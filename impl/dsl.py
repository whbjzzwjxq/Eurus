from typing import List, Union, Dict

from .financial_constraints import *
from .utils import *
from .utils_slither import *


class Tokenflow:
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
        return isinstance(self.token, str) and isinstance(self.sender, str) and isinstance(self.receiver, str)

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


class AFLAction:
    def __init__(self, action_name: str, args_in_name: List[str], args: List[str], concrete: bool = False) -> None:
        self.action_name = action_name
        self.args_in_name = args_in_name
        self.args = args
        self.concrete = concrete

        self.token_flows: List[Tokenflow] = []
        self.constraints: List[ACTION_CONSTR] = []

    def __eq__(self, __value: "AFLAction") -> bool:
        if self.action_name == "nop" and __value.action_name == "nop":
            return True
        return (self.action_name == __value.action_name) and (self.args_in_name == __value.args_in_name)

    @property
    def func_sig(self) -> str:
        return "_".join([self.action_name, *self.args_in_name])

    def __str__(self) -> str:
        func_names = self.func_sig
        arg_names = ", ".join(self.args)
        return f"{func_names}({arg_names})"

    def symbolic_copy(self, arg_start_index: int) -> "AFLAction":
        args = [f"amt{i + arg_start_index}" for i in range(self.param_num)]
        action = AFLAction(self.action_name, self.args_in_name, args, concrete=False)
        action.token_flows = [*self.token_flows]
        action.constraints = [*self.constraints]
        return action

    @property
    def param_num(self):
        return len(self.args)

    @property
    def swap_pair(self) -> str:
        # Assume deposit and withdraw are swap
        if self.action_name in ("swap", "deposit", "withdraw"):
            return self.args_in_name[0]
        elif self.action_name in ("addliquidity"):
            return self.args_in_name[1]
        else:
            raise NotImplementedError

    @property
    def token0(self):
        if self.action_name in ("burn", "mint", "borrow", "payback"):
            return self.args_in_name[0]
        elif self.action_name in ("deposit", "withdraw"):
            return self.args_in_name[1]
        elif self.action_name in ("swap", "addliquidity"):
            return self.args_in_name[2]
        else:
            raise NotImplementedError

    @property
    def token1(self):
        if self.action_name in ("swap", "addliquidity"):
            return self.args_in_name[3]
        elif self.action_name in ("deposit", "withdraw"):
            return self.args_in_name[2]
        else:
            raise NotImplementedError

    @property
    def defi(self):
        if self.action_name in ("addliquidity", "deposit", "withdraw", "transaction"):
            return self.args_in_name[0]
        else:
            raise NotImplementedError

    @property
    def lender(self):
        if self.action_name in ("borrow", "payback"):
            return self.args_in_name[1]
        else:
            raise NotImplementedError

    @property
    def account(self):
        if self.action_name in ("burn", "mint", "addliquidity", "swap"):
            return self.args_in_name[1]
        elif self.action_name in ("deposit", "withdraw", "borrow", "payback"):
            return ATTACKER
        else:
            raise NotImplementedError

    @property
    def amount0(self):
        if self.action_name in ("burn", "mint", "swap", "borrow", "payback", "deposit", "withdraw"):
            return self.args[0]
        else:
            raise NotImplementedError

    @property
    def amount1(self):
        if self.action_name in ("swap",):
            return self.args[1]
        else:
            raise NotImplementedError

    def update(self, token_flows=None, constraints=None):
        if token_flows is None:
            token_flows = []
        if constraints is None:
            constraints = []
        self.token_flows = token_flows
        self.constraints = constraints


class NOP(AFLAction):
    def __init__(self, concrete: bool = False) -> None:
        super().__init__("nop", [], [], concrete)


class Burn(AFLAction):
    def __init__(self, token: str, account: str, amount: str, concrete: bool = False) -> None:
        super().__init__("burn", [token, account], [amount], concrete)


class Mint(AFLAction):
    def __init__(self, token: str, account: str, amount: str, concrete: bool = False) -> None:
        super().__init__("mint", [token, account], [amount], concrete)


class Swap(AFLAction):
    def __init__(
        self,
        pair: str,
        account: str,
        token0: str,
        token1: str,
        amountIn: str,
        amountOutMin: str,
        concrete: bool = False,
    ) -> None:
        if token0 == token1:
            super().__init__("nop", [], [], True)
            return
        super().__init__("swap", [pair, account, token0, token1], [amountIn, amountOutMin], concrete)


class Borrow(AFLAction):
    def __init__(self, token: str, lender: str, amount: str, concrete: bool = False) -> None:
        super().__init__("borrow", [token, lender], [amount], concrete)


class Payback(AFLAction):
    def __init__(self, token: str, lender: str, amount: str, concrete: bool = False) -> None:
        super().__init__("payback", [token, lender], [amount], concrete)


# Beyond Swap
class AddLiquidity(AFLAction):
    def __init__(self, defi: str, swap_pair: str, token0: str, token1: str, concrete: bool = False) -> None:
        super().__init__("addliquidity", [defi, swap_pair, token0, token1], [], concrete)


class Deposit(AFLAction):
    def __init__(self, defi: str, token0: str, token1: str, amount: str, concrete: bool = False) -> None:
        super().__init__("deposit", [defi, token0, token1], [amount], concrete)


class Withdraw(AFLAction):
    def __init__(self, defi: str, token0: str, token1: str, amount: str, concrete: bool = False) -> None:
        super().__init__("withdraw", [defi, token0, token1], [amount], concrete)


# General Transaction
# I think it is never used.
class Transaction(AFLAction):
    def __init__(self, defi: str, concrete: bool = False) -> None:
        super().__init__("transaction", [defi], [], concrete)


action_name2cls = {
    "nop": NOP,
    "burn": Burn,
    "mint": Mint,
    "swap": Swap,
    "borrow": Borrow,
    "payback": Payback,
    "addliquidity": AddLiquidity,
    "deposit": Deposit,
    "withdraw": Withdraw,
    "transaction": Transaction,
}


def init_action_from_list(strs: List[str], concrete: bool) -> AFLAction:
    action_name = strs[0]
    args = strs[1:]
    cls = action_name2cls[action_name]
    return cls(*args, concrete=concrete)


class Sketch:
    def __init__(self, actions: List[AFLAction]) -> None:
        self._actions = actions

    def __len__(self):
        return self.pure_actions.__len__()

    @property
    def pure_actions(self):
        return [a for a in self._actions if a.action_name != "nop"]

    @property
    def param_num(self):
        return sum(n.param_num for n in self.pure_actions)

    @property
    def args(self):
        r = []
        for a in self.pure_actions:
            r.extend(a.args)
        return r

    @property
    def func_sigs(self):
        return [a.func_sig for a in self.pure_actions]

    def concretize(self, args: List[str]) -> "Sketch":
        assert len(args) == self.param_num
        actions = []
        n = 0
        for a in self._actions:
            act_args = args[n : n + a.param_num]
            act = AFLAction(a.action_name, a.args_in_name, act_args, True)
            actions.append(act)
            n += a.param_num
        return Sketch(actions)

    def __eq__(self, __value: "Sketch") -> bool:
        if len(self) != len(__value):
            return False
        pa0 = self.pure_actions
        pa1 = __value.pure_actions
        sames = [a.func_sig == b.func_sig for a, b in zip(pa0, pa1)]
        return all(sames)

    def __str__(self) -> str:
        return "\n".join([str(a) for a in self.pure_actions])

    def symbolic_copy(self) -> "Sketch":
        """
        Rename all arguments in this sketch to symbolic ones.
        """
        arg_start_index = 0
        new_actions = []
        for a in self._actions:
            new_a = a.symbolic_copy(arg_start_index)
            new_actions.append(new_a)
            arg_start_index += new_a.param_num
        return Sketch(new_actions)

    def match_borrow_payback(self, idx: int) -> int:
        a = self.pure_actions[idx]
        if a.action_name == "borrow":
            pair_name = "payback"
        elif a.action_name == "payback":
            pair_name = "borrow"
        else:
            raise ValueError(f"Index: {idx} is not a borrow/payback action. Sketch is: {str(self)}")
        for i, a1 in enumerate(self.pure_actions):
            if a1.action_name == pair_name and a1.lender == a.lender:
                return i
        return -1

    def output(self, func_name: str, pre_statements: List[str] = None) -> List[str]:
        if pre_statements is None:
            pre_statements = []
        else:
            pre_statements = [*pre_statements]
        # Here, all of benchmarks have flashloan.
        for idx, a in enumerate(self.pure_actions):
            if a.action_name == "borrow":
                a1_idx = self.match_borrow_payback(idx)
                a1 = self.pure_actions[a1_idx]
                f = f"vm.assume({a1.amount0} >= {a.amount0});"
                pre_statements.append(f)

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

    def output_verify(self, func_name: str, pre_statements: List[str] = None, print_balance: bool = False) -> List[str]:
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

    def get_action_idx_by_sig(self, func_sig: str) -> int:
        for idx, a in enumerate(self.pure_actions):
            if a.func_sig == func_sig:
                return idx
        return -1


hack_token_flows: Dict[str, Dict[str, List[Tokenflow]]] = {}
