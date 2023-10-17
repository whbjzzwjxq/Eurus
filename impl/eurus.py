import time
from typing import Any, Dict, List, Tuple
import json
import gurobipy as gp
from z3 import *

from impl.dsl import Sketch
from .foundry_toolset import LazyStorage, deploy_contract, init_anvil, set_nomining
import re
from .benchmark_builder import BenchmarkBuilder, get_sketch_by_func_name
from .synthesizer import Synthesizer
from .utils import (
    gen_result_paths,
    prepare_subfolder,
    resolve_project_name,
)
from .verifier import verify_model
from .financial_constraints import (
    ACTION_SUMMARY,
    LAMBDA_CONSTR,
    gen_attack_goal,
    hack_constraints,
    refine_constraints,
    SCALE,
    DECIMAL,
)

SolverType = Any
global Z3_OR_GB
Z3_OR_GB = True
TRACK_UNSAT = True
LB = 0
UB = 2**64 - 1
VTYPE = gp.GRB.CONTINUOUS


class VAR:
    names = set()

    def __init__(self, name: str, solver: SolverType, value: int = None) -> None:
        if name in self.names:
            raise ValueError(f"Duplicated name: {name}!")
        self.names.add(name)
        self.name = name
        self.solver = solver
        if Z3_OR_GB:
            if value is not None:
                self.var_obj = value / SCALE
            elif TRACK_UNSAT:
                self.var_obj = Real(name)
                self.solver.assert_and_track(self.var_obj >= LB, f"LB{len(self.names)}")
                self.solver.assert_and_track(self.var_obj <= UB, f"UB{len(self.names)}")
            else:
                self.var_obj = Real(name)
                self.solver.add(self.var_obj >= LB)
                self.solver.add(self.var_obj <= UB)
        else:
            if value is not None:
                self.var_obj = value / SCALE
            else:
                self.var_obj = self.solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name=name)

    @property
    def as_float(self) -> float:
        if isinstance(self.var_obj, float):
            return self.var_obj * SCALE
        if Z3_OR_GB:
            model = self.solver.model()
            if model[self.var_obj] is None:
                r = 0
            else:
                r = (
                    float(model[self.var_obj].as_decimal(DECIMAL).removesuffix("?"))
                    * SCALE
                )
            return r
        else:
            return self.var_obj.x * SCALE

    @property
    def as_int(self):
        return int(self.as_float)

    def __str__(self) -> str:
        return hex(self.as_int)


class VarCreator:
    def __init__(self) -> None:
        self.var_names = set()

    def get(self, __name: str) -> int:
        if __name.startswith("old_"):
            key = __name.removeprefix("old_")
        elif __name.startswith("new_"):
            key = __name.removeprefix("new_")
        else:
            key = ""
        if key != "":
            self.var_names.add(key)
        return 1


class VarGetter:
    def __init__(
        self,
        idx: int,
        init_state: Dict[str, VAR],
        pre_state: Dict[str, VAR],
        post_state: Dict[str, VAR],
        params: Dict[str, VAR],
        solver: SolverType,
    ) -> None:
        self.idx = idx
        self.init_state = init_state
        self.pre_state = pre_state
        self.post_state = post_state
        self.params = params
        self.solver = solver

    def get(self, __name: str) -> Any:
        idx = self.idx
        if __name.startswith("old_"):
            key = __name.removeprefix("old_")
            r = self.pre_state[key].var_obj
            return r
        elif __name.startswith("new_"):
            key = __name.removeprefix("new_")
            r = self.post_state[key].var_obj
            return r
        elif __name.startswith("arg_"):
            key = __name.removeprefix("arg_")
            r = self.params[key].var_obj
            return r
        elif __name.startswith("init_"):
            key = __name.removeprefix("init_")
            r = self.init_state[key].var_obj
            return r
        else:
            # Internal variable
            k = __name + str(idx)
            if k not in self.pre_state:
                v = VAR(k, self.solver, None)
                self.pre_state[k] = v
            r = self.pre_state[k].var_obj
            return r


class FinancialAction:
    def __init__(
        self,
        param_num: int,
        write_vars: List[str],
        constraints: List[LAMBDA_CONSTR],
    ) -> None:
        self.param_num = param_num
        self.write_vars = write_vars
        self.constraints = constraints


class FinancialExecution:
    def __init__(
        self,
        sketch: List[FinancialAction],
        solver: SolverType,
        init_state: LazyStorage,
        attack_goal: LAMBDA_CONSTR,
    ) -> None:
        self.sketch = sketch
        self.solver = solver
        self.states: List[Dict[str, VAR]] = []
        self.params: List[Dict[str, VAR]] = []
        self.all_params: List[VAR] = []
        self.init_state = init_state
        self.attack_goal = attack_goal

    def _default_var(self, k: str):
        return VAR(k, self.solver, None)

    def add_constraint(self, c: Any, name: str = None):
        if Z3_OR_GB:
            if TRACK_UNSAT:
                if name is None:
                    raise ValueError("Name is not given!")
                if isinstance(c, bool):
                    return
                self.solver.assert_and_track(c, name)
            else:
                self.solver.add(c)
        else:
            self.solver.addConstr(c)

    def gen_constraint(
        self,
        idx: int,
        func: LAMBDA_CONSTR,
        constraint_name: str,
    ):
        init_state = self.states[0]
        pre_state = self.states[idx]
        if idx < len(self.states) - 1:
            post_state = self.states[idx + 1]
        else:
            post_state = {}
        if idx < len(self.params):
            params = self.params[idx]
        else:
            params = {}
        getter = VarGetter(
            idx,
            init_state,
            pre_state,
            post_state,
            params,
            self.solver,
        )
        c = func(getter)
        self.add_constraint(c, constraint_name)

    def get_hack_param(self, idx: int):
        return None

    def execute(self):
        # Init params
        for idx, action in enumerate(self.sketch):
            # Assume there are two actions written as:
            # act0(p0, p1), act1(p0).
            # p0 in act1 is named as p2.
            # p_x0 in act1 is the actual p0.
            params = {}
            param_num = action.param_num
            for i in range(param_num):
                param_offset = len(self.all_params)
                k = f"amt{i + param_offset}"
                hack_param = self.get_hack_param(i + param_offset)
                if hack_param is None:
                    var = self._default_var(k)
                else:
                    var = VAR(k, self.solver, hack_param)
                params[f"{i}"] = var
                self.all_params.append(var)
            for idx, p in enumerate(self.all_params):
                params[f"x{idx}"] = p
            self.params.append(params)

        # Init storage variables
        creator = VarCreator()
        for idx, action in enumerate(self.sketch):
            for func in action.constraints:
                try:
                    _ = func(creator)
                except Exception:
                    pass
        var_names = sorted(list(creator.var_names))

        s = {}
        for v in var_names:
            value = int(self.init_state.get(v))
            var = VAR(v + str(0), self.solver, value)
            s[v] = var
        self.states.append(s)

        # Write to storage variables
        for idx, action in enumerate(self.sketch):
            write_vars = action.write_vars
            # Post state
            i = idx + 1
            s = {}
            for v in var_names:
                if v in write_vars:
                    v_name = v + str(i)
                    s[v] = self._default_var(v_name)
                else:
                    s[v] = self.states[idx][v]
            self.states.append(s)

        # Generate constraints for computation between steps
        for idx, action in enumerate(self.sketch):
            for f_idx, func in enumerate(action.constraints):
                self.gen_constraint(idx, func, f"Step{idx}_{f_idx}")

        # Generate constraint for attack goal
        self.gen_constraint(idx + 1, self.attack_goal, "AttackGoal")


def setup_solver(timeout: bool):
    # timeout is counted as seconds.
    if Z3_OR_GB:
        solver = Solver()
        solver.set(timeout=timeout * 1000)
        solver.set(unsat_core=True)
    else:
        solver = gp.Model()
        solver.params.NumericFocus = 3
        solver.params.TimeLimit = timeout
        solver.params.NonConvex = 2
        # solver.Params.Presolve = 0
    return solver


def autogen_financial_formula(
    bmk_dir: str,
) -> Tuple[LAMBDA_CONSTR, Dict[str, ACTION_SUMMARY]]:
    builder = BenchmarkBuilder(bmk_dir)
    config = builder.config
    synthesizer = Synthesizer(config)
    project_name = config.project_name

    token, amount = config.attack_goal

    attack_goal = gen_attack_goal(token, amount, SCALE)

    action2constraints: Dict[str, ACTION_SUMMARY] = {}
    for sketch in synthesizer.candidates:
        for action in sketch.pure_actions:
            if action.func_sig in action2constraints:
                continue
            action2constraints[action.func_sig] = action.gen_constraints(config)

    action2constraints.update(hack_constraints.get(project_name, {}))

    return attack_goal, action2constraints


def eurus_solve(
    solver: SolverType,
    bmk_dir: str,
    func_name: str,
    origin_sketch: Sketch,
    output_path: str,
    exec: FinancialExecution,
    refine_loop: int,
) -> bool:
    start_time = time.perf_counter()
    if Z3_OR_GB:
        res = solver.check()
    else:
        solver.optimize()
        res = sat if solver.status == gp.GRB.OPTIMAL else unsat
    timecost = time.perf_counter() - start_time
    print(f"Timecost is: {timecost}.")
    if res == sat:
        print(f"Solution is found.")
        param_ints = []
        for p in exec.all_params:
            v = str(p)
            print(f"{p.name}: {v}")
            param_ints.append(v)
        model = [param_ints]
        feasible = verify_model(bmk_dir, [(func_name, origin_sketch, model)])
        if feasible:
            print("Result is feasible in realworld!")
        else:
            print("Result is NOT feasible in realworld!")
        result = {
            "test_results": {
                bmk_dir: [
                    {
                        "name": func_name,
                        "num_models": 1,
                        "models": [
                            {f"p_{p.name}_uint256": str(p) for p in exec.all_params}
                        ],
                        "time": [timecost, 0, timecost],
                        "feasible": feasible,
                        "refine_loop": refine_loop,
                    }
                ]
            }
        }
        with open(output_path, "w") as f:
            json.dump(result, f, indent=4)

    else:
        print(f"Solution is NOT found.")
        if Z3_OR_GB and TRACK_UNSAT:
            unsat_core = solver.unsat_core()
            print("Unsat core:")
            names = [str(assertion) for assertion in unsat_core]
            imple_regex = re.compile(r"Implies\((.*),.*")
            for c in solver.assertions():
                m = imple_regex.match(str(c))
                n = m.groups()[0]
                if n in names:
                    print(c)
    return feasible


def eurus_test(bmk_dir: str, args):
    timeout: int = args.timeout
    only_gt: bool = args.gt
    start: int = args.start
    end: int = args.end
    suffix_spec: str = args.suffix
    smtdiv = f"Eurus_{args.solver}"
    global Z3_OR_GB
    Z3_OR_GB = args.solver == "z3"
    VAR.names = set()

    builder = BenchmarkBuilder(bmk_dir)
    builder.get_initial_state()
    synthesizer = Synthesizer(builder.config)
    project_name = resolve_project_name(bmk_dir)
    _, result_path = prepare_subfolder(bmk_dir)

    timestamp = builder.init_state["blockTimestamp"][1]

    anvil_proc = init_anvil(timestamp=int(timestamp) - 1)

    try:
        snapshot_id, ctrt_name2addr = deploy_contract(bmk_dir)

        init_state = LazyStorage(bmk_dir, ctrt_name2addr, timestamp)

        result_paths = gen_result_paths(
            result_path, only_gt, smtdiv, len(synthesizer.candidates), suffix_spec
        )
        result_paths = result_paths[start:end]

        attack_goal, action_constraints = autogen_financial_formula(bmk_dir)

        for func_name, output_path, _, _ in result_paths:
            solver = setup_solver(timeout)
            origin_sketch = get_sketch_by_func_name(builder, synthesizer, func_name)
            action_names = [a.func_sig for a in origin_sketch.pure_actions]
            param_nums = [a.param_num for a in origin_sketch.pure_actions]
            actions = []
            for name, p_num in zip(action_names, param_nums):
                write_vars, constraints = action_constraints[name]
                action = FinancialAction(p_num, write_vars, constraints)
                actions.append(action)

            exec = FinancialExecution(actions, solver, init_state, attack_goal)

            exec.execute()

            feasible = False
            idx = 0
            while not feasible:
                if Z3_OR_GB:
                    print(solver.sexpr())
                feasible = eurus_solve(
                    solver, bmk_dir, func_name, origin_sketch, output_path, exec, idx
                )
                refinements = refine_constraints.get(project_name, [])
                if len(refinements) <= idx:
                    break
                refinement = refinements[idx]
                for s_sig, v in refinement.items():
                    s_idx = origin_sketch.get_action_idx_by_sig(s_sig)
                    if s_idx == -1:
                        raise ValueError(
                            f"Unknown function signature: {s_sig} in project: {project_name}"
                        )
                    for f_idx, func in enumerate(v):
                        exec.gen_constraint(
                            s_idx, func, f"Ref{idx}_Step{s_idx}_{f_idx}"
                        )
                # if Z3_OR_GB:
                #     solver.reset()
                # else:
                #     # Gurobi doesn't require it.
                #     pass
                idx += 1
        anvil_proc.kill()
    except Exception as err:
        anvil_proc.kill()
        raise err
