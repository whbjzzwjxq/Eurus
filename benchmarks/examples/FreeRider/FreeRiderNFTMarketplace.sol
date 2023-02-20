// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ERC721Basic} from "@utils/ERC721Basic.sol";

/**
 * @title FreeRiderBuyer
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */

interface NFTSeller {
    function receiver() external view returns (address);
}

contract FreeRiderNFTMarketplace is ReentrancyGuard {

    ERC721Basic public immutable nft;

    uint256 public amountOfOffers;
    // tokenId -> price
    mapping(uint256 => uint256) private offers;

    constructor(address token_) payable {
        nft = ERC721Basic(token_);
    }

    function offerOne(uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be greater than zero");

        require(
            msg.sender == nft.ownerOf(tokenId),
            "Account offering must be the owner"
        );

        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender, address(this)),
            "Account offering must have approved transfer"
        );

        offers[tokenId] = price;

        amountOfOffers++;
    }

    function buyOne(uint256 tokenId) public payable {
        uint256 priceToPay = offers[tokenId];
        require(priceToPay > 0, "Token is not being offered");
        require(msg.value >= priceToPay, "Amount paid is not enough");

        address tokenOwner = nft.ownerOf(tokenId);

        // transfer from seller to buyer
        nft.transferFrom(nft.ownerOf(tokenId), msg.sender, tokenId);

        address receiver = NFTSeller(tokenOwner).receiver();
        if (receiver == address(0)) {
            receiver = nft.ownerOf(tokenId);
        }
        payable(receiver).transfer(priceToPay);

        amountOfOffers--;
    }

    function _check(address attacker, uint256 amount) public view {
        if (address(attacker).balance < amount) {
            revert();
        }
    }
}
