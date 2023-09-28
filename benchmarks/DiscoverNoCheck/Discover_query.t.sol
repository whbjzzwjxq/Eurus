// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

/* 攻击者钱包：
0x446247bb10B77D1BCa4D4A396E014526D1ABA277

攻击者合约：
0x06b912354b167848a4a608a56bc26c680dad3d79

0xfa9c2157cf3d8cbfd54f6bef7388fbcd7dc90bd6

攻击交易：
0x8a33a1f8c7af372a9c81ede9e442114f0aabb537e5c3a22c0fd7231c4820f1e9

0x1dd4989052f69cd388f4dfbeb1690a3f3a323ebb73df816e5ef2466dc98fa4a4

ETHpledge合约：
0xe732a7bD6706CBD6834B300D7c56a8D2096723A7 */

contract ContractTest is Test, BlockLoader {
    IERC20 disc = IERC20(0x5908E4650bA07a9cf9ef9FD55854D4e1b700A267);
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);

    IUniswapV2Pair pair = IUniswapV2Pair(0x92f961B6bb19D35eedc1e174693aAbA85Ad2425d);

    address attacker = 0x446247bb10B77D1BCa4D4A396E014526D1ABA277;
    address ethpledge = 0xe732a7bD6706CBD6834B300D7c56a8D2096723A7;

    function setUp() public {
        vm.createSelectFork("bsc", 18_446_845);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](4);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = address(disc);
        users[3] = ethpledge;
        string[] memory user_names = new string[](4);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "disc";
        user_names[3] = "ethpledge";
        queryERC20(address(disc), "disc", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        emit log_string("----query ends----");
    }
}
