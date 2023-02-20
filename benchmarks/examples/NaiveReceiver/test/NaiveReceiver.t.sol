// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "examples/NaiveReceiver/LenderPool.sol";
import "examples/NaiveReceiver/NaiveReceiver.sol";

contract NaiveReceiverFuzzing is Test {
    address owner;
    address attacker;
    LenderPool pool;
    NaiveReceiver receiver;

    uint256 public attackerInitBalance = 10 ether;
    uint256 public receiverInitBalance = 100 ether;
    uint256 public fee = 1 ether;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);

        vm.deal(attacker, attackerInitBalance);

        pool = new LenderPool();
        receiver = new NaiveReceiver{value: receiverInitBalance}(address(pool));
    }

    function testAttackGT() public {
        testAttack(10 ether, 10 ether, 10 ether);
    }

    function testAttack(
        uint256 v0,
        uint256 v1,
        uint256 v2
    ) public {
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);
        call_data = abi.encodeWithSignature("receiveETH()");
        (succeed, ) = address(receiver).call{value: v0}(call_data);
        if (succeed) {
            (succeed, ) = address(receiver).call{value: v1}(call_data);
            if (succeed) {
                (succeed, ) = address(receiver).call{value: v2}(call_data);
                if (succeed) {
                    emit log_named_uint("Attacker.balance: ", attacker.balance);
                    assert(attacker.balance < attackerInitBalance + fee * 3);
                }
            }
        }
        vm.stopPrank();
    }
}
