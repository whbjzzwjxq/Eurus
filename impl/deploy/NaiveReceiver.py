from os import path

from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer


class NaiveReceiver(ContractDeployer):

    attacker_init_balance = ContractDeployer.attacker_init_balance + 10 * ether
    receiver_init_balance = 100 * ether
    fee = 1 * ether

    def __init__(self) -> None:
        super().__init__("NaiveReceiver")

    def _deploy_hook(self):
        ctrt_pool_path = path.join(self.ctrt_dir, "LenderPool.sol")
        ctrt_receiver_path = path.join(self.ctrt_dir, "NaiveReceiver.sol")

        ctrt_pool_addr = self._compile(
            ctrt_pool_path, "LenderPool", (), balance=0)
        ctrt_receiver_addr = self._compile(ctrt_receiver_path, "NaiveReceiver",
                                           (ctrt_pool_addr,), balance=self.receiver_init_balance)

    def _check(self):
        ctrt_receiver_addr = self.ctrt_name2addr["NaiveReceiver"]
        ctrt_receiver_addr._check(self.attacker,
                                  self.attacker_init_balance + self.fee * 3, caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_sums = [
            ("LenderPool", "flashLoan"),
            ("NaiveReceiver", "receiveETH"),
        ]
        func_sums = [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                     for addr_name, func_name in func_sums]
        return [*func_sums,
                # self._transfer_func_sum
                ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        ctrt_pool_addr = self.ctrt_name2addr["LenderPool"]
        ctrt_receiver_addr = self.ctrt_name2addr["NaiveReceiver"]
        if func_sum.func_name == "flashLoan":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            ctrt_pool_addr.flashLoan(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "receiveETH":
            s0 = self.m.make_symbolic_value()
            ctrt_receiver_addr.receiveETH(caller=self.attacker, value=s0)
            return s0,
        if func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(self.ctrt_name2addr["NaiveReceiver"], s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        ctrt_receiver_addr = self.ctrt_name2addr["NaiveReceiver"]
        func_sums = ["receiveETH", "receiveETH", "receiveETH"]
        return [FunctionSummary("NaiveReceiver", f_n, ctrt_receiver_addr.get_signature(f_n)) for f_n in func_sums]
