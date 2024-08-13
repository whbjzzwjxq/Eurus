from typing import List, Set, Optional, Union, Dict, Iterable, Callable, Any

import time

from .config import Config, init_config
from .dsl import *
from .financial_constraints import *
from .token_flow_graph import TFGManager, VOID
from .utils import *
from .utils_slither import *


TRACE = List[Tuple[SliFunction, SliCallExpression]]
TRANS_SUMMARY = List[Tuple[TRACE, Tokenflow]]


def init_default_token_transfer(ctrt: SliContract, func: SliFunction) -> Tokenflow:
    return Tokenflow(ctrt, Tokenflow.SENDER, *func.parameters)


def init_default_token_transferFrom(ctrt: SliContract, func: SliFunction) -> Tokenflow:
    return Tokenflow(ctrt, *func.parameters)


def init_default_token_burn(ctrt: SliContract, func: SliFunction) -> Tokenflow:
    return Tokenflow(ctrt, func.parameters[0], Tokenflow.DEAD, func.parameters[1])


def init_default_token_mint(ctrt: SliContract, func: SliFunction) -> Tokenflow:
    return Tokenflow(ctrt, Tokenflow.ZERO, func.parameters[0], func.parameters[1])


# All possible variables related to this expr
def destruct_expr(expr: SliExpression) -> Set[SliVariable]:
    # token0.transfer(xxx, xxx, xxx);
    if isinstance(expr, SliVariable):
        return {expr}

    if isinstance(expr, SliIdentifier):
        # LocalVariable | StorageVariable
        return {expr.value}

    # IERC20(token0).transfer(xxx, xxx, xxx);
    if isinstance(expr, SliTypeConversion):
        return destruct_expr(expr.expression)

    # UniswapV2Library.pairFor(factory, path[0], path[1])
    if isinstance(expr, SliCallExpression):
        new_set = set()
        for a in expr.arguments:
            new_set = new_set.union(destruct_expr(a))
        return new_set

    # path[0]
    if isinstance(expr, SliIndexAccess):
        return destruct_expr(expr.expression_left).union(destruct_expr(expr.expression_right))

    # '0'
    if isinstance(expr, SliLiteral):
        return set()

    raise CornerCase("TODO")


DSL_FUNC_GEN = Callable[[Tuple[str, ...]], str]


class ERC20Summary:
    def __init__(
        self,
        ctrt: SliContract,
        transfer: List[Tokenflow],
        transferFrom: List[Tokenflow],
    ) -> None:
        self.ctrt = ctrt
        self.transfer = transfer
        self.transferFrom = transferFrom


class Synthesizer:
    def __init__(self, bmk_dir: str, record: dict = None) -> None:
        self.config: Config = init_config(bmk_dir)
        self.sli = gen_slither(bmk_dir)
        self.candidates: List[Sketch] = []
        self.candidates_signs: Set[str] = set()
        actions = [init_action_from_list(a, True) for a in self.config.groundtruth]
        self.gt_sketch = Sketch(actions).symbolic_copy()

        self.role2ctrt_names = self._init_role2names()
        self.role2ctrt = self._init_role2ctrts()
        self.init_storage = self._init_storage_var_mapping()

        self.timecost: float = 0
        self.func_summarys: Dict[str, AFLAction] = {}
        self.candidates: List[Sketch] = []
        suffix = "TestBase"
        test_ctrt_name = f"{self.config.project_name}{suffix}"
        self.test_ctrt = self.sli.get_contract_from_name(test_ctrt_name)[0]
        if record is None:
            timer = time.perf_counter()
            self.candidates = self._infer_candidates()
            self.timecost = time.perf_counter() - timer
        else:
            self.candidates = self._load_candidates(record)
            self.timecost = record["sketchgen_timecost"]

    def _init_storage_var_mapping(self):
        # Hardcode
        hack_storage_var_mapping = {"MUMUG": {"mubank._MuCoin": "mu"}}
        storage = hack_storage_var_mapping.get(self.config.project_name, {})

        for name, role in self.config.roles.items():
            if role.is_uniswap:
                storage = {
                    f"{name}._token0": role.token_pair[0],
                    f"{name}._token1": role.token_pair[1],
                    f"{name}.token0": role.token_pair[0],
                    f"{name}.token1": role.token_pair[1],
                }
                storage.update(storage)
        return storage

    def _init_role2names(self) -> Dict[str, str]:
        role2names = {}
        for role_name, ctrt_name in self.config.ctrt_name2cls:
            role2names[role_name] = ctrt_name
        return role2names

    def _init_role2ctrts(self) -> Dict[str, SliContract]:
        role2ctrts = {}
        for role_name, ctrt_name in self.role2ctrt_names.items():
            for ctrt in self.sli.contracts:
                if ctrt.name == ctrt_name:
                    role2ctrts[role_name] = ctrt
        if len(self.role2ctrt_names) != len(role2ctrts):
            raise ValueError("Unmatched contract_names and contracts!")
        return role2ctrts

    @property
    def ctrts(self) -> Iterable[SliContract]:
        return self.role2ctrt.values()

    def _infer_candidates(self):
        # # Infer the behaviors of functions in ERC20.
        # self.func_trans_summary: Dict[str, TRANS_SUMMARY] = {}
        # self.erc20_summarys: Dict[str, ERC20Summary] = {}
        # for role_name, ctrt in self.role2ctrt.items():
        #     if not self.is_erc20(ctrt):
        #         continue
        #     ava_funcs = self.get_public_funcs(ctrt.functions_entry_points)
        #     transfer_summary, transfer_from_summary = [], []
        #     for func in ava_funcs:
        #         token_flows = self.infer_transfer_formulas(func)
        #         if func.name == "transfer":
        #             transfer_summary = token_flows
        #         if func.name == "transferFrom":
        #             transfer_from_summary = token_flows
        #     summary = ERC20Summary(ctrt, transfer_summary, transfer_from_summary)
        #     self.erc20_summarys[role_name] = summary

        # Infer public actions in the attack contract.
        for func in self.test_ctrt.functions:
            eurus_func = any(m.full_name == "eurus()" for m in func.modifiers)
            if not eurus_func:
                continue
            func_summary = self.infer_func_summary(func)
            self.func_summarys[func_summary.func_sig] = func_summary

        # Generate sketch
        tokens = [VOID] + self.config.tokens
        accounts = ["owner", "dead"] + list(self.role2ctrt.keys())
        func_summarys = list(self.func_summarys.values())
        attack_goal, _ = self.config.attack_goal
        tfg = TFGManager(tokens, accounts, func_summarys, attack_goal)

        candidates = tfg.gen_candidates()
        # Hardcode
        if self.config.project_name == "NMB":
            candidates = candidates[:7] + [self.gt_sketch.symbolic_copy()] + candidates[7:]
        # Remove all candidates after the groundtruth.
        # To allow the false-prositive ablation study, disable it.
        # end_idx = -1
        # for idx, c in enumerate(candidates):
        #     if len(c) != len(self.gt_sketch):
        #         continue
        #     if c == self.gt_sketch:
        #         end_idx = idx
        #     if len(c.args) > 8:
        #         end_idx = idx
        # if end_idx == -1:
        #     raise ValueError("Ground truth is not covered by the candidates!")
        # return candidates[: end_idx + 1]

        # Solidity doesn't support arguments more than 12, otherwise stack too deep will raise.
        res = []
        for idx, c in enumerate(candidates):
            if len(c.args) > 12:
               continue
            res.append(c)
        return res

    def _load_candidates(self, record: dict):
        for func in self.test_ctrt.functions:
            eurus_func = any(m.full_name == "eurus()" for m in func.modifiers)
            if not eurus_func:
                continue
            func_summary = self.infer_func_summary(func)
            self.func_summarys[func_summary.func_sig] = func_summary

        candidates = []
        for c in record["candidates"]:
            actions = [self.func_summarys[func_sig] for func_sig in c]
            sketch = Sketch(actions).symbolic_copy()
            candidates.append(sketch)
        return candidates

    def infer_func_summary(self, func: SliFunction) -> AFLAction:
        action = self.map_func_to_action(func)
        token_flows = self.infer_token_flows(action)
        constraints = self.infer_constraints(action)
        action.update(token_flows, constraints)
        return action

    # Hardcode
    def infer_token_flows(self, action: AFLAction) -> List[Tokenflow]:
        cur_hack_token_flows = hack_token_flows.get(self.config.project_name, {})
        if action.func_sig in cur_hack_token_flows:
            return cur_hack_token_flows[action.func_sig]
        if action.action_name == "nop":
            return []
        elif action.action_name == "burn":
            return [Tokenflow(action.token0, action.account, DEAD, "")]
        elif action.action_name == "mint":
            return [Tokenflow(action.token0, DEAD, action.account, "")]
        elif action.action_name == "swap":
            return [
                Tokenflow(action.token0, action.swap_pair, action.account, ""),
                Tokenflow(action.token1, action.account, action.swap_pair, ""),
            ]
        elif action.action_name == "borrow":
            return [Tokenflow(action.token0, action.lender, action.account, "")]
        elif action.action_name == "payback":
            return [Tokenflow(action.token0, action.account, action.lender, "")]
        elif action.action_name == "addliquidity":
            if action.token0 != action.token1:
                return [
                    Tokenflow(action.token0, action.defi, action.swap_pair, ""),
                    Tokenflow(action.token1, action.defi, action.swap_pair, ""),
                ]
            else:
                return [Tokenflow(action.token0, action.defi, action.swap_pair, "")]
        elif action.action_name == "deposit":
            return [
                Tokenflow(action.token0, action.defi, action.account, ""),
                Tokenflow(action.token1, action.account, action.defi, ""),
            ]
        elif action.action_name == "withdraw":
            return [
                Tokenflow(action.token0, action.defi, action.account, ""),
                Tokenflow(action.token1, action.account, action.defi, ""),
            ]
        elif action.action_name == "transaction":
            return []

    # Hardcode
    def infer_constraints(self, action: AFLAction) -> ACTION_CONSTR:
        cur_hack_constraints = hack_constraints.get(self.config.project_name, {})
        if action.func_sig in cur_hack_constraints:
            return cur_hack_constraints[action.func_sig]
        if action.action_name == "nop":
            return []
        elif action.action_name == "burn":
            return gen_summary_burn(action.account, action.token0, "arg_0")
        elif action.action_name == "mint":
            return gen_summary_mint(action.account, action.token0, "arg_0")
        elif action.action_name == "swap":
            return gen_summary_uniswap(
                action.swap_pair, "attacker", "attacker", action.token0, action.token1, "arg_0", "arg_1"
            )
        elif action.action_name == "borrow":
            return gen_summary_transfer(action.lender, "attacker", action.token0, "arg_0")
        elif action.action_name == "payback":
            return gen_summary_payback("attacker", action.lender, action.token0, "alias_" + action.func_sig, "arg_0")
        elif action.action_name == "addliquidity":
            return []
        elif action.action_name == "deposit":
            return []
        elif action.action_name == "withdraw":
            return []
        elif action.action_name == "transaction":
            return []

    # Utils
    def map_func_to_action(self, func: SliFunction) -> AFLAction:
        args_in_name = func.name.split("_")
        args = [str(a) for a in func.parameters]
        return init_action_from_list([*args_in_name, *args], False)

    def count_type_amt_in_func(self, func: SliFunction, type_str: str) -> int:
        _count = 0
        for param in func.parameters:
            if isinstance(param.type, SliElementaryType):
                if param.type.name == type_str:
                    _count += 1
                continue
            if isinstance(param.type, SliArrayType):
                length = 2
                if not param.type.is_dynamic_array:
                    length = param.type.length
                sub_type = param.type.type
                if isinstance(sub_type, SliElementaryType):
                    if sub_type.name == type_str:
                        _count += length
                    continue
            raise CornerCase("TODO")
        return _count

    def init_transfer(self, ctrt: SliContract, called_expr: SliCallExpression) -> Tokenflow:
        called: SliMemberAccess = called_expr.called
        return Tokenflow(
            called.expression,
            self.get_role_name_by_ctrt(ctrt),
            *called_expr.arguments,
            transfer_from=False,
        )

    def init_transferFrom(self, called_expr: SliCallExpression) -> Tokenflow:
        called: SliMemberAccess = called_expr.called
        return Tokenflow(called.expression, *called_expr.arguments, transfer_from=True)

    def init_burn(self, called_expr: SliCallExpression) -> Tokenflow:
        called: SliMemberAccess = called_expr.called
        return Tokenflow(
            called.expression,
            called_expr.arguments[0],
            Tokenflow.DEAD,
            called_expr.arguments[1],
            transfer_from=False,
        )

    def get_role_name_by_ctrt(self, ctrt: Union[SliContract, str]) -> str:
        if isinstance(ctrt, SliContract):
            name = ctrt.name
        else:
            name = ctrt
        for role, _ctrt in self.role2ctrt.items():
            if name == _ctrt.name:
                return role
        raise CornerCase("TODO")

    def get_fixed_expr_in_trace(self, trace: TRACE, expr: SliExpression) -> Any:
        idx = len(trace) - 1
        t_expr = expr
        while idx >= 0:
            checking_vars = destruct_expr(t_expr)
            n_checking_vars: Set[SliVariable] = set()
            f, call_expr = trace[idx]
            for jdx, p in enumerate(f.parameters):
                for v in checking_vars:
                    if is_dependent(v, p, f):
                        if call_expr is not None:
                            n_vars = destruct_expr(call_expr.arguments[jdx])
                            n_checking_vars = n_checking_vars.union(n_vars)
                        else:
                            n_checking_vars.add(f.parameters[jdx])
            # There is no data-dependence from parameters to the variable points to token.
            # The variable points to var is a storage variable.
            if len(n_checking_vars) == 0:
                if len(checking_vars) > 1:
                    raise CornerCase("TODO")
                # Get the variable in current scope.
                var = checking_vars.pop()

                # Get the top of function stack.
                f, _ = trace[idx]

                # Get the stored value of var.
                stored_val = self.get_stored_val(f, var)

                # Generate binding
                binding = {var: stored_val}

                # Get the actual value of the expression
                return self.partial_eval_in_trace(trace[idx - 1 :], binding, t_expr)
            elif len(n_checking_vars) == 1:
                t_expr = n_checking_vars.pop()
                checking_vars = n_checking_vars.copy()
                idx -= 1
            else:
                return None
        return None

    def get_stored_val(self, func: SliFunction, var: SliExpression) -> Any:
        if str(var) == "msg.sender":
            return ATTACKER
        if str(var) == "this":
            return self.get_role_name_by_ctrt(func.contract)
        key = f"{self.get_role_name_by_ctrt(func.contract)}.{str(var)}"
        return self.init_storage[key]

    def partial_eval(self, func: SliFunction, binding: Dict[SliVariable, Any], expr: SliExpression):
        if isinstance(expr, SliTypeConversion):
            return self.partial_eval(func, binding, expr.expression)
        if isinstance(expr, SliIdentifier):
            return self.partial_eval(func, binding, expr.value)
        if isinstance(expr, SliCallExpression):
            if isinstance(expr.called, SliNewElementaryType):
                return None
            if isinstance(expr.called, SliMemberAccess):
                if expr.called.member_name == "pairFor" and expr.called.expression.value.name == "UniswapV2Library":
                    token0 = self.partial_eval(func, binding, expr.arguments[1])
                    token1 = self.partial_eval(func, binding, expr.arguments[2])
                    if token0 == token1:
                        return None
                    # Hardcode
                    for role_name, role in self.config.roles.items():
                        if role.token_pair == [token0, token1] or role.token_pair == [token1, token0]:
                            return role_name
                return None
            return None
        if isinstance(expr, SliIndexAccess):
            index = expr.expression_right
            expr = expr.expression_left
            if isinstance(expr, SliIdentifier):
                var = expr.value
            if var in binding:
                return binding[var][int(str(index))]
        if expr in binding:
            return binding[expr]
        return None

    def partial_eval_in_trace(self, trace: TRACE, binding: Dict[SliVariable, Any], expr: SliExpression):
        func, _ = trace[0]
        for f, exprs in trace[1:]:
            new_binding = {}
            for idx, p in enumerate(f.parameters):
                sub_expr = exprs.arguments[idx]
                v = self.partial_eval(func, binding, sub_expr)
                new_binding[p] = v
            binding = new_binding
            func = f
        res = self.partial_eval(func, binding, expr)
        return res

    def is_erc20(self, ctrt: SliContract) -> bool:
        for ctrt in ctrt.inheritance:
            if ctrt.name in ("ERC20", "IERC20"):
                return True
        return False

    def get_external_call_funcs_from_expr(self, e_call_expr: SliExpression) -> List[SliFunction]:
        # Call new Uint();
        if isinstance(e_call_expr.called, SliNewElementaryType):
            return []
        # Call new Array();
        if isinstance(e_call_expr.called, SliNewArray):
            return []
        # Call new Contract();
        if isinstance(e_call_expr.called, SliNewContract):
            return []
        if isinstance(e_call_expr.called, SliMemberAccess):
            return self.get_external_call_funcs(e_call_expr.called)
        raise CornerCase("TODO")

    def get_external_call_funcs(self, called: SliMemberAccess) -> List[SliFunction]:
        key = called.member_name
        c_expr = called.expression
        c_val = getattr(c_expr, "value", None)
        # Call IERC20(token).xxx
        if isinstance(c_expr, SliTypeConversion):
            ctrt_interface = c_expr.type.type
            return self.get_func_by_interface(ctrt_interface, key)

        # Call token.xxx
        if isinstance(c_expr, SliIdentifier):
            if isinstance(c_val, SliContract):
                # Call a library: Math.min(a, b);
                if c_val.is_library:
                    return self.get_func_from_library(c_val, key)
                else:
                    raise CornerCase("TODO")
            # Call a contract initialized by variable: token.transferFrom(a, b, amt);
            # token is a state variable or local variable
            elif isinstance(c_val, SliStateVariable) or isinstance(c_val, SliLocalVariable):
                # Solidity intrinsic call
                # address(abc).transfer()
                if not isinstance(c_val.type, SliUserDefinedType):
                    return []
                # called_value.signature == ('pair', [], ['IUniswapV2Pair'])
                interface = c_val.signature[-1][0]
                precise_func = self.get_func_by_interface(interface, key)
                if precise_func:
                    return precise_func
                imprecise_func = self.get_func_by_method_name(key)
                return imprecise_func
            # block.number
            elif isinstance(c_val, SolidityVariable):
                return []
            else:
                raise CornerCase("TODO")

        # 'UQ112x112.encode(_reserve1).uqdiv'
        if isinstance(c_expr, SliCallExpression):
            if isinstance(c_val, SliContract):
                cur_funcs = self.get_func_from_library(c_val, key)
            else:
                cur_funcs = []
            return cur_funcs + self.get_external_call_funcs(c_expr.called)

        # (blockNumber.sub(startBlock).sub(1)).div(decayPeriod);
        if isinstance(c_expr, SliTupleExpression):
            cur_funcs = []
            for expr in c_expr.expressions:
                cur_funcs.extend(self.get_external_call_funcs_from_expr(expr))
            return cur_funcs

        # Write to member
        # foo.abc = a;
        if isinstance(c_expr, SliMemberAccess):
            return []

        # Write to index
        # foo[0] = a;
        if isinstance(c_expr, SliIndexAccess):
            return []

        raise CornerCase("TODO")

    def get_ctrt_by_name(self, name: str):
        for ctrt in self.ctrts:
            if ctrt.name == name:
                return ctrt
        return None

    def _get_function_by_name(self, ctrt: SliContract, name: str) -> Optional[SliFunction]:
        return next(
            (
                f
                for f in ctrt.functions
                if f.name ==
                # Make sure it is the implementation instead of interface
                name and f.canonical_name.startswith(ctrt.name)
            ),
            None,
        )

    def get_func_by_name(self, ctrt_or_name: Union[SliContract, str], func_name: str):
        if isinstance(ctrt_or_name, str):
            ctrt = self.get_ctrt_by_name(ctrt_or_name)
            if ctrt is None:
                raise ValueError(f"Unknown contract name: {ctrt}")
        else:
            ctrt = ctrt_or_name
        return self._get_function_by_name(ctrt, func_name)

    def get_var_by_name(self, ctrt_name: str, var_name: str):
        ctrt = self.get_ctrt_by_name(ctrt_name)
        if ctrt is None:
            raise ValueError(f"Unknown contract name: {ctrt_name}")
        for sv in ctrt.state_variables:
            if sv.name == var_name:
                return sv
        return None

    def get_func_by_interface(self, interface: Union[SliContract, str], method_name: str):
        if isinstance(interface, SliContract):
            name = interface.name
        else:
            name = interface
        if name in (
            "IUniswapV2Pair",
            "IUniswapV2Router",
            "IUniswapV2Factory",
            "IERC20",
        ):
            # Hardcode for interface matching
            name = name.removeprefix("I")
        possible_funcs = []
        for ctrt in self.ctrts:
            possible_names = [ctrt.name] + [i.name for i in ctrt.inheritance]
            for c_name in possible_names:
                if name == c_name:
                    res = self.get_func_by_name(ctrt, method_name)
                    if res is None:
                        continue
                    possible_funcs.append(res)
        return possible_funcs

    def get_func_by_method_name(self, method_name: str):
        # Imprecise finding.
        possible_funcs = []
        for ctrt in self.ctrts:
            res = self.get_func_by_name(ctrt, method_name)
            if res is None:
                continue
            possible_funcs.append(res)
        return possible_funcs

    def get_func_from_library(self, library: SliContract, method_name: str):
        for func in library.functions:
            if func.name == method_name:
                return [func]
        return []

    def get_public_funcs(self, funcs: List[SliFunction]) -> List[SliFunction]:
        access_modifiers = ["onlyOwner", "onlyMinter"]
        ava_funcs = []
        for f in funcs:
            if f.is_constructor or f.is_constructor_variables or not f.is_implemented:
                continue
            if f.pure or f.view or f.visibility in ("internal", "private"):
                continue
            # Special access control
            has_access_modifier = any(m.name in access_modifiers for m in f.modifiers)
            if has_access_modifier:
                continue
            ava_funcs.append(f)
        return ava_funcs

    # def infer_transfer_formulas(self, func: SliFunction) -> List[Tokenflow]:
    #     source_ctrt = func.contract

    #     transfer_names = [f"{a}.transfer(address,uint256)" for a in ["ERC20", source_ctrt.name]]
    #     transferFrom_names = [f"{a}.transferFrom(address,uint256)" for a in ["ERC20", source_ctrt.name]]
    #     _burn_names = [f"{a}._burn(address,uint256)" for a in ["ERC20", source_ctrt.name]]
    #     _mint_names = [f"{a}._mint(address,uint256)" for a in ["ERC20", source_ctrt.name]]
    #     token_flows = []

    #     if func.canonical_name in transfer_names:
    #         token_flows = [init_default_token_transfer(source_ctrt, func)]

    #     if func.canonical_name in transferFrom_names:
    #         token_flows = [init_default_token_transferFrom(source_ctrt, func)]

    #     if func.canonical_name in _burn_names:
    #         token_flows = [init_default_token_transferFrom(source_ctrt, func)]

    #     if func.canonical_name in _mint_names:
    #         token_flows = [init_default_token_mint(source_ctrt, func)]

    #     return token_flows

    # def infer_token_flows(self, trace: TRACE, func: SliFunction) -> TRANS_SUMMARY:
    #     key = func.canonical_name
    #     _ctrt: SliContract = func.contract
    #     if key in self.func_trans_summary:
    #         res = []
    #         for o_trace, trans in self.func_trans_summary[key]:
    #             n_trace = trace + o_trace[1:]
    #             res.append((n_trace, trans))
    #         return res

    #     trans_summary = []

    #     external_calls_as_expressions = func.external_calls_as_expressions
    #     for call_expr in func.calls_as_expressions:
    #         if call_expr in external_calls_as_expressions:
    #             e_call_expr = call_expr
    #             if isinstance(e_call_expr.called, SliMemberAccess):
    #                 func_name = e_call_expr.called.member_name
    #                 if func_name == "transfer":
    #                     inst = self.init_transfer(_ctrt, e_call_expr)
    #                     trans_summary.append((trace, inst))
    #                     continue
    #                 if func_name == "transferFrom":
    #                     inst = self.init_transferFrom(e_call_expr)
    #                     trans_summary.append((trace, inst))
    #                     continue
    #                 # TODO
    #             ext_call_funcs = self.get_external_call_funcs_from_expr(e_call_expr)
    #             for e_func in ext_call_funcs:
    #                 new_trace: TRACE = [*trace, (e_func, e_call_expr)]
    #                 trans_summary.extend(self.infer_token_flows(new_trace, e_func))
    #         i_call_expr = call_expr
    #         called = i_call_expr.called

    #         # 'UQ112x112.encode(_reserve1)'
    #         if isinstance(called, SliMemberAccess):
    #             continue
    #         # Call new Uint();
    #         if isinstance(called, SliNewElementaryType):
    #             continue
    #         # Call new Array();
    #         if isinstance(called, SliNewArray):
    #             continue
    #         # Call new Contract();
    #         if isinstance(called, SliNewContract):
    #             continue
    #         c_val = i_call_expr.called.value

    #         # block.number
    #         if isinstance(c_val, SolidityFunction):
    #             continue

    #         # onlyOwner()
    #         if isinstance(c_val, SliModifier):
    #             continue

    #         # emit Event
    #         if isinstance(c_val, SliEvent):
    #             continue

    #         if isinstance(c_val, SliFunction) or isinstance(c_val, SliFunctionContract):
    #             # TODO
    #             if self.is_erc20(_ctrt) and func.name in (
    #                 "_burn",
    #                 "_mint",
    #             ):
    #                 if func.name == "_burn":
    #                     inst = self.init_burn(_ctrt, e_call_expr)
    #                     trans_summary.append((trace, inst))
    #                     continue
    #                 continue
    #             new_trace: TRACE = [*trace, (c_val, i_call_expr)]
    #             trans_summary.extend(self.infer_token_flows(new_trace, c_val))
    #             continue

    #         raise CornerCase("TODO")

    #     self.func_trans_summary[key] = trans_summary
    #     return trans_summary

    # def infer_func_summary(self, func: SliFunction) -> List[FuncSummary]:
    # key = func.canonical_name
    # source_ctrt = func.contract
    # if self.is_erc20(source_ctrt) and source_ctrt == func.contract:
    #     return []

    # # Infer swap, deposit, reward, etc...
    # func_summarys = []

    # # Collect all transfer.
    # trans_summary = self.infer_func_trans_summary([(func, None)], func)

    # if len(trans_summary) == 0:
    #     return []

    # # Concretize all possible values in transfer.
    # for trace, trans in trans_summary:
    #     if not isinstance(trans.token, str):
    #         r = self.get_fixed_expr_in_trace(trace, trans.token)
    #         if r:
    #             trans.token = r
    #     if not isinstance(trans.sender, str):
    #         r = self.get_fixed_expr_in_trace(trace, trans.sender)
    #         if r:
    #             trans.sender = r

    #     if not isinstance(trans.receiver, str):
    #         r = self.get_fixed_expr_in_trace(trace, trans.receiver)
    #         if r:
    #             trans.receiver = r

    # # Collect all parameters whose type related to address.
    # roles = list(self.role2ctrt.keys())
    # addr_num = self.count_type_amt_in_func(func, "address")

    # # Generate the binding plan.
    # for plan in itertools.product(roles, repeat=addr_num):
    #     binding = {}
    #     plan_idx = 0
    #     for param in func.parameters:
    #         p_type = param.type
    #         if isinstance(p_type, SliElementaryType):
    #             if p_type.name == "address":
    #                 cur_role = plan[plan_idx]
    #                 binding[param] = cur_role
    #                 plan_idx += 1
    #             elif p_type.name == "uint256":
    #                 # TODO financial parameters recognization.
    #                 pass
    #             elif p_type.name == "bytes":
    #                 # TODO
    #                 pass
    #             elif p_type.name == "string":
    #                 # TODO
    #                 pass
    #             else:
    #                 raise CornerCase("TODO")
    #         elif isinstance(p_type, SliArrayType):
    #             sub_type = p_type.type
    #             length = p_type.length if p_type.is_fixed_array else 2
    #             if isinstance(sub_type, SliElementaryType):
    #                 if sub_type.name == "address":
    #                     cur_roles = plan[plan_idx : plan_idx + length]
    #                     binding[param] = cur_roles
    #                     plan_idx += length
    #                 else:
    #                     raise CornerCase("TODO")
    #             else:
    #                 raise CornerCase("TODO")
    #         else:
    #             raise CornerCase("TODO")
    #     # Concretize all values in transfer.
    #     # If this plan isn't valid, it can't be concretized.
    #     token_flows: List[Tokenflow] = []
    #     invalid = False
    #     for trace, trans in trans_summary:
    #         n_trans = trans.copy()
    #         if not isinstance(n_trans.token, str):
    #             r = self.partial_eval_in_trace(trace, binding, n_trans.token)
    #             if not self.is_erc20(self.role2ctrt[r]):
    #                 invalid = True
    #                 break
    #             n_trans.token = r

    #         if not isinstance(n_trans.sender, str):
    #             r = self.partial_eval_in_trace(trace, binding, n_trans.sender)
    #             n_trans.sender = r

    #         if not isinstance(n_trans.receiver, str):
    #             r = self.partial_eval_in_trace(trace, binding, n_trans.receiver)
    #             n_trans.receiver = r

    #         if not n_trans.is_concrete:
    #             invalid = True
    #             break
    #         token_flows.append(n_trans)
    #     if invalid:
    #         continue

    #     # Hardcode
    #     # Map the actions to current handy function.
    #     action_name = ""
    #     me = "attackContract"

    #     # Infer swap
    #     transfer_to_me = False
    #     token_a = ""
    #     transfer_from_me = False
    #     token_b = ""
    #     for tf in token_flows:
    #         if tf.sender == me and tf.transfer_from:
    #             transfer_from_me = True
    #             token_a = tf.token
    #             for tf in token_flows:
    #                 if tf.receiver == me and tf.token != token_a:
    #                     transfer_to_me = True
    #                     token_b = tf.token
    #             if transfer_from_me and transfer_to_me:
    #                 # Hardcode
    #                 _role_name = "pair" if role_name == "router" else role_name
    #                 action_name = f"swap_{_role_name}_{token_a}_{token_b}"
    #     if action_name in self.action_names:
    #         func_summary = FunctionSummary(token_flows, action_name)
    #         func_summarys.append(func_summary)
    # return func_summarys
