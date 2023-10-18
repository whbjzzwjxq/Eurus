// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XSushi is ERC20 {
    uint256 private _totalSupply;
    constructor() ERC20("SushiBar", "xSUSHI") {
        _totalSupply = 17238576213941926120365877;
    }
}
