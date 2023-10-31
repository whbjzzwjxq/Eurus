// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 resA = IERC20(0xecCD8B08Ac3B587B7175D40Fb9C60a20990F8D21);
    IERC20 resB = IERC20(0x04C0f31C0f59496cf195d2d7F1dA908152722DE7);

    // usdt-resA
    IUniswapV2Pair pair =
        IUniswapV2Pair(0x05ba2c512788bd95cd6D61D3109c53a14b01c82A);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 21_948_016);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](4);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = address(resA);
        users[3] = address(resB);
        string[] memory user_names = new string[](4);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "resA";
        user_names[3] = "resB";
        queryERC20(address(usdt), "usdt", users, user_names);
        queryERC20(address(resA), "resA", users, user_names);
        queryERC20(address(resB), "resB", users, user_names);
        emit log_string("----query ends----");
    }
}
