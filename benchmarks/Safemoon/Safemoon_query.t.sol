// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 safemoon = IERC20(0x42981d0bfbAf196529376EE702F2a9Eb9092fcB5);
    IERC20 weth = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    
    // wbnb-safemoon
    IUniswapV2Pair sfpairimpl = IUniswapV2Pair(0x35e072E93B2e4316e3bb0ef4cDA4Eb206188afEb);
    // IUniswapV2Pair sfswappair = IUniswapV2Pair(0x8e0301E3bDE2397449FeF72703E71284d0d149F1);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/bsc", 26854757);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(sfpairimpl), "sfpairimpl");
        // queryUniswapV2Pair(address(sfswappair), "sfswappair");
        
        
        address[] memory users = new address[](2);
        users[0] = address(sfpairimpl);
        // users[1] = address(sfswappair);
        users[1] = attacker;
        string[] memory user_names = new string[](2);
        user_names[0] = "sfpairimpl";
        // user_names[1] = "sfswappair";
        user_names[1] = "attacker";
        queryERC20(address(safemoon), "safemoon", users, user_names);
        queryERC20(address(weth), "weth", users, user_names);
        emit log_string("----query ends----");
    }
}
