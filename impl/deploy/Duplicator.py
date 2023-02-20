from os import path
from typing import Tuple, Any

from impl.utils import (FunctionSummary, ether, gwei)

from ._deployer import ContractDeployer


class Duplicator(ContractDeployer):

    init_token_supply = 1000 * ether

    attacker_init_bnb_token = 10 * ether

    pool_init_bnb_token = 100 * ether
    pool_init_dpc_token = 900 * ether

    hack_dpc_token = 220 * ether

    def __init__(self) -> None:
        super().__init__("Duplicator")

    def _deploy_hook(self):
        ctrt_dupl_path = path.join(self.ctrt_dir, "Duplicator.sol")

        ctrt_bnb_addr = self._compile(
            ctrt_dupl_path, "ERC20Basic", (self.init_token_supply, ), balance=0, name="BNB")
        ctrt_dpc_addr = self._compile(
            ctrt_dupl_path, "ERC20Basic", (self.init_token_supply, ), balance=0, name="DPC")

        self.main_ctrt = self._compile(
            ctrt_dupl_path, "Duplicator", (ctrt_bnb_addr, ctrt_dpc_addr), balance=self.init_balance)

        ctrt_bnb_addr.transfer(
            self.attacker, self.attacker_init_bnb_token, caller=self.owner)
        ctrt_bnb_addr.transfer(
            self.main_ctrt, self.pool_init_bnb_token, caller=self.owner)
        ctrt_dpc_addr.transfer(
            self.main_ctrt, self.pool_init_dpc_token, caller=self.owner)

        # Initial approve
        ctrt_bnb_addr.approve(self.attacker, 0, caller=self.main_ctrt)
        ctrt_dpc_addr.approve(self.attacker, 0, caller=self.main_ctrt)

        # Hacking
        ctrt_bnb_addr.approve(self.main_ctrt, 10 * ether, caller=self.attacker)


    def _check(self):
        self.main_ctrt._check(
            self.attacker, self.hack_dpc_token, caller=self.attacker)
        pass

    def _gen_functiom_summaries(self):
        func_sums = [
            ("BNB", "approve"),
            ("BNB", "transfer"),
            ("BNB", "transferFrom"),
            ("DPC", "approve"),
            ("DPC", "transfer"),
            ("DPC", "transferFrom"),
            ("Duplicator", "addLiquidity"),
            ("Duplicator", "swapBNB"),
            ("Duplicator", "claimStakeLp"),
            ("Duplicator", "withdrawReward"),
        ]
        func_sums = [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                     for addr_name, func_name in func_sums]
        return [*func_sums,
                # self._transfer_func_sum
                ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        ctrt_bnb_addr = self.ctrt_name2addr["BNB"]
        ctrt_dpc_addr = self.ctrt_name2addr["DPC"]
        if func_sum.ctrt_name == "BNB":
            if func_sum.func_name == "approve":
                s0 = self.m.make_symbolic_address(*self._all_addresses)
                s1 = self.m.make_symbolic_value()
                ctrt_bnb_addr.approve(s0, s1, caller=self.attacker)
                return s0, s1
            elif func_sum.func_name == "transfer":
                s0 = self.m.make_symbolic_address(*self._all_addresses)
                s1 = self.m.make_symbolic_value()
                ctrt_bnb_addr.transfer(s0, s1, caller=self.attacker)
                return s0, s1
            elif func_sum.func_name == "transferFrom":
                s0 = self.m.make_symbolic_address(*self._all_addresses)
                s1 = self.m.make_symbolic_address(*self._all_addresses)
                s2 = self.m.make_symbolic_value()
                ctrt_bnb_addr.transferFrom(s0, s1, s2, caller=self.attacker)
                return s0, s1, s2
        elif func_sum.ctrt_name == "DPC":
            if func_sum.func_name == "approve":
                s0 = self.m.make_symbolic_address(*self._all_addresses)
                s1 = self.m.make_symbolic_value()
                ctrt_dpc_addr.approve(s0, s1, caller=self.attacker)
                return s0, s1
            elif func_sum.func_name == "transfer":
                s0 = self.m.make_symbolic_address(*self._all_addresses)
                s1 = self.m.make_symbolic_value()
                ctrt_dpc_addr.transfer(s0, s1, caller=self.attacker)
                return s0, s1
            elif func_sum.func_name == "transferFrom":
                s0 = self.m.make_symbolic_address(*self._all_addresses)
                s1 = self.m.make_symbolic_address(*self._all_addresses)
                s2 = self.m.make_symbolic_value()
                ctrt_dpc_addr.transferFrom(s0, s1, s2, caller=self.attacker)
                return s0, s1, s2
        elif func_sum.ctrt_name == "Duplicator":
            return self.main_ctrt.exec_func_totally_symbolical(func_sum.func_name, caller=self.attacker)
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(self.main_ctrt, s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        func_sums = [
            # ("BNB", "approve"),
            ("Duplicator", "addLiquidity"),
            ("Duplicator", "claimStakeLp"),
            ("Duplicator", "claimStakeLp"),
            ("Duplicator", "claimStakeLp"),
            ("Duplicator", "withdrawReward"),
        ]
        return [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                for addr_name, func_name in func_sums]
