// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20Basic} from "@utils/ERC20Basic.sol";

contract UniswapV1 {

    ERC20Basic public immutable erc20basic;

    constructor(address token_) payable {
        erc20basic = ERC20Basic(token_);
    }

    function erc20Balance() public view returns (uint256) {
        return erc20basic.balanceOf(address(this));
    }

    function swapToken(uint256 tokenAmount, uint256 ethAmount) public {
        require((tokenAmount * address(this).balance) >= (ethAmount * erc20Balance()),
            "Swap too much eths!");
        erc20basic.transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(ethAmount);
    }

    function swapETH(uint256 tokenAmount) public payable {
        require((msg.value * erc20Balance()) >= (tokenAmount * address(this).balance),
            "Swap too much tokens!");
        erc20basic.transfer(msg.sender, tokenAmount);
    }
}
