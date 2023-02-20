// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NaiveReceiverLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */

interface FlashLoanReceiver {
    function receiveETH() external payable;
}

contract LenderPool is ReentrancyGuard {

    // not the cheapest flash loan
    uint256 public immutable FIXED_FEE = 1 ether;

    function flashLoan(address borrower, uint256 borrowAmount) external nonReentrant {

        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= borrowAmount, "Not enough ETH in pool");

        FlashLoanReceiver(borrower).receiveETH{value: borrowAmount}();

        require(
            address(this).balance >= balanceBefore + FIXED_FEE,
            "Flash loan hasn't been paid back"
        );
    }

    function fixedFee() public pure returns (uint256) {
        return FIXED_FEE;
    }
}
