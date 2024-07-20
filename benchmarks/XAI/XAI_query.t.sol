// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 xai = IERC20(0x570Ce7b89c67200721406525e1848bca6fF5A6F3);
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    IUniswapV2Pair pair = IUniswapV2Pair(0xe633c651e6B3F744e7DeD314CDb243cf606A5F5B);

    address attacker = 0x446247bb10B77D1BCa4D4A396E014526D1ABA277;
    
    function setUp() public {
        vm.createSelectFork("bsc", 33_503_556);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](2);
        users[0] = address(pair);
        users[1] = attacker;
        string[] memory user_names = new string[](2);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        queryERC20(address(xai), "xai", users, user_names);
        queryERC20(address(wbnb), "wbnb", users, user_names);
        emit log_string("----query ends----");
    }
}
