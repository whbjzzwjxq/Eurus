// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "examples/TokenBurner/TokenBurner.sol";

contract TokenBurnerFuzzing is Test {
    address owner;
    address attacker;
    TokenBurner token;

    uint256 public attackerInitBalance = 1 ether;
    uint256 public tokenInitBalance = 100 ether;
    uint256 public tokenInitSupply = 100 ether;

    uint256 public requiredBalance = 100 ether;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);
        vm.deal(attacker, attackerInitBalance);

        token = new TokenBurner(tokenInitSupply);
        vm.deal(address(token), tokenInitBalance);
    }

    function addressSelector(uint256 e) public returns (address) {
        address[3] memory addresses = [
            address(0),
            attacker,
            address(token)
        ];
        e = bound(e, 0, addresses.length - 1);
        return addresses[e];
    }

    function testAttackGT() public {
        testAttack(2, tokenInitSupply, 99 ether);
    }

    function testAttack(
        uint256 e0,
        uint256 v0,
        uint256 v1
    ) public {
        address a0 = addressSelector(e0);
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);

        call_data = abi.encodeWithSignature("burn(address,uint256)", a0, v0);
        (succeed, ) = address(token).call(call_data);
        if (succeed) {
            call_data = abi.encodeWithSignature("swapToken(uint256)", v1);
            (succeed, ) = address(token).call(call_data);
            emit log_named_uint("attacker.balance: ", attacker.balance);
            assert(attacker.balance < requiredBalance);
        }
        vm.stopPrank();
    }
}
