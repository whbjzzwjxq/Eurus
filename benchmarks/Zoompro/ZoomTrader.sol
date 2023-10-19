// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract ZoomTrader {
    address private _uniswapAddr;
    address private _uniswapRouter;

    UniswapV2Pair pair;
    UniswapV2Router router;
    IERC20 zoom;
    IERC20 usdt;
    IERC20 fusdt;

    constructor(
        address uniswapAddr,
        address payable uniswapRouterAddr,
        address zoomAddr,
        address usdtAddr,
        address fusdtAddr
    ) {
        _uniswapAddr = uniswapAddr;
        _uniswapRouter = uniswapRouterAddr;
        pair = UniswapV2Pair(uniswapAddr);
        router = UniswapV2Router(uniswapRouterAddr);
        zoom = IERC20(zoomAddr);
        usdt = IERC20(usdtAddr);
        fusdt = IERC20(fusdtAddr);
    }

    function buy(uint256 amount) public {
        usdt.transferFrom(msg.sender, address(this), amount);
        fusdt.approve(address(pair), amount);
        fusdt.transfer(address(pair), amount);
        (uint256 reserveIn, uint256 reserveOut, ) = pair.getReserves();
        uint256 amountOut = router.getAmountOut(amount, reserveIn, reserveOut);
        pair.swap(0, amountOut, msg.sender, new bytes(0));
    }

    function sell(uint256 amount) public {
        zoom.transferFrom(msg.sender, address(pair), amount);
        (uint256 reserveIn, uint256 reserveOut, ) = pair.getReserves();
        uint256 amountOut = router.getAmountOut(amount, reserveOut, reserveIn);
        pair.swap(amountOut, 0, address(this), new bytes(0));
        usdt.transfer(msg.sender, amountOut);
    }
}
