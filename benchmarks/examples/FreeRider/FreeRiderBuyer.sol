// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721Basic} from "@utils/ERC721Basic.sol";

/**
 * @title FreeRiderBuyer
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FreeRiderBuyer {

    ERC721Basic public immutable nft;
    uint256 public immutable JOB_PAYOUT;

    uint256 public immutable tokenWTB = 123;

    constructor(address _nft, uint256 job_payout_) payable {
        nft = ERC721Basic(_nft);
        JOB_PAYOUT = job_payout_;
    }

    function buy() external {
        nft.transferFrom(msg.sender, address(this), tokenWTB);
        payable(msg.sender).transfer(JOB_PAYOUT);
    }
}
