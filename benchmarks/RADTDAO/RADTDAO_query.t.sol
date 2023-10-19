// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract RADTDAOTest is Test, BlockLoader {
    // Token
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 radt = IERC20(0xDC8Cb92AA6FC7277E3EC32e3f00ad7b8437AE883);

    // Pair
    IUniswapV2Pair pair =
        IUniswapV2Pair(0xaF8fb60f310DCd8E488e4fa10C48907B7abf115e);

    // Users
    address wrapper = address(0x01112eA0679110cbc0ddeA567b51ec36825aeF9b);
    address attacker = address(0xabcd);

    function setUp() public {
        vm.createSelectFork("bsc", 21_572_418);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = wrapper;
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "wrapper";

        queryERC20(address(usdt), "usdt", users, user_names);
        queryERC20(address(radt), "radt", users, user_names);
        emit log_string("----query ends----");
    }
}
