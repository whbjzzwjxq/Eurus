// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@utils/ERC20Basic.sol";

contract Duplicator {

    address private _owner;
    ERC20Basic public immutable bnbToken;
    ERC20Basic public immutable dpcToken;

    mapping(address => uint256) rewardQuota;
    mapping(address => uint256) oldClaimQuota;
    uint256 public totalQuota = 100;
    uint256 public totalReward = 100 ether;

    uint256 public immutable MIN_LP = 1 ether;
    uint256 public immutable SWAP_RATE = 20;
    uint256 public immutable SWAPB_RATE = 25;

    constructor(address bnbToken_, address dpcToken_) payable {
        _owner = msg.sender;
        bnbToken = ERC20Basic(bnbToken_);
        dpcToken = ERC20Basic(dpcToken_);
    }

    function bnbBalance() public view returns (uint256) {
        return bnbToken.balanceOf(address(this));
    }

    function dpcBalance() public view returns (uint256) {
        return dpcToken.balanceOf(address(this));
    }

    function claimedQuota(address addr) public view returns (uint256) {
        return oldClaimQuota[addr];
    }

    function addLiquidity(uint256 bnbAmount) public returns (bool) {
        address _from = msg.sender;
        bool succeed = bnbToken.transferFrom(_from, address(this), bnbAmount);
        require(succeed, "Transfer failed!");
        require(bnbAmount * SWAP_RATE <= dpcBalance(), "Too much bnb token");
        dpcToken.transfer(_from, bnbAmount * SWAP_RATE);
        uint256 quota = bnbAmount / MIN_LP;
        rewardQuota[_from] += quota;
        totalQuota += quota;
        return true;
    }

    function swapForBNB(uint256 dpcAmount) public returns (bool) {
        address _from = msg.sender;
        bool succeed = dpcToken.transferFrom(_from, address(this), dpcAmount);
        require(succeed, "Transfer failed!");
        require(dpcAmount <= bnbBalance() * SWAPB_RATE, "Too much dpc token");
        bnbToken.transfer(_from, dpcAmount / SWAPB_RATE);
        return true;
    }

    function getClaimQuota(address addr) public view returns (uint256) {
        return rewardQuota[addr] * totalReward / totalQuota;
    }

    function claimStakeLp(uint256 amount) public {
        address _from = msg.sender;
        require(amount > 0, "Quantity error");
        require(rewardQuota[_from] >= amount, "Insufficient authorization limit");
        oldClaimQuota[_from] += getClaimQuota(_from);
        rewardQuota[_from] -= amount;
    }

    function withdrawReward(uint256 amount) public {
        address _from = msg.sender;
        require(amount <= oldClaimQuota[_from], "Withdraw too much reward!");
        dpcToken.transfer(_from, amount);
        oldClaimQuota[_from] -= amount;
    }

    function _check(address attacker, uint256 amount) public view {
        if (dpcToken.balanceOf(attacker) < amount) {
            revert();
        }
    }

}
