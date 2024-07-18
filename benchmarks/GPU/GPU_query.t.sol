// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    // IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 gpu = IERC20(0xf51CBf9F8E089Ca48e454EB79731037a405972ce);
    
    // busd-wbnb
    // IUniswapV2Pair busdWbnbPair = IUniswapV2Pair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
    // busd-gpu
    // IUniswapV2Pair busdGpuPair = IUniswapV2Pair(0x61373083F4dEef88ba449AD82218059781962D76);
    IUniswapV2Pair pair = IUniswapV2Pair(0x61373083F4dEef88ba449AD82218059781962D76);
    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 38_539_572);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        // queryUniswapV2Pair(address(busdWbnbPair), "busdWbnbPair");
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](2);
        // users[0] = address(busdWbnbPair);
        users[0] = address(pair);
        users[1] = attacker;
        string[] memory user_names = new string[](2);
        // user_names[0] = "busdWbnbPair";
        user_names[0] = "pair";
        user_names[1] = "attacker";
        queryERC20(address(busd), "busd", users, user_names);
        queryERC20(address(gpu), "gpu", users, user_names);
        emit log_string("----query ends----");
    }
}
