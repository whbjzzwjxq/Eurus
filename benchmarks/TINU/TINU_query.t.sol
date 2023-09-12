// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// Total lost: 22 ETH
// Attacker: 0x14d8ada7a0ba91f59dc0cb97c8f44f1d177c2195
// Attack Contract: 0xdb2d869ac23715af204093e933f5eb57f2dc12a9
// Vulnerable Contract: 0x2d0e64b6bf13660a4c0de42a0b88144a7c10991f
// Attack Tx: https://phalcon.blocksec.com/tx/eth/0x6200bf5c43c214caa1177c3676293442059b4f39eb5dbae6cfd4e6ad16305668
//            https://etherscan.io/tx/0x6200bf5c43c214caa1177c3676293442059b4f39eb5dbae6cfd4e6ad16305668

// @Analysis
// https://twitter.com/libevm/status/1618731761894309889

contract ContractTest is Test, BlockLoader {
    IERC20 private constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 private constant tinu = IERC20(0x2d0E64B6bF13660a4c0De42a0B88144a7C10991F);

    IUniswapV2Pair private constant pair = IUniswapV2Pair(0xb835752Feb00c278484c464b697e03b03C53E11B);

    address attacker = 0x14d8Ada7A0BA91f59Dc0Cb97C8F44F1d177c2195;

    function setUp() external {
        vm.createSelectFork("mainnet", 16489408);
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
        queryERC20(address(weth), "weth", users, user_names);
        queryERC20(address(tinu), "tinu", users, user_names);
        emit log_string("----query ends----");
    }
}
