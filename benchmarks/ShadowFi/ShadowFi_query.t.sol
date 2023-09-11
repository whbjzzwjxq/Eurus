// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ShadowFiTest is Test, BlockLoader {
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 sdf = IERC20(0x10bc28d2810dD462E16facfF18f78783e859351b);
    IUniswapV2Pair pair =
        IUniswapV2Pair(0xF9e3151e813cd6729D52d9A0C3ee69F22CcE650A);

    address attacker = 0x4daa3135B016Ac37C46ED03423D314CAeA89ff5e;

    function setUp() public {
        vm.createSelectFork("bsc", 20_969_095);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        queryERC20(address(sdf), "sdf", users, user_names);
        queryERC20(address(wbnb), "wbnb", users, user_names);
        emit log_string("----query ends----");
    }
}
