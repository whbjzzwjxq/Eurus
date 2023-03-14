// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";
import "@utils/UniswapV1.sol";
import "@utils/Handler.sol";

import "benchmarks/PuppetPool/PuppetPool.sol";

contract PuppetPoolHandler is Handler {
    address owner;
    address dead = address(0xdead);

    ERC20Basic token;
    WETH weth;
    UniswapV1 uniswap;
    PuppetPool puppetpool;

    constructor(
        address owner_,
        address attacker_,
        address token_,
        address weth_,
        address uniswap_,
        address puppetpool_
    ) {
        addresses = new address[](7);
        addresses[0] = owner_;
        addresses[1] = attacker_;
        addresses[2] = dead;
        addresses[3] = token_;
        addresses[4] = weth_;
        addresses[5] = uniswap_;
        addresses[6] = puppetpool_;
        owner = owner_;
        attacker = attacker_;
        token = ERC20Basic(token_);
        weth = WETH(token_);
        uniswap = UniswapV1(uniswap_);
        puppetpool = PuppetPool(puppetpool_);
    }

    function callTransfer(uint256 to, uint256 amount) public sendByAttacker {
        token.transfer(selectAddress(to), amount);
    }

    function callApprove(
        uint256 spender,
        uint256 amount
    ) public sendByAttacker {
        token.approve(selectAddress(spender), amount);
    }

    function callTransferFrom(
        uint256 from,
        uint256 to,
        uint256 amount
    ) public sendByAttacker {
        token.transferFrom(selectAddress(from), selectAddress(to), amount);
    }

    function callSwapTokenToWETH(uint256 tokenAmount) public sendByAttacker {
        uniswap.swapTokenToWETH(tokenAmount);
    }

    function callSwapWETHToToken(uint256 wethAmount) public sendByAttacker {
        uniswap.swapWETHToToken(wethAmount);
    }

    function callBorrowWETH(uint256 borrowAmount) public sendByAttacker {
        puppetpool.borrowWETH(borrowAmount);
    }

    function callWETHTransfer(uint256 to, uint256 amount) public sendByAttacker {
        weth.transfer(selectAddress(to), amount);
    }
}
