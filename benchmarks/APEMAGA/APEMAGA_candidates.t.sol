// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {APEMAGA} from "./APEMAGA.sol";
import {AttackContract} from "./AttackContract.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WETH} from "@utils/WETH.sol";

contract APEMAGATest is Test, BlockLoader {
    WETH weth;
    APEMAGA apemaga;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wethAddr;
    address apemagaAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1719397643;
    uint112 reserve0pair = 54765572250112844423;
    uint112 reserve1pair = 9146306958660137885;
    uint32 blockTimestampLastpair = 1719397583;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 924504523958275391543891579333734752;
    uint256 price1CumulativeLastpair = 90615988006238608201646154271471894632;
    uint256 totalSupplyweth = 2854187513811339559603869;
    uint256 balanceOfwethpair = 9146306958660137885;
    uint256 balanceOfwethattacker = 0;
    uint256 totalSupplyapemaga = 91159088068526318125;
    uint256 balanceOfapemagapair = 54765572250112844423;
    uint256 balanceOfapemagaattacker = 0;

    function setUp() public {
        owner = address(this);
        weth = new WETH();
        wethAddr = address(weth);
        apemaga = new APEMAGA("HCT", "XAI", 9, 91159088068);
        apemagaAddr = address(apemaga);
        pair = new UniswapV2Pair(
            address(apemaga),
            address(weth),
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
        weth.transfer(address(pair), balanceOfwethpair);
        apemaga.transfer(address(pair), balanceOfapemagapair);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Weth Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(weth),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(apemaga),
            address(weth),
            apemaga.decimals()
        );
        emit log_string("");
        emit log_string("Apemaga Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(apemaga),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(apemaga),
            address(apemaga),
            apemaga.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(pair),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(apemaga),
            address(pair),
            apemaga.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(weth),
            address(attacker),
            weth.decimals()
        );
        queryERC20BalanceDecimals(
            address(apemaga),
            address(attacker),
            apemaga.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return weth.balanceOf(attacker) >= 1e12 + balanceOfwethattacker;
    }

    function borrow_weth_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        weth.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_weth_owner(uint256 amount) internal eurus {
        weth.transfer(owner, amount);
    }

    function borrow_apemaga_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        apemaga.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_apemaga_owner(uint256 amount) internal eurus {
        apemaga.transfer(owner, amount);
    }

    function swap_pair_attacker_apemaga_weth(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        apemaga.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_weth_apemaga(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        weth.transfer(address(pair), amount);
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
        vm.assume(amt5 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_apemaga(amt1, amt2);
        swap_pair_attacker_apemaga_weth(amt3, amt4);
        payback_weth_owner(amt5);
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
        borrow_apemaga_owner(amt0);
        swap_pair_attacker_apemaga_weth(amt1, amt2);
        swap_pair_attacker_weth_apemaga(amt3, amt4);
        payback_apemaga_owner(amt5);
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
        vm.assume(amt9 >= amt0);
        borrow_weth_owner(amt0);
        swap_pair_attacker_weth_apemaga(amt1, amt2);
        swap_pair_attacker_apemaga_weth(amt3, amt4);
        swap_pair_attacker_weth_apemaga(amt5, amt6);
        swap_pair_attacker_apemaga_weth(amt7, amt8);
        payback_weth_owner(amt9);
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
        vm.assume(amt9 >= amt0);
        borrow_apemaga_owner(amt0);
        swap_pair_attacker_apemaga_weth(amt1, amt2);
        swap_pair_attacker_weth_apemaga(amt3, amt4);
        swap_pair_attacker_apemaga_weth(amt5, amt6);
        swap_pair_attacker_weth_apemaga(amt7, amt8);
        payback_apemaga_owner(amt9);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_weth_owner(2200 * 1e18);
        printBalance("After step0 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(uint256 amt0) public {
        vm.startPrank(attacker);
        vm.assume(amt0 >= amt0);
        borrow_weth_owner(amt0);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
