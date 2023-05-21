from os import path

from typing import Tuple, Any

from impl.utils import (SolFunction, ether, gwei)

from ._deployer import ContractDeployer


class PuppetPool(ContractDeployer):

    attacker_init_balance = ContractDeployer.init_balance + 2 * ether
    swaper_init_balance = 10 * ether + 10 * gwei

    attacker_init_token = 1000
    swaper_init_token = 10
    lender_pool_init_token = 100 * attacker_init_token

    def __init__(self) -> None:
        super().__init__("PuppetPool")

    def _deploy_hook(self):
        ctrt_uniswap_path = path.join(self.ctrt_dir, "UniswapV1.sol")
        ctrt_puppetpool_path = path.join(self.ctrt_dir, "PuppetPool.sol")

        ctrt_erc20_addr = self._compile(ctrt_uniswap_path, "ERC20Basic",
                                        (self.init_token_supply, ), balance=0)

        ctrt_uniswap_addr = self._compile(ctrt_uniswap_path, "UniswapV1",
                                          (ctrt_erc20_addr,), balance=self.swaper_init_balance)

        ctrt_puppetpool_addr = self._compile(ctrt_puppetpool_path, "PuppetPool",
                                             (ctrt_erc20_addr, ctrt_uniswap_addr), balance=ContractDeployer.init_balance)

        ctrt_erc20_addr.transfer(
            self.attacker, self.attacker_init_token, caller=self.owner)
        ctrt_erc20_addr.transfer(
            ctrt_uniswap_addr, self.swaper_init_token, caller=self.owner)
        ctrt_erc20_addr.transfer(
            ctrt_puppetpool_addr, self.lender_pool_init_token, caller=self.owner)

        # Initial approve
        ctrt_erc20_addr.approve(self.attacker, 0, caller=ctrt_uniswap_addr)
        ctrt_erc20_addr.approve(self.attacker, 0, caller=ctrt_puppetpool_addr)

        # Hacking
        # We assume we have known we should transfer to uniswap
        ctrt_erc20_addr.approve(ctrt_uniswap_addr, self.attacker_init_token, caller=self.attacker)

    def _check(self):
        ctrt_puppetpool_addr = self.name2ctrt_addr["PuppetPool"]
        ctrt_puppetpool_addr._check(
            self.attacker, self.lender_pool_init_token, caller=self.attacker)

    def _gen_function_instances(self):
        func_sums = [
            ("ERC20Basic", "approve"),
            ("ERC20Basic", "transfer"),
            ("ERC20Basic", "transferFrom"),
            ("PuppetPool", "borrow"),
            ("UniswapV1", "swapETH"),
            ("UniswapV1", "swapToken"),
        ]
        func_sums = [SolFunction(addr_name, func_name, self.name2ctrt_addr[addr_name].get_signature(func_name))
                     for addr_name, func_name in func_sums]
        return [*func_sums,
                # self._transfer_func_sum
                ]

    def _exec_hook(self, func_sum: SolFunction) -> Tuple[Any]:
        ctrt_erc20_addr = self.name2ctrt_addr["ERC20Basic"]
        ctrt_puppetpool_addr = self.name2ctrt_addr["PuppetPool"]
        ctrt_uniswap_addr = self.name2ctrt_addr["UniswapV1"]
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
        elif func_sum.func_name == "borrow":
            s0 = self.m.make_symbolic_value()
            s1 = self.m.make_symbolic_value()
            ctrt_puppetpool_addr.borrow(s0, caller=self.attacker, value=s1)
            return s0, s1
        elif func_sum.func_name == "swapETH":
            s0 = self.m.make_symbolic_value()
            s1 = self.m.make_symbolic_value()
            ctrt_uniswap_addr.swapETH(s0, caller=self.attacker, value=s1)
            return s0, s1
        elif func_sum.func_name == "swapToken":
            s0 = self.m.make_symbolic_value()
            s1 = self.m.make_symbolic_value()
            ctrt_uniswap_addr.swapToken(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            self._transfer(self.name2ctrt_addr["PuppetPool"], s0)
            return s0,
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        func_sums = [
            ("UniswapV1", "swapToken"),
            ("PuppetPool", "borrow"),
        ]
        return [SolFunction(addr_name, func_name, self.name2ctrt_addr[addr_name].get_signature(func_name))
                for addr_name, func_name in func_sums]
