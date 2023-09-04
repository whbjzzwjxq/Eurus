// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {USDT} from "@utils/USDT.sol";

import {DxBurnToken} from "benchmarks/realworld/BIGFI/DxBurnToken.sol";

import "@utils/QueryBlockchain.sol";

contract BIGFITest is Test, BlockLoader {
    DxBurnToken bigfi = DxBurnToken(payable(0xd3d4B46Db01C006Fb165879f343fc13174a1cEeB));
    USDT usdt = USDT(0x55d398326f99059fF775485246999027B3197955);
    // USDT to BIGFI
    IUniswapV2Pair pair =
        IUniswapV2Pair(0xA269556EdC45581F355742e46D2d722c5F3f551a);
    address attacker = 0x76a88c2bAeBf251701435ABBe8af11ad52b0ab04;

    function setUp() public {
        vm.createSelectFork("bsc", 26685503);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryUniswapV2Pair(address(pair), "pair");

        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;

        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";

        queryERC20(address(bigfi), "bigfi", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        emit log_string("----query ends----");
    }
}
