import json
import re
import time
from typing import Any, Dict, List

import gurobipy as gp
from z3 import *

from impl.dsl.dsl import Sketch
from impl.sketch_enum.sol_builder import BenchmarkBuilder
from impl.toolkit.foundry import (LazyStorage, deploy_contract, init_anvil,
                                  verify_model_on_anvil)
from impl.toolkit.utils import (gen_result_paths, prepare_subfolder,
                                resolve_project_name, update_record)

from ..dsl.financial_constraints import (ACTION_CONSTR, DECIMAL, LAMBDA_CONSTR,
                                         SCALE, extract_rw_vars,
                                         gen_attack_goal, refine_constraints)

SolverType = Any
global Z3_OR_GB
Z3_OR_GB = True
TRACK_UNSAT = True
LB = 0
UB = 2**128 - 1
VTYPE = gp.GRB.CONTINUOUS


class VAR:
    names = set()

    def __init__(self, name: str, solver: SolverType, value: int = None) -> None:
        if name in self.names:
            raise ValueError(f"Duplicated name: {name}!")
        scale = SCALE
        if "block.timestamp" in name:
            scale = 1
        self.names.add(name)
        self.name = name
        self.solver = solver
        if Z3_OR_GB:
            if value is not None:
                self.var_obj = value / scale
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
                self.var_obj = value / scale
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
                r = float(model[self.var_obj].as_decimal(DECIMAL).removesuffix("?")) * SCALE
            return r
        else:
            return self.var_obj.x * SCALE

    @property
    def as_int(self):
        return int(self.as_float)

    def __str__(self) -> str:
        return hex(self.as_int)

    @classmethod
    def clear_cache(cls):
        cls.names = set()


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


class FinancialExecution:
    def __init__(
        self,
        sketch: Sketch,
        solver: SolverType,
        init_state: LazyStorage,
        attack_goal: LAMBDA_CONSTR,
    ) -> None:
        self.sketch = sketch.pure_actions
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
        # hack_params = [
        #     2100e18,
        #     100e18,
        #     424526221219952604636716,
        #     0,
        #     (424526221219952604636716 * 1003) / 1000,
        #     3942125010164795070597262,
        #     29602056415795361087488,
        #     2100e18 * 1003 / 1000,
        # ]
        # return hack_params[idx]
        return None

    def execute(self):
        # All read variables
        all_read_vars = set()
        # Init params
        for idx, action in enumerate(self.sketch):
            # Assume there are two actions written as:
            # act0(p0, p1), act1(p0).
            # p0 in act1 is named as p2.
            # p_x0 in act1 is the actual p0.
            params = {}
            param_num = action.param_num
            param_offset = len(self.all_params)
            for i in range(param_num):
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
            read_vars, _ = extract_rw_vars(action._constraints)
            all_read_vars = all_read_vars.union(read_vars)

        s = {}
        for v in all_read_vars:
            value = int(self.init_state.get(v))
            var = VAR(v + str(0), self.solver, value)
            s[v] = var
        self.states.append(s)

        # Write to storage variables
        for idx, action in enumerate(self.sketch):
            _, write_vars = extract_rw_vars(action._constraints)
            # Post state
            i = idx + 1
            s = {}
            for v in all_read_vars:
                if v in write_vars:
                    v_name = v + str(i)
                    s[v] = self._default_var(v_name)
                else:
                    s[v] = self.states[idx][v]
            self.states.append(s)

        # Generate constraints for computation between steps
        for idx, action in enumerate(self.sketch):
            for f_idx, func in enumerate(action._constraints):
                self.gen_constraint(idx, func, f"Step{idx}_{f_idx}")

        # Generate constraint for attack goal
        self.gen_constraint(idx + 1, self.attack_goal, "AttackGoal")


def setup_solver(timeout: int):
    # timeout is counted as seconds.
    if Z3_OR_GB:
        solver = Solver()
        solver.set(timeout=timeout)
        solver.set(unsat_core=True)
    else:
        solver = gp.Model()
        solver.params.NumericFocus = 3
        solver.params.TimeLimit = timeout
        solver.params.NonConvex = 2
        # solver.Params.Presolve = 0
    return solver


def eurus_solve(
    solver: SolverType,
    bmk_dir: str,
    func_name: str,
    ctrt_name2addr: Dict[str, str],
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
        print(f"Solution is found in candidate: {func_name}, loop: {refine_loop}.")
        param_strs = []
        for p in exec.all_params:
            v = str(p)
            print(f"uint256 {p.name} = {v}")
            param_strs.append(v)
        feasible = verify_model_on_anvil(ctrt_name2addr, func_name, param_strs)
        # There is a bug in anvil, this solution is tested in foundry test.
        # if "BXH" in bmk_dir and func_name == "check_cand003":
        #     feasible = True
        if feasible:
            print(f"Result for {func_name} is feasible in realworld!")
        else:
            print(f"Result for {func_name} is NOT feasible in realworld!")
        result = {
            "test_results": {
                bmk_dir: [
                    {
                        "name": func_name,
                        "num_models": 1,
                        "models": [{f"p_{p.name}_uint256": str(p) for p in exec.all_params}],
                        "time": [timecost, 0, timecost],
                        "feasible": feasible,
                        "refine_loop": refine_loop,
                    }
                ]
            }
        }
        with open(output_path, "w") as f:
            json.dump(result, f, indent=4)
        return feasible
    else:
        print(f"Solution is NOT found in candidate: {func_name}, loop: {refine_loop}.")
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
        return "UNSAT"
