// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@utils/ERC20Basic.sol";

import {UniswapV1} from "examples/PuppetPool/UniswapV1.sol";

contract PuppetPool is ReentrancyGuard {

    UniswapV1 public immutable uniswapPair;
    ERC20Basic public immutable erc20basic;

    mapping(address => uint256) public deposits;
    uint256 immutable rate = 10 ** 18;

    constructor (address token_, address uniswapPair_) payable {
        erc20basic = ERC20Basic(token_);
        uniswapPair = UniswapV1(uniswapPair_);
    }

    // Allows borrowing `borrowAmount` of tokens by first depositing two times their value in ETH
    function borrow(uint256 borrowAmount) public payable nonReentrant {
        uint256 depositRequired = calculateDepositRequired(borrowAmount);

        require(msg.value >= depositRequired, "Not depositing enough collateral");

        if (msg.value > depositRequired) {
            payable(msg.sender).transfer(msg.value - depositRequired);
        }

        deposits[msg.sender] = deposits[msg.sender] + depositRequired;

        // Fails if the pool doesn't have enough tokens in liquidity
        bool succeed = erc20basic.transfer(msg.sender, borrowAmount);
        require(succeed, "Transfer failed");
    }

    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return (amount * address(uniswapPair).balance * 2 + 1) / (uniswapPair.erc20Balance() + 1);
    }

    function _check(address attacker, uint256 amount) public view {
        if (erc20basic.balanceOf(attacker) < amount) {
            revert();
        }
    }
}
