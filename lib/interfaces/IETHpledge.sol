// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IETHpledge {
    function pledgein(
        address fatheraddr,
        uint256 amountt
    ) external returns (bool);
}
