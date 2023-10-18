// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BentoBoxV1} from "./BentoBoxV1.sol";

contract AttackContract {
    BentoBoxV1 gnimb;

    function setUp(address payable bentboxAddr, address masterContract) public {
        BentoBoxV1(bentboxAddr).setMasterContractApproval(
            address(this),
            masterContract,
            true,
            uint8(0),
            bytes32(0),
            bytes32(0)
        );
    }
}
