// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@utils/UniswapV1.sol";

contract PuppetPool is ReentrancyGuard {
    UniswapV1 uniswap;
    IERC20 token;
    IERC20 weth;

    uint256 constant offset = 1e6;

    mapping(address => uint256) public deposits;

    event Borrowed(
        address indexed account,
        uint256 depositRequired,
        uint256 borrowAmount
    );

    constructor(address token_, address weth_, address uniswapPair_) payable {
        token = IERC20(token_);
        weth = IERC20(weth_);
        uniswap = UniswapV1(uniswapPair_);
    }

    function borrowWETH(uint256 borrowAmount) public nonReentrant {
        uint256 depositRequired = calculateDepositRequired(borrowAmount);

        // Fails if the user doesn't have enough tokens in liquidity
        bool succeed = token.transferFrom(
            msg.sender,
            address(this),
            depositRequired
        );
        require(succeed, "Transfer failed");
        deposits[msg.sender] += depositRequired;
        weth.transfer(msg.sender, borrowAmount);
    }

    function calculateDepositRequired(
        uint256 amount
    ) public view returns (uint256) {
        return
            (amount * uniswap.tokenBalance() + offset) /
            (uniswap.wethBalance() + offset);
    }
}
