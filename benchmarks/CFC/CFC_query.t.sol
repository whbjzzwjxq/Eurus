// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 safe = IERC20(0x4d7Fa587Ec8e50bd0E9cD837cb4DA796f47218a1);
    IERC20 cfc = IERC20(0xdd9B223AEC6ea56567A62f21Ff89585ff125632c);
    
    // SAFE - BEP20USDT
    IUniswapV2Pair safeusdtPair = IUniswapV2Pair(0x400DB103Af7a0403C9Ab014b2B73702B89F6B4b7);
    // SAFE - CFC
    IUniswapV2Pair pair = IUniswapV2Pair(0x595488F902C4d9Ec7236031a1D96cf63b0405CF0);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 29_116_478);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(safeusdtPair), "safeusdtPair");
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(safeusdtPair);
        users[1] = address(pair);
        users[2] = attacker;
        string[] memory user_names = new string[](3);
        user_names[0] = "safeusdtPair";
        user_names[1] = "pair";
        user_names[2] = "attacker";
        queryERC20(address(safe), "safe", users, user_names);
        queryERC20(address(cfc), "cfc", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        
        emit log_string("----query ends----");
    }
}
