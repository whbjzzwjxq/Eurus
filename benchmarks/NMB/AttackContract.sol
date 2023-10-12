// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GNIMB} from "./GNIMB.sol";
import {GNIMBStaking} from "./GNIMBStaking.sol";

contract AttackContract {

    GNIMB gnimb;
    GNIMBStaking gnimbstaking;

    function setUp(address gnimbAddr, address gnimbstakingAddr) public {
        gnimb = GNIMB(gnimbAddr);
        gnimbstaking = GNIMBStaking(gnimbstakingAddr);
        gnimb.approve(address(gnimbstaking), type(uint256).max);
        gnimbstaking.stake(gnimb.balanceOf(address(this)));
    }
}