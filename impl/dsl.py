from typing import Dict, List

from .config import Config, DefiRoles
from .financial_constraints import (
    ACTION_SUMMARY,
    gen_summary_ratioswap,
    gen_summary_uniswap,
)

from .utils import *


class DSLAction:
    def __init__(
        self,
        action_name: str,
        args_in_name: List[str],
        args: List[str],
        concrete: bool = False,
    ) -> None:
        self.action_name = action_name
        self.args_in_name = args_in_name
        self.args = args
        self.concrete = concrete

    def __eq__(self, __value: "DSLAction") -> bool:
        if self.action_name == "nop" and __value.action_name == "nop":
            return True
        return (
            (self.action_name == __value.action_name)
            and (self.args_in_name == __value.args_in_name)
            and (self.args == __value.args)
        )

    @property
    def func_sig(self) -> str:
        return "_".join([self.action_name, *self.args_in_name])

    def __str__(self) -> str:
        func_names = self.func_sig
        arg_names = ", ".join(self.args)
        return f"{func_names}({arg_names})"

    def symbolic_copy(self, arg_start_index: int) -> "DSLAction":
        args = [f"amt{i + arg_start_index}" for i in range(self.param_num)]
        return DSLAction(self.action_name, self.args_in_name, args, concrete=False)

    @property
    def param_num(self):
        return len(self.args)

    @property
    def swap_pairs(self):
        if self.action_name in ("swap",):
            return self.args_in_name[:-2]
        elif self.action_name in ("breaklr",):
            return self.args_in_name[:-1]
        elif self.action_name in ("burn",):
            return self.args_in_name[0:]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as swap_pair"
            )

    @property
    def asset0(self):
        if self.action_name in ("borrow", "payback"):
            return self.args_in_name[0]
        elif self.action_name in ("burn", "oracle", "transaction"):
            return self.args_in_name[1]
        elif self.action_name in ("swap",):
            return self.args_in_name[-2]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as asset0"
            )

    @property
    def asset1(self):
        if self.action_name in ("swap",):
            return self.args_in_name[-1]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as asset1"
            )

    @property
    def defi_entry(self):
        if self.action_name in ("transaction",):
            return self.args_in_name[0]
        elif self.action_name in ("breaklr",):
            return self.args_in_name[-1]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as defi_entry"
            )

    @property
    def amount(self):
        if self.action_name in ("swap", "borrow", "payback", "burn", "transaction"):
            return self.args[0]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as amount"
            )

    def check_implemented(self, roles: Dict[str, DefiRoles]) -> bool:
        if self.action_name == "swap":
            src_assets = set([self.asset0])
            for s in self.swap_pairs:
                new_src_assets = set()
                support_swaps = roles[s].support_swaps
                for sa in src_assets:
                    new_src_assets.update(support_swaps.get(sa, []))
                src_assets = new_src_assets
            return self.asset1 in src_assets
        elif self.action_name == "burn":
            return roles[self.asset0].is_burnable
        elif self.action_name == "transaction":
            return self.asset0 in roles[self.defi_entry].hacked_assets
        elif self.action_name == "breaklr":
            return self.swap_pairs[0] in roles[self.defi_entry].hacked_pairs
        return True

    def gen_constraints(self, config: Config) -> ACTION_SUMMARY:
        roles: Dict[str, DefiRoles] = config.roles
        if self.action_name == "nop":
            return ([], [])
        elif self.action_name == "swap":
            is_uniswap = roles[self.swap_pairs[0]].is_uniswap
            if is_uniswap:
                return gen_summary_uniswap(
                    self.swap_pairs[0], "attacker", self.asset0, self.asset1, "arg_0"
                )
            else:
                return gen_summary_ratioswap(
                    self.swap_pairs[0],
                    "pair",
                    "attacker",
                    self.asset0,
                    self.asset1,
                    "arg_0",
                )
        elif self.action_name == "borrow":
            b0a = f"balanceOf{self.asset0}attacker"
            return (
                [b0a],
                [
                    # fmt: off
                    lambda s: s.__getattr__(f"new_{b0a}") == s.__getattr__(f"old_{b0a}") + s.arg_0,
                    # fmt: on
                ],
            )
        elif self.action_name == "payback":
            b0a = f"balanceOf{self.asset0}attacker"
            return (
                [b0a],
                [
                    # fmt: off
                    lambda s: s.__getattr__(f"new_{b0a}") == s.__getattr__(f"old_{b0a}") - s.arg_0,
                    lambda s: s.arg_0 == s.arg_x0 * 1003 / 1000,
                    # fmt: on
                ],
            )
        elif self.action_name == "burn":
            b0p = f"balanceOf{self.asset0}{self.swap_pairs[0]}"
            return (
                [b0p],
                [
                    # fmt: off
                    lambda s: s.__getattr__(f"new_{b0p}") == s.__getattr__(f"old_{b0p}") - s.arg_0,
                    # fmt: on
                ],
            )
        elif self.action_name == "sync":
            return ([], [])
        elif self.action_name == "breaklr":
            return ([], [])
        elif self.action_name == "transaction":
            return ([], [])


class NOP(DSLAction):
    def __init__(
        self,
        concrete: bool = False,
    ) -> None:
        super().__init__("nop", [], [], concrete)


class Swap(DSLAction):
    def __init__(
        self,
        *args,
        concrete: bool = False,
    ) -> None:
        if len(args) < 4:
            raise ValueError(
                f"Length of arguments of a Swap must be larger than 4, current is: {args}"
            )
        swap_pairs: str = args[:-3]
        asset0: str = args[-3]
        asset1: str = args[-2]
        amount: str = args[-1]
        if asset0 == asset1:
            super().__init__("nop", [], [], True)
            return
        super().__init__("swap", [*swap_pairs, asset0, asset1], [amount], concrete)


class Borrow(DSLAction):
    def __init__(
        self,
        asset: str,
        amount: str,
        concrete: bool = False,
    ) -> None:
        super().__init__("borrow", [asset], [amount], concrete)


class Payback(DSLAction):
    def __init__(
        self,
        asset: str,
        amount: str,
        concrete: bool = False,
    ) -> None:
        super().__init__("payback", [asset], [amount], concrete)


class Burn(DSLAction):
    def __init__(
        self,
        pair: str,
        asset: str,
        amount: str,
        concrete: bool = False,
    ) -> None:
        super().__init__("burn", [pair, asset], [amount], concrete)


class BreakLR(DSLAction):
    def __init__(
        self,
        *args,
        concrete: bool = False,
    ) -> None:
        if len(args) < 2:
            raise ValueError(
                f"Length of arguments of a Swap must be larger than 2, current is: {args}"
            )
        swap_pairs: str = args[:-1]
        defi_entry: str = args[-1]
        super().__init__("breaklr", [*swap_pairs, defi_entry], [], concrete)


class Sync(DSLAction):
    def __init__(
        self,
        oracle: str,
        concrete: bool = False,
    ) -> None:
        super().__init__("sync", [oracle], [], concrete)


class Transaction(DSLAction):
    def __init__(
        self,
        defi_entry: str,
        asset: str,
        amount: str,
        concrete: bool = False,
    ) -> None:
        super().__init__("transaction", [defi_entry, asset], [amount], concrete)


action_name2cls = {
    "nop": NOP,
    "swap": Swap,
    "borrow": Borrow,
    "payback": Payback,
    "burn": Burn,
    "sync": Sync,
    "transaction": Transaction,
    "breaklr": BreakLR,
}


def init_action_from_list(strs: List[str], concrete: bool) -> DSLAction:
    action_name = strs[0]
    args = strs[1:]
    cls = action_name2cls[action_name]
    return cls(*args, concrete=concrete)


class Sketch:
    def __init__(self, actions: List[DSLAction]) -> None:
        self.actions = actions

    @property
    def len(self):
        return self.actions.__len__()

    @property
    def pure_len(self):
        return self.pure_actions.__len__()

    @property
    def pure_actions(self):
        return [a for a in self.actions if a.action_name != "nop"]

    @property
    def param_num(self):
        return sum(n.param_num for n in self.pure_actions)

    @property
    def args(self):
        r = []
        for a in self.pure_actions:
            r.extend(a.args)
        return r

    def concretize(self, args: List[str]) -> "Sketch":
        assert len(args) == self.param_num
        actions = []
        n = 0
        for a in self.actions:
            act_args = args[n : n+a.param_num]
            act = DSLAction(a.action_name, a.args_in_name, act_args, True)
            actions.append(act)
            n += a.param_num
        return Sketch(actions)

    def __eq__(self, __value: "Sketch") -> bool:
        if self.pure_len != __value.pure_len:
            return False
        pa0 = self.pure_actions
        pa1 = __value.pure_actions
        sames = [a == b for a, b in zip(pa0, pa1)]
        return all(sames)

    def symbolic_copy(self) -> "Sketch":
        """
        Rename all arguments in this sketch to symbolic ones.
        """
        arg_start_index = 0
        new_actions = []
        for a in self.actions:
            new_a = a.symbolic_copy(arg_start_index)
            new_actions.append(new_a)
            arg_start_index += new_a.param_num
        return Sketch(new_actions)

    def check_implemented(self, roles: Dict[str, DefiRoles]) -> bool:
        return all(a.check_implemented(roles) for a in self.pure_actions)

    def output(
        self,
        func_name: str,
        pre_statements: List[str] = None,
    ) -> List[str]:
        if pre_statements is None:
            pre_statements = []
        # Here, all of benchmarks have flashloan.
        pre_statements = [
            f"vm.assume({self.actions[-1].amount} == {self.actions[0].amount} * 1003 / 1000);",
            *pre_statements,
        ]

        params = [f"uint256 amt{i}" for i in range(self.param_num)]
        param_str = ",".join(params)

        func_body = []
        for s in self.pure_actions:
            func_body.append(f"{str(s)};")

        checker = [
            f"function {func_name}({param_str}) public " + "{",
            f"vm.startPrank(attacker);",
            *pre_statements,
            *func_body,
            "assert(!attackGoal());",
            f"vm.stopPrank();",
            "}",
        ]
        return checker

    def output_verify(
        self,
        func_name: str,
        pre_statements: List[str] = None,
        print_balance: bool = False,
    ) -> List[str]:
        func_body = []
        # action must be concrete
        for idx, a in enumerate(self.pure_actions):
            if not a.concrete:
                raise ValueError("Try to verify a sketch with non-concretized actions!")
            func_body.append(f"{str(a)};")
            if print_balance:
                func_body.append(f'printBalance("After step{idx} ");')
        verifier = [
            f"function {func_name}() public " + "{",
            f"vm.startPrank(attacker);",
            *pre_statements,
            *func_body,
            'require(attackGoal(), "Attack failed!");',
            f"vm.stopPrank();",
            "}",
        ]
        return verifier
