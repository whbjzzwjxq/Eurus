// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

abstract contract Handler is Test {
    address attacker;
    address[] public addresses;

    function selectAddress(uint256 seed) internal view returns (address) {
        require(addresses.length != 0, "Empty addresses!");
        uint256 len = addresses.length;
        return addresses[seed % len];
    }

    modifier sendByAttacker() {
        vm.stopPrank();
        vm.startPrank(attacker);
        _;
        vm.stopPrank();
    }
}
