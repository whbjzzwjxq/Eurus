// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Basic} from "@utils/ERC20Basic.sol";

contract Rewarder {

    address private _owner;
    ERC20Basic private immutable token;

    mapping(address => uint256) deposits;
    mapping(address => uint256) lastReward;
    mapping(address => bool) locked;

    constructor(address token_) payable {
        token = ERC20Basic(token_);
        _owner = msg.sender;
    }

    function swapToken(uint256 tokenAmount) public payable {
        uint256 currentTokenBalance = token.balanceOf(address(this));
        require(tokenAmount <= currentTokenBalance, "Swap too much token!");
        require(tokenAmount <= msg.value, "Not enough ETH provided!");
        token.transfer(msg.sender, tokenAmount);
    }

    function swapETH(uint256 ETHAmount) public {
        uint256 currentETHBalance = address(this).balance;
        require(ETHAmount <= currentETHBalance, "Swap too much ETH!");
        bool succeed = token.transferFrom(msg.sender, address(this), ETHAmount);
        require(succeed, "Unsucceed transfer!");
        payable(msg.sender).transfer(ETHAmount);
    }

    function deposit(address a) public view returns (uint256) {
        return deposits[a];
    }

    function depositToken(uint256 tokenAmount) public {
        bool succeed = token.transferFrom(msg.sender, address(this), tokenAmount);
        require(succeed, "Unsucceed transfer!");
        deposits[msg.sender] += tokenAmount;
    }

    function depositETH() public payable {
        uint256 currentTokenBalance = token.balanceOf(address(this));
        require(msg.value <= currentTokenBalance, "Not enough token reverse!");
        deposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 tokenAmount) public {
        require(!locked[msg.sender], "Deposit is locked!");
        uint256 currentDeposit = deposit(msg.sender);
        require(tokenAmount <= currentDeposit);
        token.transfer(msg.sender, tokenAmount);
        deposits[msg.sender] = deposits[msg.sender] - tokenAmount;
    }

    function initialReward() public {
        lastReward[msg.sender] = block.timestamp;
        locked[msg.sender] = true;
    }

    function claimReward() public {
        uint256 timePassed = block.timestamp - lastReward[msg.sender];
        lastReward[msg.sender] = block.timestamp;
        deposits[msg.sender] = deposits[msg.sender] + ((timePassed * deposits[msg.sender]) / 24 * 60 * 60);
        locked[msg.sender] = false;
    }

    function _check(address attacker, uint256 amount) public view {
        if (token.balanceOf(attacker) < amount) {
            revert();
        }
    }
}
