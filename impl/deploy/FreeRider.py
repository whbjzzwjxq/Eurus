from os import path
from typing import Any, Tuple

from impl.utils import (FunctionSummary, ether)

from ._deployer import ContractDeployer


class FreeRider(ContractDeployer):

    price_for_one = 15 * ether
    payout = 20 * ether
    token_id = 123

    attacker_init_balance = ContractDeployer.init_balance + price_for_one

    market_init_balance = 100 * ether
    buyer_init_balance = payout
    seller_init_balance = ContractDeployer.init_balance

    def __init__(self) -> None:
        super().__init__("FreeRider")

    def _deploy_hook(self):
        ctrt_market_path = path.join(
            self.ctrt_dir, "FreeRiderNFTMarketplace.sol")
        ctrt_buyer_path = path.join(self.ctrt_dir, "FreeRiderBuyer.sol")
        ctrt_seller_path = path.join(self.ctrt_dir, "FreeRiderSeller.sol")

        ctrt_erc721_addr = self._compile(
            ctrt_market_path, "ERC721Basic", (), balance=0)

        ctrt_market_addr = self._compile(ctrt_market_path, "FreeRiderNFTMarketplace",
                                         args=(ctrt_erc721_addr,), balance=self.market_init_balance)

        ctrt_buyer_addr = self._compile(ctrt_buyer_path, "FreeRiderBuyer",
                                        args=(ctrt_erc721_addr, self.payout), balance=self.buyer_init_balance)

        ctrt_seller_addr = self._compile(ctrt_seller_path, "FreeRiderSeller",
                                         args=(ctrt_erc721_addr, ctrt_market_addr, self.price_for_one), balance=self.seller_init_balance)

        ctrt_erc721_addr.mint(
            ctrt_seller_addr, self.token_id, caller=self.owner)
        ctrt_erc721_addr.setApprovalForAll(
            ctrt_market_addr, True, caller=ctrt_seller_addr)
        ctrt_market_addr.offerOne(
            self.token_id, self.price_for_one, caller=ctrt_seller_addr)

    def _check(self):
        ctrt_market_addr = self.ctrt_name2addr["FreeRiderNFTMarketplace"]
        ctrt_market_addr._check(
            self.attacker, self.payout + self.price_for_one, caller=self.attacker)

    def _gen_functiom_summaries(self):
        func_sums = (
            ("ERC721Basic", "approve"),
            ("ERC721Basic", "mint"),
            ("ERC721Basic", "setApprovalForAll"),
            ("ERC721Basic", "transferFrom"),
            ("FreeRiderBuyer", "buy"),
            ("FreeRiderNFTMarketplace", "buyOne"),
            ("FreeRiderNFTMarketplace", "offerOne"),
            ("FreeRiderSeller", "removeReceiver"),
            ("FreeRiderSeller", "setReceiver"),
        )
        func_sums = [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                     for addr_name, func_name in func_sums]
        return [*func_sums,
                # self._transfer_func_sum
                ]

    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        ctrt_erc721_addr = self.ctrt_name2addr["ERC721Basic"]
        ctrt_market_addr = self.ctrt_name2addr["FreeRiderNFTMarketplace"]
        ctrt_seller_addr = self.ctrt_name2addr["FreeRiderSeller"]
        ctrt_buyer_addr = self.ctrt_name2addr["FreeRiderBuyer"]
        if func_sum.func_name == "approve":
            # Hacking
            # We assume we have known the token idx.
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.token_id
            ctrt_erc721_addr.approve(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "mint":
            # Hacking
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.token_id
            ctrt_erc721_addr.mint(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "setApprovalForAll":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            # Hacking
            # We assume there is no bug in the implementation of the ERC721 token.
            # So we just approve true.
            s1 = True
            ctrt_erc721_addr.setApprovalForAll(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "transferFrom":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            s1 = self.m.make_symbolic_address(*self._all_addresses)
            s2 = self.m.make_symbolic_value()
            ctrt_erc721_addr.transferFrom(s0, s1, s2, caller=self.attacker)
            return s0, s1, s2
        elif func_sum.func_name == "buy":
            ctrt_buyer_addr.buy(caller=self.attacker)
            return None
        elif func_sum.func_name == "buyOne":
            # Hacking
            s0 = self.token_id
            s1 = self.m.make_symbolic_value()
            ctrt_market_addr.buyOne(
                s0, caller=self.attacker, value=s1)
            return s0, s1
        elif func_sum.func_name == "offerOne":
            # Hacking
            s0 = self.token_id
            s1 = self.m.make_symbolic_value()
            ctrt_market_addr.offerOne(s0, s1, caller=self.attacker)
            return s0, s1
        elif func_sum.func_name == "removeReceiver":
            ctrt_seller_addr.removeReceiver(caller=self.attacker)
            return None
        elif func_sum.func_name == "setReceiver":
            s0 = self.m.make_symbolic_address(*self._all_addresses)
            ctrt_seller_addr.setReceiver(s0, caller=self.attacker)
            return s0,
        elif func_sum == self._transfer_func_sum:
            s0 = self.m.make_symbolic_value()
            addr = self.ctrt_name2addr["FreeRiderNFTMarketplace"]
            self._transfer(addr, s0)
            return str(addr), s0
        raise ValueError(f"Unknown function summary: {func_sum}")

    @property
    def _ground_truth_sketch(self):
        func_sums = (
            ("ERC721Basic", "setApprovalForAll"),
            ("FreeRiderSeller", "removeReceiver"),
            ("FreeRiderNFTMarketplace", "buyOne"),
            ("FreeRiderBuyer", "buy"),
        )
        return [FunctionSummary(addr_name, func_name, self.ctrt_name2addr[addr_name].get_signature(func_name))
                for addr_name, func_name in func_sums]
