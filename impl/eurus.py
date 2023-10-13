import time
from typing import Any, Callable, Dict, List, Tuple
import json
import gurobipy as gp
from z3 import *
from .foundry_toolset import LazyStorage, deploy_contract, init_anvil

from .benchmark_builder import BenchmarkBuilder, get_sketch_by_func_name, AttackCtrtName
from .synthesizer import Synthesizer
from .utils import (
    gen_result_paths,
    get_bmk_dirs,
    prepare_subfolder,
    resolve_project_name,
)
from .verifier import verify_model
from .financial_constraints import hacking_constraints

SolverType = Any
DECIMAL = 18
SCALE = 10**DECIMAL
PROFIT = 10**18 / SCALE
global Z3_OR_GB
Z3_OR_GB = True
TRACK_UNSAT = False
LB = 0
UB = 2**64 - 1
VTYPE = gp.GRB.CONTINUOUS


class VAR:
    names = set()

    def __init__(self, name: str, solver: SolverType, value: int = None) -> None:
        if name in self.names:
            raise ValueError("Duplicated names!")
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
        if Z3_OR_GB:
            model = self.solver.model()
            return (
                float(model[self.var_obj].as_decimal(DECIMAL).removesuffix("?")) * SCALE
            )
        else:
            return self.var_obj.x * SCALE

    @property
    def as_int(self):
        return int(self.as_float)

    def __str__(self) -> str:
        return hex(self.as_int)


class Storage:
    def __init__(self, prev_storage: "VarGetter") -> None:
        pass


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
        self.pre_state = pre_state
        self.post_state = post_state
        self.init_state = init_state
        self.params = params
        self.solver = solver

    def __getattr__(self, __name: str) -> Any:
        idx = self.idx
        if __name.startswith("old_"):
            key = __name.removeprefix("old_") + str(idx)
            r = self.pre_state[key].var_obj
            return r
        elif __name.startswith("new_"):
            key = __name.removeprefix("new_") + str(idx + 1)
            r = self.post_state[key].var_obj
            return r
        elif __name.startswith("arg_"):
            r = self.params[key].var_obj
            return r
        elif __name.startswith("init_"):
            key = __name.removeprefix("init_") + str(0)
            r = self.init_state[key].var_obj
            return r
        else:
            k = __name + str(idx)
            # internal variable
            if k not in self.pre_state:
                v = VAR(k, self.solver, None)
                self.pre_state[k] = v
            r = self.pre_state[k].var_obj
            return r


LAMBDA_CONSTR = Callable[[VarGetter], Any]
ACTION_SUMMARY = Tuple[List[str], List[LAMBDA_CONSTR]]


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
        for _ in range(len(sketch) + 1):
            self.states.append({})
        self.params: List[VAR] = []
        self.init_state = init_state
        self.attack_goal = attack_goal

    def _default_var(self, k: str):
        return VAR(k, self.solver, None)
    
    def add_constraint(self, c: Any, name: str = None):
        if Z3_OR_GB:
            if TRACK_UNSAT:
                self.solver.assert_and_track(c, name)
            else:
                self.solver.add(c)
        else:
            self.solver.addConstr(c)

    def handle_constraint(
        self,
        idx: int,
        func: LAMBDA_CONSTR,
        param_offset: int,
    ):
        init_state = self.states[0]
        pre_state = self.states[idx]
        if idx < len(self.states) - 1:
            post_state = self.states[idx + 1]
        else:
            post_state = {}
        getter = VarGetter(
            idx,
            pre_state,
            post_state,
            init_state,
            self.params,
            param_offset,
            self.solver,
        )
        c = func(getter)
        name = f"Step: {idx}, {str(c)}"
        self.add_constraint(c, name)

    def execute(self):
        for k in self.init_state:
            if k not in self.rw_vars:
                continue
            v = self.init_state.get(k, 0)
            nk = k + str(0)
            var = VAR(nk, self.solver, int(v))
            self.states[0][nk] = var

        for idx, action in enumerate(self.sketch):
            write_vars = action.write_vars
            param_num = action.param_num
            pre_state = self.states[idx]
            if idx < len(self.states) - 1:
                post_state = self.states[idx + 1]
            else:
                post_state = {}
            for k in pre_state:
                pure_k = k.removesuffix(str(idx))
                nk = pure_k + str(idx + 1)
                post_state[nk] = self._default_var(nk)
                if pure_k not in write_vars:
                    if Z3_OR_GB:
                        if TRACK_UNSAT:
                            self.solver.assert_and_track(
                                pre_state[k].var_obj == post_state[nk].var_obj,
                                f"Step: {idx}, State: {k}",
                            )
                        else:
                            self.solver.add(
                                pre_state[k].var_obj == post_state[nk].var_obj,
                            )
                    else:
                        self.solver.addConstr(
                            pre_state[k].var_obj == post_state[nk].var_obj
                        )
            param_offset = len(self.params)
            for i in range(param_num):
                k = f"amt{i + len(self.params)}"
                var = self._default_var(k)
                self.params.append(var)
            for func in action.constraints:
                self.handle_constraint(idx, func, param_offset)
        self.handle_constraint(idx + 1, self.attack_goal, len(self.params))


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
    return solver


def autogen_financial_formula(
    bmk_dir: str,
) -> Tuple[LAMBDA_CONSTR, Dict[str, ACTION_SUMMARY]]:
    builder = BenchmarkBuilder(bmk_dir)
    config = builder.config
    synthesizer = Synthesizer(config)
    project_name = config.project_name

    attack_goal_varstr = config.attack_goal.split("+ ")[1]
    # fmt: off
    attack_goal = lambda s: s.__getattr__(f"old_{attack_goal_varstr}") >= s.__getattr__(f"init_{attack_goal_varstr}") + PROFIT
    # fmt: on
    # rw_vars = []
    # for token in builder.erc20_tokens:
    #     for user in builder.token_users:
    #         if user != AttackCtrtName:
    #             rw_vars.append(f"balanceOf{token}{user}")
    #         else:
    #             rw_vars.append(f"balanceOf{token}attacker")

    action2constraints: Dict[str, ACTION_SUMMARY] = {}
    for sketch in synthesizer.candidates:
        for action in sketch.pure_actions:
            if action.func_sig in action2constraints:
                continue
            action2constraints[action.func_sig] = action.gen_constraints(config)

    action2constraints.update(hacking_constraints.get(project_name, {}))

    return attack_goal, action2constraints


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

    anvil_proc = init_anvil(timestamp=builder.init_state["blockTimestamp"][1])

    snapshot_id, ctrt_name2addr = deploy_contract(bmk_dir)

    init_state = LazyStorage(bmk_dir, ctrt_name2addr)

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

        if Z3_OR_GB:
            print(solver.sexpr())

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
            for p in exec.params:
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
                                {f"p_{p.name}_uint256": str(p) for p in exec.params}
                            ],
                            "time": [timecost, 0, timecost],
                            "feasible": feasible,
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
                for assertion in unsat_core:
                    print(assertion)

    anvil_proc.kill()
