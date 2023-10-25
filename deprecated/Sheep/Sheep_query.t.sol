// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// @Analysis
// https://twitter.com/BlockSecTeam/status/1623999717482045440
// https://twitter.com/BlockSecTeam/status/1624077078852210691
// @TX
// https://bscscan.com/tx/0x61293c6dd5211a98f1a26c9f6821146e12fb5e20c850ad3ed2528195c8d4c98e
// Related Events
// https://github.com/SunWeb3Sec/DeFiHackLabs/#20230207---fdp---reflection-token
// https://github.com/SunWeb3Sec/DeFiHackLabs/#20230126---tinu---reflection-token

contract ContractTest is Test, BlockLoader {
    IERC20 sheep = IERC20(0x0025B42bfc22CbbA6c02d23d4Ec2aBFcf6E014d4);
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IUniswapV2Pair pair = IUniswapV2Pair(0x912DCfBf1105504fB4FF8ce351BEb4d929cE9c24);
    address attacker = 0x638B4779D1923CEDF726Ed4D717ee4169Df53d4e;

    function setUp() public {
        vm.createSelectFork("bsc", 25_543_755);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        queryERC20(address(sheep), "sheep", users, user_names);
        queryERC20(address(wbnb), "wbnb", users, user_names);
        emit log_string("----query ends----");
    }

}