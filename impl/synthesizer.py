import itertools
from typing import List, Set, Optional, Union, Dict, Iterable, Callable, Any
from .utils_slither import *

from .config import Config, init_config
from .dsl import *
from .utils import *


class Tokenflow:
    SENDER = "msg.sender"
    ZERO = "address(0x0)"
    DEAD = "address(0xdead)"

    def __init__(
        self,
        token: Union[SliExpression, SliVariable, str],
        sender: Union[SliExpression, SliVariable, str],
        receiver: Union[SliExpression, SliVariable, str],
        amount: Union[SliExpression, SliVariable, str],
        transfer_from: bool = False,
    ) -> None:
        self.token = token
        self.sender = sender
        self.receiver = receiver
        self.amount = amount
        self.transfer_from = transfer_from

    @property
    def is_concrete(self) -> bool:
        return (
            isinstance(self.token, str)
            and isinstance(self.sender, str)
            and isinstance(self.receiver, str)
        )
    
    def __copy__(self):
        return Tokenflow(
            self.token,
            self.sender,
            self.receiver,
            self.amount,
            self.transfer_from,
        )
    
    def copy(self):
        return self.__copy__()


TRACE = List[Tuple[SliFunction, SliCallExpression]]

TRANS_SUMMARY = List[Tuple[TRACE, Tokenflow]]


class FunctionSummary:
    def __init__(
        self,
        token_flows: List[Tokenflow],
        func_name: str,
        func_params: str,
        func_body: str,
    ) -> None:
        self.token_flows = token_flows
        self.func_name = func_name
        self.func_params = func_params
        self.func_body = func_body


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
        return destruct_expr(expr.expression_left).union(
            destruct_expr(expr.expression_right)
        )
    
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
    # Hack
    hack_storage_var_mapping = {"MUMUG": {"mubank._MuCoin": "mu"}}

    def __init__(self, bmk_dir: str) -> None:
        self.config: Config = init_config(bmk_dir)
        self.sli = gen_slither(bmk_dir)
        test_ctrt_name = f"{self.config.project_name}Test"
        self.test_ctrt = self.sli.get_contract_from_name(test_ctrt_name)[0]

        self.role2ctrt_names = self._init_role2names()
        self.role2ctrt = self._init_role2ctrts()
        self.init_storage = self._init_storage_var_mapping()

        self._infer()

    def _init_storage_var_mapping(self):
        basic = self.hack_storage_var_mapping[self.config.project_name]

        for name, role in self.config.roles.items():
            if role.is_uniswap:
                storage = {
                    f"{name}._token0": role.uniswap_order[0],
                    f"{name}._token1": role.uniswap_order[1],
                    f"{name}.token0": role.uniswap_order[0],
                    f"{name}.token1": role.uniswap_order[1],
                }
                basic.update(storage)
        return basic

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

    def _infer(self):
        # Infer erc20 contracts
        self.func_trans_summary: Dict[str, TRANS_SUMMARY] = {}
        self.func_summarys: Dict[str, List[FunctionSummary]] = {}
        self.erc20_summarys: Dict[str, ERC20Summary] = {}
        for role_name, ctrt in self.role2ctrt.items():
            if not self.is_erc20(ctrt):
                continue

            # Infer the behaviors of functions in ERC20
            ava_funcs = self.get_ava_funcs(ctrt.functions_entry_points)
            transfer_summary, transfer_from_summary = [], []
            for func in ava_funcs:
                token_flows = self.infer_transfer_formulas(func)
                if func.name == "transfer":
                    transfer_summary = token_flows
                if func.name == "transferFrom":
                    transfer_from_summary = token_flows
            summary = ERC20Summary(ctrt, transfer_summary, transfer_from_summary)
            self.erc20_summarys[role_name] = summary

        # Infer contracts
        for role_name, ctrt in self.role2ctrt.items():
            ava_funcs = self.get_ava_funcs(ctrt.functions_entry_points)
            # Infer actions
            for func in ava_funcs:
                func_summarys = self.infer_func_summs(role_name, func)
                self.func_summarys[func.canonical_name] = func_summarys

        print(1)

    def infer_transfer_formulas(self, func: SliFunction) -> List[Tokenflow]:
        source_ctrt = func.contract

        transfer_insts = []

        if func.canonical_name == "ERC20.transfer(address,uint256)":
            transfer_insts = [init_default_token_transfer(source_ctrt, func)]

        if func.canonical_name == "ERC20.transferFrom(address,address,uint256)":
            transfer_insts = [init_default_token_transferFrom(source_ctrt, func)]

        if func.canonical_name == "ERC20._burn(address,uint256)":
            transfer_insts = [init_default_token_transferFrom(source_ctrt, func)]

        if func.canonical_name == "ERC20._mint(address,uint256)":
            transfer_insts = [init_default_token_mint(source_ctrt, func)]

        # Todo
        return transfer_insts

    def infer_func_trans_summary(
        self, trace: TRACE, func: SliFunction
    ) -> TRANS_SUMMARY:
        key = func.canonical_name
        source_func: SliFunction = trace[0][0]
        source_ctrt: SliContract = source_func.contract
        if self.is_erc20(source_ctrt) and source_ctrt == func.contract:
            return []

        if key in self.func_trans_summary:
            res = []
            for o_trace, trans in self.func_trans_summary[key]:
                n_trace = trace + o_trace[1:]
                res.append((n_trace, trans))
            return res

        trans_summary = []

        external_calls_as_expressions = func.external_calls_as_expressions
        for call_expr in func.calls_as_expressions:
            if call_expr in external_calls_as_expressions:
                continue
            i_call_expr = call_expr
            called = i_call_expr.called

            # 'UQ112x112.encode(_reserve1)'
            if isinstance(called, SliMemberAccess):
                continue
            # Call new Uint();
            if isinstance(called, SliNewElementaryType):
                continue
            # Call new Array();
            if isinstance(called, SliNewArray):
                continue
            # Call new Contract();
            if isinstance(called, SliNewContract):
                continue
            c_val = i_call_expr.called.value

            # block.number
            if isinstance(c_val, SolidityFunction):
                continue

            # onlyOwner()
            if isinstance(c_val, SliModifier):
                continue

            # emit Event
            if isinstance(c_val, SliEvent):
                continue

            if isinstance(c_val, SliFunction) or isinstance(c_val, SliFunctionContract):
                new_trace: TRACE = [*trace, (c_val, i_call_expr)]
                trans_summary.extend(self.infer_func_trans_summary(new_trace, c_val))
                continue

            raise CornerCase("TODO")

        for e_call_expr in func.external_calls_as_expressions:
            if isinstance(e_call_expr.called, SliMemberAccess):
                func_name = e_call_expr.called.member_name
                if func_name == "transfer":
                    trans_summary.append(
                        (trace, self.init_transfer(func.contract, e_call_expr))
                    )
                    continue
                if func_name == "transferFrom":
                    trans_summary.append((trace, self.init_transferFrom(e_call_expr)))
                    continue
            ext_call_funcs = self.get_external_call_funcs_from_expr(e_call_expr)
            for e_func in ext_call_funcs:
                new_trace: TRACE = [*trace, (e_func, e_call_expr)]
                trans_summary.extend(self.infer_func_trans_summary(new_trace, e_func))
        self.func_trans_summary[key] = trans_summary
        return trans_summary

    def infer_func_summs(self, role_name: str, func: SliFunction) -> List[FunctionSummary]:
        key = func.canonical_name
        source_ctrt = func.contract
        if self.is_erc20(source_ctrt) and source_ctrt == func.contract:
            return []

        # Infer swap, deposit, reward, etc...
        func_summarys = []

        # Collect all transfer.
        trans_summary = self.infer_func_trans_summary([(func, None)], func)

        if len(trans_summary) == 0:
            return []

        # Concretize all possible values in transfer.
        for trace, trans in trans_summary:
            if not isinstance(trans.token, str):
                r = self.get_fixed_expr_in_trace(trace, trans.token)
                if r:
                    trans.token = r
            if not isinstance(trans.sender, str):
                r = self.get_fixed_expr_in_trace(trace, trans.sender)
                if r:
                    trans.sender = r

            if not isinstance(trans.receiver, str):
                r = self.get_fixed_expr_in_trace(trace, trans.receiver)
                if r:
                    trans.receiver = r

        # Collect all parameters whose type related to address.
        addr_num = 0
        param2addr_idx = {}
        for param in func.parameters:
            if isinstance(param.type, SliElementaryType):
                if param.type.name == "address":
                    param2addr_idx[param] = (addr_num, addr_num)
                    addr_num += 1
                continue
            if isinstance(param.type, SliArrayType):
                length = 2
                if not param.type.is_dynamic_array:
                    length = param.type.length
                sub_type = param.type.type
                if isinstance(sub_type, SliElementaryType):
                    if sub_type.name == "address":
                        param2addr_idx[param] = (addr_num, addr_num + length)
                        addr_num += length
                    continue
            raise CornerCase("TODO")

        roles = list(self.role2ctrt.keys())

        # Generate binding plan.
        for plan in itertools.product(roles, repeat=addr_num):
            binding = {}
            for k, v in param2addr_idx.items():
                s, e = v
                if s == e:
                    binding[k] = plan[s]
                else:
                    addresses = plan[s:e]
                    binding[k] = addresses
            # Concretize all values in transfer.
            # If this plan isn't valid, it can't be concretized.

            token_flows = []
            invalid = False
            for trace, trans in trans_summary:
                n_trans = trans.copy()
                if not isinstance(n_trans.token, str):
                    r = self.partial_eval_in_trace(trace, binding, n_trans.token)
                    n_trans.token = r

                if not isinstance(n_trans.sender, str):
                    r = self.partial_eval_in_trace(trace, binding, n_trans.sender)
                    n_trans.sender = r

                if not isinstance(n_trans.receiver, str):
                    r = self.partial_eval_in_trace(trace, binding, n_trans.receiver)
                    n_trans.receiver = r
                
                if not n_trans.is_concrete:
                    invalid = True
                    break
                token_flows.append(n_trans)
            if invalid:
                continue
            func_name = f"call_{role_name}_{func.name}"
            func_params = f""
            func_body = f""

            func_summary = FunctionSummary(token_flows, func_name, func_params, func_body)

            func_summarys.append(func_summary)
        return func_summarys

    # Utils
    def init_transfer(
        self, ctrt: SliContract, called_expr: SliCallExpression
    ) -> Tokenflow:
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
            return "attackContract"
        if str(var) == "this":
            return self.get_role_name_by_ctrt(func.contract)
        key = f"{self.get_role_name_by_ctrt(func.contract)}.{str(var)}"
        return self.init_storage[key]

    def partial_eval(
        self, func: SliFunction, binding: Dict[SliVariable, Any], expr: SliExpression
    ):
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
                    # Hack
                    for role_name, role in self.config.roles.items():
                        if role.uniswap_order == [token0, token1] or role.uniswap_order == [token1, token0]:
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

    def partial_eval_in_trace(
        self, trace: TRACE, binding: Dict[SliVariable, Any], expr: SliExpression
    ):
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

    def get_external_call_funcs_from_expr(
        self, e_call_expr: SliExpression
    ) -> List[SliFunction]:
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
            elif isinstance(c_val, SliStateVariable) or isinstance(
                c_val, SliLocalVariable
            ):
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

    def _get_function_by_name(
        self, ctrt: SliContract, name: str
    ) -> Optional[SliFunction]:
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

    def get_func_by_canonical_name(self, canonical_name: str, method_name: str):
        # Precise finding.
        tgt_ctrt_name = self.config.contract_names_mapping.get(canonical_name, None)
        tgt_ctrt = self.get_ctrt_by_name(tgt_ctrt_name)
        if tgt_ctrt is None:
            return None
        return self._get_function_by_name(tgt_ctrt, method_name)

    def get_func_by_interface(
        self, interface: Union[SliContract, str], method_name: str
    ):
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

    def get_ava_funcs(self, funcs: List[SliFunction]) -> List[SliFunction]:
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
            if f.name in (
                "addLiquidity",
                "addLiquidityETH",
                "removeLiquidity",
                "removeLiquidityETH",
                "removeLiquidityWithPermit",
                "removeLiquidityETHWithPermit",
                "removeLiquidityETHSupportingFeeOnTransferTokens",
                "removeLiquidityETHWithPermitSupportingFeeOnTransferTokens",
                "swapExactTokensForTokens",
                "swapTokensForExactTokens",
                "swapExactETHForTokens",
                "swapTokensForExactETH",
                "swapExactTokensForETH",
                "swapETHForExactTokens",
                "swapExactETHForTokensSupportingFeeOnTransferTokens",
                "swapExactTokensForETHSupportingFeeOnTransferTokens",
            ):
                continue
            ava_funcs.append(f)
        return ava_funcs

    def is_groundtruth(self, candidate: List[SliFunction]) -> bool:
        # if len(candidate) != len(self.config.groundtruth):
        #     return False
        # else:
        #     for f1, f2 in zip(candidate, self.config.groundtruth):
        #         f1_ctrt_name = f1.contract.name
        #         f1_func_name = f1.name
        #         f2_ctrt_name, f2_func_name = f2.split(".")
        #         if f1_ctrt_name != f2_ctrt_name or f1_func_name != f2_func_name:
        #             return False
        #     return True
        return False


class SynthesizerByPattern:
    def __init__(self, config: Config):
        self.config = config
        self.roles = self.config.roles
        self.candidates: List[Sketch] = []
        self.candidates_signs: Set[str] = set()
        actions = [init_action_from_list(a, True) for a in self.config.groundtruth]
        self.gt_sketch = Sketch(actions).symbolic_copy()

        if self.config.pattern == "BuySell Manipulation":
            self.gen_candidates_buysell()
        elif self.config.pattern == "Price Discrepancy":
            self.gen_candidates_pricediscrepancy()
        elif self.config.pattern == "Token Burn":
            self.gen_candidates_tokenburn()
        elif self.config.pattern == "Liquidity Ratio Break":
            self.gen_candidates_lrbreak()
        else:
            raise CornerCase(f"Unknown pattern: {self.config.pattern}!")

        self.candidates: List[Sketch] = sorted(self.candidates, key=len)

        # Remove all candidates after the ground-truth
        gt_idx = -1
        for idx, c in enumerate(self.candidates):
            if len(c) != len(self.gt_sketch):
                continue
            if c == self.gt_sketch:
                gt_idx = idx
        if gt_idx == -1:
            raise ValueError("Ground truth is not covered by the candidates!")
        self.candidates = self.candidates[: gt_idx + 1]

    def check_duplicated(self, sketch: Sketch) -> bool:
        return str(sketch) in self.candidates_signs

    def extend_candidates_from_template(
        self,
        template: List[DSLAction],
        template_times: List[int],
    ):
        sketches: List[Sketch] = []
        for times in itertools.product(*template_times):
            actions = []
            for i in range(len(template)):
                t = times[i]
                actions.extend([template[i]] * t)
            # Rename parameters
            sketch = Sketch(actions).symbolic_copy()
            # Prune too long candidates
            if len(sketch) > len(self.gt_sketch):
                continue
            sketches.append(sketch)

        for s in sketches:
            if not s.check_implemented(self.roles):
                continue
            if self.check_duplicated(s):
                continue
            self.candidates.append(s)
            self.candidates_signs.add(str(s))

    def gen_candidates_buysell(self):
        lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
        defi_entrys = [k for k, v in self.roles.items() if v.is_defientry]
        # timer = time.perf_counter()
        # i = 0
        # fmt: off
        for (
            lend_pool0, lend_pool1, asset0, asset1, swap_pair0, asset2, asset3, defi_entry, asset_hacked, swap_pair1, swap_pair2, stable_coin
        ) in itertools.product(
            lend_pools, lend_pools, assets, assets, swap_pairs, assets, assets, defi_entrys, assets, swap_pairs, swap_pairs, stable_coins
        ):
            template: List[DSLAction] = [
                Borrow(lend_pool0, asset0, "amt0"),
                    Borrow(lend_pool1, asset1, "amt1"),
                        Swap(swap_pair0, asset2, asset3, "amt2"),
                        Transaction(defi_entry, asset_hacked, "amt3"),
                        Swap(swap_pair0, asset3, asset2, "amt4"),
                    Payback(lend_pool1, asset1, "amt5"),
                    Swap(swap_pair1, asset_hacked, stable_coin, "amt6"),
                    Swap(swap_pair2, stable_coin, asset0, "amt7"),
                Payback(lend_pool0, asset0, "amt8"),
            ]
        # fmt: on
            template_times = [
                (0, 1),
                (0, 1),
                (0, 1),
                (1,),
                (0, 1),
                (0, 1),
                (0, 1),
                (0, 1),
                (0, 1),
            ]

            self.extend_candidates_from_template(template, template_times)

            # print(f"Epoch {i} timecost: {time.perf_counter() - timer}")
            # timer = time.perf_counter()
            # i += 1

    def gen_candidates_pricediscrepancy(self):
        lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
        oracles = [k for k, v in self.roles.items() if v.is_oracle]
        # fmt: off
        for (
            lend_pool0, asset0, swap_pair0, asset1, oracle, swap_pair1, swap_pair2, stable_coin, swap_pair3
        ) in itertools.product(
            lend_pools, assets, swap_pairs, assets, oracles, swap_pairs, swap_pairs, stable_coins, swap_pairs
        ):
            template: List[DSLAction] = [
                Borrow(lend_pool0, asset0, "amt0"),
                    Swap(swap_pair0, asset0, asset1, "amt1"),
                    Sync(oracle),
                    Swap(swap_pair1, asset1, asset0, "amt2"),
                    Swap(swap_pair2, asset0, stable_coin, "amt3"),
                    Swap(swap_pair3, asset1, stable_coin, "amt4"),
                Payback(lend_pool0, asset0, "amt5"),
            ]
        # fmt: on

            template_times = [
                (1,),
                (1,),
                (0, 1),
                (1,),
                (0, 1),
                (0, 1),
                (1,),
            ]
            self.extend_candidates_from_template(template, template_times)

    def gen_candidates_tokenburn(self):
        lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
        oracles = [k for k, v in self.roles.items() if v.is_oracle]
        # fmt: off
        for (
            lend_pool0, asset0, swap_pair0, asset1, oracle, swap_pair1, swap_pair2, stable_coin,
        ) in itertools.product(
            lend_pools, assets, swap_pairs, assets, oracles, swap_pairs, swap_pairs, stable_coins
        ):
            template: List[DSLAction] = [
                Borrow(lend_pool0, asset0, "amt0"),
                    Swap(swap_pair0, asset0, asset1, "amt1"),
                    Burn(oracle, asset1, "amt2"),
                    Sync(oracle),
                    Swap(swap_pair0, asset1, asset0, "amt3"),
                    Swap(swap_pair1, asset0, stable_coin, "amt4"),
                    Swap(swap_pair2, asset1, stable_coin, "amt5"),
                Payback(lend_pool0, asset0, "amt6"),
            ]
        # fmt: on
            template_times = [
                (1,),
                (1,),
                (1,),
                (0, 1),
                (1,),
                (0, 1),
                (0, 1),
                (1,),
            ]
            self.extend_candidates_from_template(template, template_times)

    def gen_candidates_lrbreak(self):
        lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
        oracles = [k for k, v in self.roles.items() if v.is_oracle]
        defi_entrys = [k for k, v in self.roles.items() if v.is_defientry]
        # fmt: off
        for (
            lend_pool0, asset0, swap_pair0, asset1, defi_entry, oracle, swap_pair1, swap_pair2, stable_coin,
        ) in itertools.product(
            lend_pools, assets, swap_pairs, assets, defi_entrys, oracles, swap_pairs, swap_pairs, stable_coins,
        ):
            template: List[DSLAction] = [
                Borrow(lend_pool0, asset0, "amt0"),
                    Swap(swap_pair0, asset0, asset1, "amt1"),
                    BreakLR(oracle, defi_entry),
                    Sync(oracle),
                    Swap(swap_pair0, asset1, asset0, "amt3"),
                    Swap(swap_pair1, asset0, stable_coin, "amt4"),
                    Swap(swap_pair2, asset1, stable_coin, "amt5"),
                Payback(lend_pool0, asset0, "amt6"),
            ]
        # fmt: on
            template_times = [
                (1,),
                (1,),
                (1,),
                (0, 1),
                (1,),
                (0, 1),
                (0, 1),
                (1,),
            ]
            self.extend_candidates_from_template(template, template_times)
