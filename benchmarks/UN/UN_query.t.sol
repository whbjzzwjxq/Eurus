// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 un = IERC20(0x1aFA48B74bA7aC0C3C5A2c8B7E24eB71D440846F);
    
    // busd-un
    IUniswapV2Pair pair = IUniswapV2Pair(0x5F739a4AdE4341D4AEe049E679095BcCbe904Ee1);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 28_864_173);
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
        queryERC20(address(busd), "busd", users, user_names);
        queryERC20(address(un), "un", users, user_names);
        emit log_string("----query ends----");
    }
}
