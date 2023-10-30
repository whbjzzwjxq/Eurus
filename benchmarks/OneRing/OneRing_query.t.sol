// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// Hack tx: https://ftmscan.com/tx/0xca8dd33850e29cf138c8382e17a19e77d7331b57c7a8451648788bbb26a70145

contract ContractTest is Test, BlockLoader {
    IERC20 mim = IERC20(0x82f0B8B456c1A451378467398982d4834b6829c1);
    IERC20 usdce = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IERC20 vault = IERC20(0x4e332D616b5bA1eDFd87c899E534D996c336a2FC);

    IUniswapV2Pair pair = IUniswapV2Pair(0xbcab7d083Cf6a01e0DdA9ed7F8a02b47d125e682);

    address strategy = address(0x8b12522260d4eC64B93A7b087b084437BF9927EE);
    address attacker = address(0x12EfeD3512EA7b76F79BcdE4a387216C7bcE905e);

    function setUp() public {
        vm.createSelectFork("fantom", 34_041_499);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryBaseV1Pair(address(pair), "pair");
        address[] memory users = new address[](4);
        users[0] = address(pair);
        users[3] = address(vault);
        users[1] = attacker;
        users[2] = strategy;
        string[] memory user_names = new string[](4);
        user_names[0] = "pair";
        user_names[3] = "vault";
        user_names[1] = "attacker";
        user_names[2] = "strategy";
        queryERC20(address(vault), "vault", users, user_names);
        queryERC20(address(mim), "mim", users, user_names);
        queryERC20(address(usdce), "usdce", users, user_names);
        emit log_string("----query ends----");
    }
}
