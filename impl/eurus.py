import time
from typing import Any, Callable, Dict, List, Tuple

import json

import gurobipy as gp
from z3 import *

from impl.solidity_builder import BenchmarkBuilder, get_sketch_by_func_name
from impl.synthesizer import Synthesizer
from impl.utils import gen_result_paths, prepare_subfolder, resolve_project_name
from impl.verifier import verify_model

SolverType = Any
DECIMAL = 18
SCALE = 10**DECIMAL
PROFIT = 10**18 / SCALE
global Z3_OR_GB
Z3_OR_GB = True
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
            else:
                self.var_obj = Real(name)
                self.solver.add(self.var_obj >= LB, self.var_obj <= UB)
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


class StateGetter:
    def __init__(
        self,
        idx: int,
        pre_state: Dict[str, VAR],
        post_state: Dict[str, VAR],
        init_state: Dict[str, VAR],
        params: List[VAR],
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
            idx = int(__name.removeprefix("arg_"))
            r = self.params[idx].var_obj
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


LAMBDA_CONSTR = Callable[[StateGetter], Any]


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
        init_state: Dict[str, int],
        attack_goal: LAMBDA_CONSTR,
        useful_vars: List[str],
    ) -> None:
        self.sketch = sketch
        self.solver = solver
        self.states: List[Dict[str, VAR]] = []
        self.useful_vars = useful_vars
        for _ in range(len(sketch) + 1):
            self.states.append({})
        self.params: List[VAR] = []
        self.init_state = init_state
        self.attack_goal = attack_goal

    def _default_var(self, k: str):
        return VAR(k, self.solver, None)

    def handle_constraint(
        self,
        idx: int,
        func: LAMBDA_CONSTR,
    ):
        init_state = self.states[0]
        pre_state = self.states[idx]
        if idx < len(self.states) - 1:
            post_state = self.states[idx + 1]
        else:
            post_state = {}
        getter = StateGetter(
            idx, pre_state, post_state, init_state, self.params, self.solver
        )
        if Z3_OR_GB:
            self.solver.add(func(getter))
        else:
            self.solver.addConstr(func(getter))

    def execute(self):
        for k in self.init_state:
            if k not in self.useful_vars:
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
                        self.solver.add(pre_state[k].var_obj == post_state[nk].var_obj)
                    else:
                        self.solver.addConstr(pre_state[k].var_obj == post_state[nk].var_obj)
            for i in range(param_num):
                k = f"amt{i + len(self.params)}"
                var = self._default_var(k)
                self.params.append(var)
            for func in action.constraints:
                self.handle_constraint(idx, func)
        self.handle_constraint(idx+1, self.attack_goal)


def setup_solver(timeout: bool):
    # timeout is counted as seconds.
    if Z3_OR_GB:
        solver = Solver()
        solver.set(timeout=timeout * 1000)
    else:
        solver = gp.Model()
        solver.params.NumericFocus = 3
        solver.params.TimeLimit = timeout
        solver.params.NonConvex = 2
    return solver


def eurus_test(bmk_dir, args):
    timeout: int = args.timeout
    only_gt: bool = args.gt
    start: int = args.start
    end: int = args.end
    suffix_spec: str = args.suffix
    smtdiv = f"Eurus_{args.solver}"
    global Z3_OR_GB
    Z3_OR_GB = args.solver == "z3"

    builder = BenchmarkBuilder(bmk_dir)
    builder.get_initial_state()
    synthesizer = Synthesizer(builder.config)
    project_name = resolve_project_name(bmk_dir)
    _, result_path = prepare_subfolder(bmk_dir)

    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates), suffix_spec
    )
    result_paths = result_paths[start:end]

    all_actions: Dict[str, Dict[str, Tuple[List[str], List[LAMBDA_CONSTR]]]] = {
        "Discover": {
            "borrow_disc": (
                ["balanceOfdiscattacker"],
                [
                    lambda s: s.new_balanceOfdiscattacker
                    == s.old_balanceOfdiscattacker + s.arg_0,
                ],
            ),
            "swap_pair_disc_usdt": (
                [
                    "balanceOfusdtattacker",
                    "balanceOfusdtpair",
                    "balanceOfdiscattacker",
                    "balanceOfdiscpair",
                ],
                [
                    # transfer DISC from attacker to pair
                    lambda s: s.new_balanceOfdiscattacker
                    == s.old_balanceOfdiscattacker - s.arg_1,
                    lambda s: s.new_balanceOfdiscpair
                    == s.old_balanceOfdiscpair + s.arg_1,
                    # transfer USDT from pair to attacker
                    lambda s: s.new_balanceOfusdtattacker
                    == s.old_balanceOfusdtattacker + s.amtOut,
                    lambda s: s.new_balanceOfusdtpair
                    == s.old_balanceOfusdtpair - s.amtOut * 1000 / 997,
                    # invariant
                    lambda s: s.new_balanceOfusdtpair * s.new_balanceOfdiscpair
                    == s.old_balanceOfusdtpair * s.old_balanceOfdiscpair,
                ],
            ),
            "swap_ethpledge_usdt_disc": (
                [
                    "balanceOfusdtattacker",
                    "balanceOfusdtpair",
                    "balanceOfdiscattacker",
                    "balanceOfdiscpair",
                ],
                [
                    # transfer USDT from attacker to pair
                    lambda s: s.new_balanceOfusdtattacker
                    == s.old_balanceOfusdtattacker - s.arg_2,
                    lambda s: s.new_balanceOfusdtpair
                    == s.old_balanceOfusdtpair + s.arg_2,
                    # transfer DISC from pair to attacker
                    lambda s: s.new_balanceOfdiscattacker
                    == s.old_balanceOfdiscattacker + s.amtOut,
                    lambda s: s.new_balanceOfdiscpair
                    == s.old_balanceOfdiscpair - s.amtOut,
                    # invariant
                    lambda s: s.amtOut * s.old_balanceOfusdtpair
                    == s.old_balanceOfdiscpair * s.arg_2,
                ],
            ),
            "payback_disc": (
                ["balanceOfdiscattacker"],
                [
                    lambda s: s.new_balanceOfdiscattacker
                    == s.old_balanceOfdiscattacker - s.arg_3,
                    lambda s: s.arg_3 == s.arg_0 * 1000 / 997,
                ],
            ),
        }
    }
    all_attack_goals: Dict[str, LAMBDA_CONSTR] = {
        "Discover": lambda s: s.old_balanceOfusdtattacker
        >= s.init_balanceOfusdtattacker + PROFIT,
    }
    all_useful_variables: Dict[str, List[str]] = {
        "Discover": [
            "balanceOfusdtattacker",
            "balanceOfusdtpair",
            "balanceOfdiscattacker",
            "balanceOfdiscpair",
        ]
    }
    init_state = {k: int(v) for k, (_, v) in builder.init_state.items()}

    attack_goal = all_attack_goals[project_name]
    useful_vars = all_useful_variables[project_name]

    for func_name, output_path, _, _ in result_paths:
        solver = setup_solver(timeout)
        origin_sketch = get_sketch_by_func_name(builder, synthesizer, func_name)
        action_names = [a.func_sig for a in origin_sketch.pure_actions]
        param_nums = [a.param_num for a in origin_sketch.pure_actions]
        actions = []
        for name, p_num in zip(action_names, param_nums):
            write_vars, constraints = all_actions[project_name][name]
            action = FinancialAction(p_num, write_vars, constraints)
            actions.append(action)

        exec = FinancialExecution(actions, solver, init_state, attack_goal, useful_vars)

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
                        }
                    ]
                }
            }
            with open(output_path, "w") as f:
                json.dump(result, f)
            if verify_model(bmk_dir, [(func_name, origin_sketch, model)]):
                print("Result is feasible in realworld!")
            else:
                print("Result is NOT feasible in realworld!")

        else:
            print(f"Solution is NOT found.")
