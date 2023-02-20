from os import path

from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer


class Rewarder(ContractDeployer):

    attacker_init_balance = ContractDeployer.attacker_init_balance + 10 * ether
    rewarder_init_balance = 100 * ether
    rewarder_init_token = 100 * ether

    def __init__(self) -> None:
        super().__init__("Rewarder")

    def _deploy_hook(self):
        ctrt_rewarder_path = path.join(self.ctrt_dir, "Rewarder.sol")

        ctrt_erc20_addr = self._compile(ctrt_rewarder_path, "ERC20Basic",
                                        (self.init_token_supply,), balance=0)

        self.main_ctrt = self._compile(ctrt_rewarder_path, "Rewarder",
                                       (ctrt_erc20_addr,), balance=self.rewarder_init_balance)

        ctrt_erc20_addr.transfer(
            self.main_ctrt, self.rewarder_init_token, caller=self.owner)

        # Initial approve
        ctrt_erc20_addr.approve(
            self.attacker, 0, caller=self.main_ctrt
        )

    def _check(self):
        self.main_ctrt._check(
            self.attacker, self.rewarder_init_token, caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_sums = [
            ("ERC20Basic", "approve"),
            ("ERC20Basic", "transfer"),
            ("ERC20Basic", "transferFrom"),
            ("Rewarder", "swapToken"),
            ("Rewarder", "swapETH"),
            ("Rewarder", "depositToken"),
            ("Rewarder", "depositETH"),
            ("Rewarder", "withdraw"),
            ("Rewarder", "initialReward"),
            ("Rewarder", "claimReward"),
        ]
        func_sums = [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                     for addr_name, func_name in func_sums]
        return [*func_sums,
                # self._transfer_func_sum
                ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        ctrt_erc20_addr = self.ctrt_name2addr["ERC20Basic"]
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
        elif func_sum.func_name == "swapToken":
            s0 = self.m.make_symbolic_value()
            s1 = self.m.make_symbolic_value()
            self.main_ctrt.swapToken(s0, value=s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "depositETH":
            s0 = self.m.make_symbolic_value()
            self.main_ctrt.depositETH(value=s0, caller=self.attacker)
            return s0,
        elif func_sum.ctrt_name == "Rewarder":
            return self.main_ctrt.exec_func_totally_symbolical(func_sum.name,
                                                               caller=self.attacker)
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(self.main_ctrt, s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        func_sums = [
            ("Rewarder", "depositETH"),
            ("Rewarder", "claimReward"),
            ("Rewarder", "withdraw"),
        ]
        return [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                for addr_name, func_name in func_sums]
