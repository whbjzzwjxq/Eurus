// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 hct = IERC20(0x0FDfcfc398Ccc90124a0a41d920d6e2d0bD8CcF5);
    
    // hct-wbnb
    IUniswapV2Pair pair = IUniswapV2Pair(0xdbE783014Cb0662c629439FBBBa47e84f1B6F2eD);
    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 31_528_198 - 1);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](2);
        users[0] = address(pair);
        users[1] = address(attacker);
        string[] memory user_names = new string[](2);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        queryERC20(address(wbnb), "wbnb", users, user_names);
        queryERC20(address(hct), "hct", users, user_names);
        emit log_string("----query ends----");
    }
}
