// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 lw = IERC20(0x7B8C378df8650373d82CeB1085a18FE34031784F);
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    
    // usdt-lw
    IUniswapV2Pair pair = IUniswapV2Pair(0x6D2D124acFe01c2D2aDb438E37561a0269C6eaBB);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);
    address market = address(0xae2f168900D5bb38171B01c2323069E5FD6b57B9);

    function setUp() public {
        vm.createSelectFork("bsc", 28_133_285);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = market;
        users[2] = attacker;
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "market";
        user_names[2] = "attacker";
        queryERC20(address(lw), "lw", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        emit log_string("----query ends----");
    }
}
