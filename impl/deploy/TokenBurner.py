from os import path

from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer


class TokenBurner(ContractDeployer):

    attacker_init_balance = ContractDeployer.attacker_init_balance + 1 * ether
    init_token_supply = 100 * ether
    init_token_balance = ContractDeployer.attacker_init_balance + 100 * ether
    required_balance = 100 * ether

    def __init__(self) -> None:
        super().__init__("TokenBurner")

    def _deploy_hook(self):
        ctrt_pool_path = path.join(self.ctrt_dir, "TokenBurner.sol")

        self.main_ctrt = self._compile(ctrt_pool_path, "TokenBurner",
                                       (self.init_token_supply,), balance=self.init_token_balance)

    def _check(self):
        self.main_ctrt._check(self.attacker, self.required_balance, caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_sums = [
            ("TokenBurner", "approve"),
            ("TokenBurner", "burn"),
            ("TokenBurner", "mint"),
            ("TokenBurner", "swapETH"),
            ("TokenBurner", "swapToken"),
            ("TokenBurner", "transfer"),
            ("TokenBurner", "transferFrom"),
        ]
        func_sums = [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                     for addr_name, func_name in func_sums]
        return [*func_sums,
                # self._transfer_func_sum
                ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        if func_sum.func_name == "approve":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.approve(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "burn":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.burn(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "mint":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.mint(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "swapETH":
            s0 = self.m.make_symbolic_value()
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.swapETH(s0, caller=self.attacker, value=s1)
            return s0, s1
        elif func_sum.func_name == "swapToken":
            s0 = self.m.make_symbolic_value()
            self.main_ctrt.swapToken(s0, caller=self.attacker)
            return s0,
        elif func_sum.func_name == "transfer":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.transfer(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "transferFrom":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_address(*self._all_addresses)
            s2 = self.m.make_symbolic_value()
            self.main_ctrt.transferFrom(s0, s1, s2, caller=self.attacker)
            return s0, s1, s2
        elif func_sum.func_name == "transferOwnership":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            self.main_ctrt.transferOwnership(s0, caller=self.attacker)
            return s0,
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(self.main_ctrt, s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        self.main_ctrt.burn(self.main_ctrt, self.init_token_supply, caller=self.attacker)
        self.main_ctrt.swapToken(99 * ether, caller=self.attacker)
        print(next(self.m.all_sound_states))
        func_sums = [
            # ("TokenBurner", "burn"),
            # ("TokenBurner", "swapToken"),
        ]
        return [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                for addr_name, func_name in func_sums]
