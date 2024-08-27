// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 sellc = IERC20(0xa645995e9801F2ca6e2361eDF4c2A138362BADe4);
    
    // sellc-wbnb
    IUniswapV2Pair pair = IUniswapV2Pair(0x358EfC593134f99833C66894cCeCD41F550051b6);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 28_168_034);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](2);
        users[0] = address(pair);
        users[1] = attacker;
        string[] memory user_names = new string[](2);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        queryERC20(address(sellc), "sellc", users, user_names);
        queryERC20(address(wbnb), "wbnb", users, user_names);
        emit log_string("----query ends----");
    }
}
