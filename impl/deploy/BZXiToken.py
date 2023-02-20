from os import path
from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer

class BZXiToken(ContractDeployer):

    bzxi_init_balance = 10 * ether

    def __init__(self) -> None:
        super().__init__("BZXiToken")

    def _deploy_hook(self):
        ctrt_bzxi_path = path.join(self.ctrt_dir, "BZXiToken.sol")

        self.main_ctrt = self._compile(ctrt_bzxi_path, "BZXiToken", (), balance=0)

        self.main_ctrt.transfer(self.attacker, self.bzxi_init_balance, caller=self.owner)

        # Initial approve
        self.main_ctrt.approve(self.attacker, 0, caller=self.attacker)

        # This approve could be solved.
    def _check(self):
        hack_amount = 1 * ether
        self.main_ctrt._check(self.attacker, self.bzxi_init_balance + hack_amount, caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_names = ["approve", "transfer", "transferFrom"]
        func_sums = [FunctionSummary("BZXiToken", f_n, self.main_ctrt.get_signature(f_n)) for f_n in func_names]
        return [*func_sums,
            # self._transfer_func_sum
        ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        if func_sum.func_name == "approve":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.approve(s0, s1, caller=self.attacker)
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
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(self.main_ctrt, s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        func_sums = ["approve", "transferFrom"]
        return [FunctionSummary("BZXiToken", f_n, self.main_ctrt.get_signature(f_n)) for f_n in func_sums]
