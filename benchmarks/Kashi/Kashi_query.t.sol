// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract KashiTest is Test, BlockLoader {
    // Tokens
    IERC20 xsushi = IERC20(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 mim = IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Pairs
    IUniswapV2Pair pair_mim_weth = IUniswapV2Pair(0x07D5695a24904CC1B6e3bd57cC7780B90618e3c4);
    IUniswapV2Pair pair_xsushi_weth = IUniswapV2Pair(0x36e2FCCCc59e5747Ff63a03ea2e5C0c2C14911e7);

    // Users
    address bentobox = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966;
    address cauldron = 0xbb02A884621FB8F5BFd263A67F58B65df5b090f3;
    address attacker = 0xb7Ea0f0f8C6dF7a61Bf024DB21bbE85ac5688005;
    
    function setUp() public {
        vm.createSelectFork("mainnet", 15_928_289);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair_mim_weth), "pair_mim_weth");
        queryUniswapV2Pair(address(pair_xsushi_weth), "pair_xsushi_weth");

        address[] memory users = new address[](5);
        users[0] = bentobox;
        users[1] = cauldron;
        users[2] = attacker;
        users[3] = address(pair_mim_weth);
        users[4] = address(pair_xsushi_weth);

        string[] memory user_names = new string[](5);
        user_names[0] = "bentobox";
        user_names[1] = "cauldron";
        user_names[2] = "attacker";
        user_names[3] = "pair_mim_weth";
        user_names[4] = "pair_xsushi_weth";

        queryERC20(address(xsushi), "xsushi", users, user_names);
        queryERC20(address(mim), "mim", users, user_names);
        queryERC20(address(weth), "weth", users, user_names);
        emit log_string("----query ends----");
    }
}
