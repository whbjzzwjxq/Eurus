from decimal import Decimal
from typing import Dict, List

from impl.config import DefiRoles

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

    def __str__(self) -> str:
        func_names = "_".join([self.action_name, *self.args_in_name])
        arg_names = ", ".join(self.args)
        return f"{func_names}({arg_names})"

    def symbolic_copy(self, arg_start_index: int) -> "DSLAction":
        args = [f"amt{i + arg_start_index}" for i in range(self.param_num)]
        return DSLAction(self.action_name, self.args_in_name, args, concrete=False)

    @property
    def param_num(self):
        return len(self.args)

    @property
    def swap_pair(self):
        if self.action_name in ("swap"):
            return self.args_in_name[0]
        elif self.action_name in ("breaklr"):
            return self.args_in_name[1]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as swap_pair"
            )

    @property
    def asset0(self):
        if self.action_name in ("swap", "burn", "oracle", "transaction"):
            return self.args_in_name[1]
        elif self.action_name in ("borrow", "payback"):
            return self.args_in_name[0]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as asset0"
            )

    @property
    def asset1(self):
        if self.action_name in ("swap"):
            return self.args_in_name[2]
        else:
            raise ValueError(
                f"This action: {self.action_name} doesn't have a role as asset1"
            )
        
    @property
    def defi_entry(self):
        if self.action_name in ("transaction", "breaklr"):
            return self.args_in_name[0]
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
            return self.asset1 in roles[self.swap_pair].support_swaps.get(
                self.asset0, []
            )
        elif self.action_name == "burn":
            return roles[self.asset0].is_burnable
        elif self.action_name == "transaction":
            return self.asset0 in roles[self.defi_entry].hacked_assets
        elif self.action_name == "breaklr":
            return self.swap_pair in roles[self.defi_entry].hacked_pairs
        return True


class NOP(DSLAction):
    def __init__(
        self,
        concrete: bool = False,
    ) -> None:
        super().__init__("nop", [], [], concrete)


class Swap(DSLAction):
    def __init__(
        self,
        swap_pair: str,
        asset0: str,
        asset1: str,
        amount: str,
        concrete: bool = False,
    ) -> None:
        if asset0 == asset1:
            super().__init__("nop", [], [], True)
            return
        super().__init__("swap", [swap_pair, asset0, asset1], [amount], concrete)


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
        oracle: str,
        asset: str,
        amount: str,
        concrete: bool = False,
    ) -> None:
        super().__init__("burn", [oracle, asset], [amount], concrete)


class BreakLR(DSLAction):
    def __init__(
        self,
        defi_entry: str,
        pair: str,
        concrete: bool = False,
    ) -> None:
        super().__init__("breaklr", [defi_entry, pair], [], concrete)


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

    def output_test(self, func_name: str) -> List[str]:
        func_body = []
        for idx, s in enumerate(self.pure_actions):
            func_body.append(f"{str(s)};")
            func_body.append(f'printBalance("After step{idx} ");')

        final_assert = 'require(attackGoal(), "Attack failed!");'

        checker = [
            f"function {func_name}() public " + "{",
            *func_body,
            final_assert,
            "}",
        ]
        return checker

    def output(
        self,
        func_name: str,
        flashloan_amount: Decimal,
        constraints: List[str] = None,
    ) -> List[str]:
        if constraints is None:
            constraints = []
        # Here, all of benchmarks have flashloan.
        constraints = [
            f"{self.actions[-1].amount} == {self.actions[0].amount} + {int(flashloan_amount * Decimal(0.003))}",
            *constraints,
        ]

        params = [f"uint256 amt{i}" for i in range(self.param_num)]
        param_str = ",".join(params)

        func_body = []
        for s in self.pure_actions:
            func_body.append(f"{str(s)};")

        final_assert = "assert(!attackGoal());"

        checker = [
            f"function {func_name}({param_str}) public " + "{",
            *[f"vm.assume({c});" for c in constraints],
            *func_body,
            final_assert,
            "}",
        ]
        return checker
