// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 bgld = IERC20(0xC2319E87280c64e2557a51Cb324713Dd8d1410a3);

    // USDT to BIGFI
    IUniswapV2Pair pair = IUniswapV2Pair(0x7526cC9121Ba716CeC288AF155D110587e55Df8b);
    address attacker = 0xF4FD2EbE7196c8E99E88bcc4Aef69dda0e493B8F;
    
    function setUp() public {
        vm.createSelectFork("bsc", 23844529);
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
        queryERC20(address(wbnb), "wbnb", users, user_names);
        queryERC20(address(bgld), "bgld", users, user_names);
        emit log_string("----query ends----");
    }
}
