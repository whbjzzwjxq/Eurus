from os import path

from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer


class Whosyourowner(ContractDeployer):

    init_token_supply = 1000 * ether
    attacker_required_token = 100 * ether

    def __init__(self) -> None:
        super().__init__("Whosyourowner")

    def _deploy_hook(self):
        ctrt_pool_path = path.join(self.ctrt_dir, "Whosyourowner.sol")

        self.main_ctrt = self._compile(ctrt_pool_path, "Whosyourowner",
                                       (self.init_token_supply,), balance=self.init_balance)

    def _check(self):
        self.main_ctrt._check(self.attacker, self.attacker_required_token, caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_sums = [
            ("Whosyourowner", "approve"),
            ("Whosyourowner", "mint"),
            ("Whosyourowner", "transfer"),
            ("Whosyourowner", "transferFrom"),
            ("Whosyourowner", "transferOwnership"),
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
        elif func_sum.func_name == "mint":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.mint(s0, s1, caller=self.attacker)
            return s0, s1
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
        # FIXME Idk why approve => mint also works.
        func_sums = [
            ("Whosyourowner", "transferOwnership"),
            ("Whosyourowner", "mint"),
        ]
        return [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                for addr_name, func_name in func_sums]
