// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@utils/ERC20Basic.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(uint256 amount) external;
}

/**
 * @title UnstoppableLender
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract LenderPool is ReentrancyGuard {

    ERC20Basic public immutable token;
    uint256 public allDepositsBalance = 0;
    uint256 public poolBalance = 0;

    constructor(address token_) {
        token = ERC20Basic(token_);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        // Run automatically after the first Deposit.
        require(amount > 0, "Must deposit at least one token");
        token.transferFrom(msg.sender, address(this), amount);
        allDepositsBalance += amount;
        poolBalance = token.balanceOf(address(this));
    }

    function flashLoan(address receiver, uint256 borrowAmount) external nonReentrant {
        require(borrowAmount > 0, "Must borrow at least one token");

        require(poolBalance >= borrowAmount, "Not enough tokens in pool");

        // Ensured by the protocol via the `depositTokens` function
        require(poolBalance == allDepositsBalance);

        token.transfer(msg.sender, borrowAmount);

        IReceiver(receiver).receiveTokens(borrowAmount);

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= poolBalance, "Flash loan hasn't been paid back");
        poolBalance = token.balanceOf(address(this));
    }

    function _check() public view {
        if (poolBalance == allDepositsBalance) {
            revert();
        }
    }
}
