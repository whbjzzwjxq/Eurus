// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

interface MuBank {
    function mu_bond(address stable, uint256 amount) external;

    function mu_gold_bond(address stable, uint256 amount) external;
}

contract MUMUGTest is Test, BlockLoader {
    MuBank mubank = MuBank(0x4aA679402c6afcE1E0F7Eb99cA4f09a30ce228ab);
    IERC20 mu = IERC20(0xD036414fa2BCBb802691491E323BFf1348C5F4Ba);
    IERC20 usdce = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    // USDCE to MU
    IUniswapV2Pair pair = IUniswapV2Pair(0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5);
    address attacker = 0xd46b44A0e0b90E0136cf456dF633Cd15a87DE77E;
    
    function setUp() public {
        vm.createSelectFork("Avalanche", 23435294);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(mubank);
        users[1] = address(pair);
        users[2] = attacker;
        string[] memory user_names = new string[](3);
        user_names[0] = "mubank";
        user_names[1] = "pair";
        user_names[2] = "attacker";
        queryERC20(address(mu), "mu", users, user_names);
        queryERC20(address(usdce), "usdce", users, user_names);
        emit log_string("----query ends----");
    }
}
