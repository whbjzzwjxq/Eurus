// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@utils/ERC20Basic.sol";
import "examples/Unstoppable/LenderPool.sol";

/**
 * @title ReceiverUnstoppable
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Receiver {
    LenderPool public immutable pool;
    ERC20Basic public immutable token;

    uint256 public immutable tokenBalance = 1000;

    constructor(address pool_, address token_) {
        pool = LenderPool(pool_);
        token = ERC20Basic(token_);
    }

    // Pool will call this function during the flash loan
    function receiveTokens(uint256 amount) external {
        require(msg.sender == address(pool), "Sender must be pool");
        require(token.balanceOf(address(this)) == tokenBalance + amount, "No vulnerability");
        // Return all tokens to the pool
        bool succeed = token.transfer(msg.sender, amount);
        require(succeed, "Transfer of tokens failed");
    }
}
