// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// Total Lost :  40085 USDT
// Attacker : 0x81c63d821b7cdf70c61009a81fef8db5949ac0c9
// Attack Contract : 0x4e77df7b9cdcecec4115e59546f3eacba095a89f
// Vulnerable Contract : https://bscscan.com/address/0x27539b1dee647b38e1b987c41c5336b1a8dce663
// Attack Tx  0xa13c8c7a0c97093dba3096c88044273c29cebeee109e23622cd412dcca8f50f4

contract ContractTest is Test, BlockLoader {
    IERC20 bxh = IERC20(0x6D1B7b59e3fab85B7d3a3d86e505Dd8e349EA7F3);
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IUniswapV2Pair pair = IUniswapV2Pair(0x919964B7f12A742E3D33176D7aF9094EA4152e6f);

    address attacker = address(0x4e77DF7b9cDcECeC4115e59546F3EAcBA095a89f);

    address bxhstaking = address(0x27539B1DEe647b38e1B987c41C5336b1A8DcE663);

    function setUp() public {
        vm.createSelectFork("bsc", 21727289);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = bxhstaking;
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "bxhstaking";
        queryERC20(address(bxh), "bxh", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        emit log_string("----query ends----");
    }
}
