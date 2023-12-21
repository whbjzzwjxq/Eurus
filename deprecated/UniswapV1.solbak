// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Simpified version of UniswapV1
contract UniswapV1 {
    IERC20 public immutable token;
    IERC20 public immutable weth;
    uint256 public immutable fee;
    uint256 constant deno = 1000;
    uint256 constant offset = 1e6;

    constructor(address token_, address weth_, uint256 fee_) payable {
        token = IERC20(token_);
        weth = IERC20(weth_);
        fee = fee_;
        require(fee <= deno, "Fee should be less or equal than denominator.");
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function wethBalance() public view returns (uint256) {
        return weth.balanceOf(address(this));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    function swapTokenToWETH(uint256 tokenAmount) public {
        uint256 expectedWETH = (tokenAmount * wethBalance() + offset) /
            (tokenBalance() + offset);
        uint256 wethCounter = min(expectedWETH, wethBalance());
        uint256 feeCounter = (wethCounter * fee) / deno;
        uint256 wethAmount = wethCounter - feeCounter;
        bool succeed = token.transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        require(succeed, "Transfer failed");
        weth.transfer(msg.sender, wethAmount);
    }

    function swapWETHToToken(uint256 wethAmount) public {
        uint256 expectedToken = (wethAmount * tokenBalance() + offset) /
            (wethBalance() + offset);
        uint256 tokenCounter = min(expectedToken, tokenBalance());
        uint256 feeCounter = (tokenCounter * fee) / deno;
        uint256 tokenAmount = tokenCounter - feeCounter;
        bool succeed = weth.transferFrom(msg.sender, address(this), wethAmount);
        require(succeed, "Transfer failed");
        token.transfer(msg.sender, tokenAmount);
    }
}
