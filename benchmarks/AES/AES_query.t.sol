// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// @Analysis
// https://twitter.com/BlockSecTeam/status/1600442137811689473
// https://twitter.com/peckshield/status/1600418002163625984
// @TX
// https://bscscan.com/tx/0xca4d0d24aa448329b7d4eb81be653224a59e7b081fc7a1c9aad59c5a38d0ae19

contract ContractTest is Test, BlockLoader {
    IERC20 aes = IERC20(0xdDc0CFF76bcC0ee14c3e73aF630C029fe020F907);
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IUniswapV2Pair pair = IUniswapV2Pair(0x40eD17221b3B2D8455F4F1a05CAc6b77c5f707e3);

    address attacker = 0x286E09932B8D096cbA3423d12965042736b8F850;

    function setUp() public {
        vm.createSelectFork("bsc", 23_695_904);
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
        queryERC20(address(aes), "aes", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        emit log_string("----query ends----");
    }
}
