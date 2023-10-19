// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract ZoomController {
    address private _uniswapAddr;

    constructor(address uniswapAddr) {
        _uniswapAddr = uniswapAddr;
    }

    function batchToken(
        address[] calldata _addr,
        uint256[] calldata _num,
        address token
    ) external {
        for (uint256 i = 0; i < _addr.length; i++) {
            address addr = _addr[i];
            uint256 num = _num[i];
            IERC20(token).transfer(addr, num);
        }
    }
}
