// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {LenderPool} from "examples/NaiveReceiver/LenderPool.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */

contract NaiveReceiver {

    LenderPool public immutable pool;
    uint256 public immutable loanRequired;

    constructor(address pool_) payable {
        pool = LenderPool(pool_);
        loanRequired = 10 ether;
    }

    function doSomething() internal {
        // Do something;
    }

    function receiveETH() external payable {
        require(msg.value >= loanRequired, "Need at least 10 ether");
        uint256 amountToBeRepaid = msg.value + pool.fixedFee();
        require(address(this).balance >= amountToBeRepaid, "Cannot borrow that much");
        doSomething();
        // Return funds to pool
        payable(msg.sender).transfer(amountToBeRepaid);
    }

    function _check(address attacker, uint256 amount) public view {
        if (address(attacker).balance < amount) {
            revert();
        }
    }
}
