// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract EtherReceiverMock {
    bool private _acceptEther;

    function setAcceptEther(bool acceptEther) public {
        _acceptEther = acceptEther;
    }

    receive() external payable {
        if (!_acceptEther) {
            revert();
        }
    }
}
