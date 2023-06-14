// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@utils/WETH.sol";
import "@utils/UniswapV1.sol";

import "benchmarks/toy/LiquidityAdder/TokenA.sol";

contract TokenADeployer {

    TokenA token;
    WETH weth;
    UniswapV1 uniswap;

    constructor(address token_, address weth_, address uniswap_) {
        token = TokenA(token_);
        weth = WETH(weth_);
        uniswap = UniswapV1(uniswap_);
    }

    function addLiquidityToPool(uint256 amtTokenA, uint256 amtWETH) public {
        require(amtTokenA <= token.balanceOf(address(this)), "Not enough tokenA!");
        require(amtWETH <= weth.balanceOf(address(this)), "Not enough WETH!");
        token.transfer(address(uniswap), amtTokenA);
        weth.transfer(address(uniswap), amtWETH);
    }
}
