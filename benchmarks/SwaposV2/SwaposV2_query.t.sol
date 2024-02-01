// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 swapos = IERC20(0x09176F68003c06F190ECdF40890E3324a9589557);

    IUniswapV2Pair pair = IUniswapV2Pair(0x8ce2F9286F50FbE2464BFd881FAb8eFFc8Dc584f);

    address attacker = 0x446247bb10B77D1BCa4D4A396E014526D1ABA277;
    address spair = 0x8ce2F9286F50FbE2464BFd881FAb8eFFc8Dc584f;

    function setUp() public {
        vm.createSelectFork("mainnet", 17_057_419);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](4);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = spair;
        string[] memory user_names = new string[](4);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "spair";
        queryERC20(address(weth), "weth", users, user_names);
        queryERC20(address(swapos), "swapos", users, user_names);
        emit log_string("----query ends----");
    }
}
