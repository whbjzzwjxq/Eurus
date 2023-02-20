// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FreeRiderNFTMarketplace} from "examples/FreeRider/FreeRiderNFTMarketplace.sol";

import {ERC721Basic} from "@utils/ERC721Basic.sol";

contract FreeRiderSeller {

    address private immutable owner;
    ERC721Basic public immutable nft;
    FreeRiderNFTMarketplace public immutable market;
    uint256 public immutable TOKEN_PRICE;
    uint256 public immutable tokenWTS = 123;

    address public _receiver;

    constructor(address _nft, address market_, uint256 _token_price) payable {
        owner = msg.sender;
        nft = ERC721Basic(_nft);
        market = FreeRiderNFTMarketplace(payable(market_));
        _receiver = msg.sender;
        TOKEN_PRICE = _token_price;
    }

    function receiver() public view returns (address) {
        return _receiver;
    }

    function setReceiver(address receiver_) public {
        require(msg.sender == owner);
        _receiver = receiver_;
    }

    function removeReceiver() public {
        _receiver = address(0);
    }
}
