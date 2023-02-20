from os import path

from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer


class Unstoppable(ContractDeployer):

    attacker_init_token = 10000

    def __init__(self) -> None:
        super().__init__("Unstoppable")

    def _deploy_hook(self):
        ctrt_pool_path = path.join(self.ctrt_dir, "LenderPool.sol")
        ctrt_receiver_path = path.join(self.ctrt_dir, "Receiver.sol")

        ctrt_erc20_addr = self._compile(ctrt_pool_path, "ERC20Basic",
                                        (self.init_token_supply,), balance=0)

        ctrt_pool_addr = self._compile(ctrt_pool_path, "LenderPool",
                                       (ctrt_erc20_addr,), balance=0)

        ctrt_receiver_addr = self._compile(ctrt_receiver_path, "Receiver",
                                           (ctrt_pool_addr, ctrt_erc20_addr), balance=0)

        ctrt_erc20_addr.transfer(
            self.attacker, self.attacker_init_token, caller=self.owner)

        # This approve could be solved.

    def _check(self):
        ctrt_pool_addr = self.ctrt_name2addr["LenderPool"]
        ctrt_pool_addr._check(caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_sums = [
            ("ERC20Basic", "approve"),
            ("ERC20Basic", "transfer"),
            ("ERC20Basic", "transferFrom"),
            ("LenderPool", "depositTokens"),
            ("LenderPool", "flashLoan"),
            ("Receiver", "receiveTokens"),
        ]
        func_sums = [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                     for addr_name, func_name in func_sums]
        return [*func_sums,
                # self._transfer_func_sum
                ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        ctrt_erc20_addr = self.ctrt_name2addr["ERC20Basic"]
        ctrt_pool_addr = self.ctrt_name2addr["LenderPool"]
        ctrt_receiver_addr = self.ctrt_name2addr["Receiver"]
        if func_sum.func_name == "approve":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            ctrt_erc20_addr.approve(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "transfer":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            ctrt_erc20_addr.transfer(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "transferFrom":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_address(*self._all_addresses)
            s2 = self.m.make_symbolic_value()
            ctrt_erc20_addr.transferFrom(s0, s1, s2, caller=self.attacker)
            return s0, s1, s2
        elif func_sum.func_name == "depositTokens":
            s0 = self.m.make_symbolic_value()
            ctrt_pool_addr.depositTokens(s0, caller=self.attacker)
            return s0,
        elif func_sum.func_name == "flashLoan":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_value()
            ctrt_pool_addr.flashLoan(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "receiveTokens":
            s0 = self.m.make_symbolic_value()
            ctrt_receiver_addr.receiveTokens(s0, )
            return s0,
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(ctrt_pool_addr, s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        func_sums = [
            ("ERC20Basic", "approve"),
            ("ERC20Basic", "transfer"),
            ("LenderPool", "depositTokens"),
        ]
        return [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                for addr_name, func_name in func_sums]
