// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 neverFall = IERC20(0x5ABDe8B434133C98c36F4B21476791D95D888bF5);
    
    // wbnb-bamboo
    IUniswapV2Pair pair = IUniswapV2Pair(0x97a08A9Fb303b4f6F26C5B3C3002EBd0E6417d2c);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 27_863_178 - 1);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = address(neverFall);
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "neverFall";
        queryERC20(address(usdt), "usdt", users, user_names);
        queryERC20(address(neverFall), "neverFall", users, user_names);
        queryERC20(address(pair), "pair", users, user_names);
        emit log_string("----query ends----");
    }
}
