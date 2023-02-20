from os import path
from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer

class Killme(ContractDeployer):

    killme_init_balance = 10 * ether

    def __init__(self) -> None:
        super().__init__("Killme")

    def _deploy_hook(self):
        ctrt_killme_path = path.join(self.ctrt_dir, "Killme.sol")

        self.main_ctrt = self._compile(ctrt_killme_path, "Killme", (), balance=self.killme_init_balance)

    def _check(self):
        self.main_ctrt._check(self.attacker, self.killme_init_balance, caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_names = ["activateBackdoor", "kill", "pwnContract", "updateToken"]
        func_sums = [FunctionSummary("Killme", f_n, self.main_ctrt.get_signature(f_n)) for f_n in func_names]
        return [*func_sums,
            # self._transfer_func_sum
        ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        if func_sum.func_name == "activateBackdoor":
            s0 = self.m.make_symbolic_value()
            self.main_ctrt.activateBackdoor(s0, caller=self.attacker)
            return s0,
        elif func_sum.func_name == "kill":
            self.main_ctrt.kill(caller=self.attacker)
            return None
        elif func_sum.func_name == "pwnContract":
            self.main_ctrt.pwnContract(caller=self.attacker)
            return None
        elif func_sum.func_name == "updateToken":
            s0 = self.m.make_symbolic_value()
            self.main_ctrt.updateToken(s0, caller=self.attacker)
            return s0,
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(self.main_ctrt, s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        func_sums = ["activateBackdoor", "pwnContract", "updateToken", "kill"]
        return [FunctionSummary("Killme", f_n, self.main_ctrt.get_signature(f_n)) for f_n in func_sums]
