// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 haven = IERC20(0x9caE753B661142aE766374CEFA5dC800d80446aC);
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);

    // HAVEN - WBNB
    IUniswapV2Pair pairhw =
        IUniswapV2Pair(0x63373252f5090B3CEE061348D627A17cf6Ab360F);

    // BUSD - HAVEN
    IUniswapV2Pair pairbh =
        IUniswapV2Pair(0x25e02ab0c95e07F7614F4de793004A0E3Eb2C2B3);

    // BUSD - WBNB
    IUniswapV2Pair pairbw =
        IUniswapV2Pair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
        
    address attacker = address(0xbadbbb);

    function setUp() public {
        vm.createSelectFork("bsc", 33_537_922);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pairhw), "pairhw");
        queryUniswapV2Pair(address(pairbh), "pairbh");
        queryUniswapV2Pair(address(pairbw), "pairbw");

        address[] memory users = new address[](5);
        users[0] = address(pairhw);
        users[1] = attacker;
        users[2] = address(haven);
        users[3] = address(pairbw);
        users[4] = address(pairbh);
        
        string[] memory user_names = new string[](5);
        user_names[0] = "pairhw";
        user_names[1] = "attacker";
        user_names[2] = "haven";
        user_names[3] = "pairbw";
        user_names[4] = "pairbh";

        queryERC20(address(haven), "haven", users, user_names);
        queryERC20(address(wbnb), "wbnb", users, user_names);
        queryERC20(address(busd), "busd", users, user_names);
        emit log_string("----query ends----");
    }
}
