// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import "@utils/QueryBlockchain.sol";
import "@utils/USDCE.sol";
import "./Mu.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import "./MuBank.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract MUMUGTest is Test, BlockLoader {
    MuBank mubank;
    Mu mu;
    USDCE usdce;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    address attacker;
    address constant owner = address(0x123456);
    uint112 reserve0pair = 110596398651;
    uint112 reserve1pair = 172739951491310439336991;
    uint32 blockTimestampLastpair = 1670632626;
    uint256 kLastpair = 19102449214934407600169207587014640;
    uint256 price0CumulativeLastpair =
        308814746138342549066779453499621908384171319637193787;
    uint256 price1CumulativeLastpair = 108977737583418847522328147893;
    uint256 totalSupplymu = 1000000000000000000000000;
    uint256 balanceOfmumubank = 100000000000000000000000;
    uint256 balanceOfmupair = 172739951491310439336991;
    uint256 balanceOfmuattacker = 0;
    uint256 totalSupplyusdce = 193102891951559;
    uint256 balanceOfusdcemubank = 0;
    uint256 balanceOfusdcepair = 110596398651;
    uint256 balanceOfusdceattacker = 0;

    function setUp() public {
        attacker = address(this);
        vm.startPrank(owner);
        mu = new Mu(totalSupplymu);
        usdce = new USDCE();
        pair = new UniswapV2Pair(
            address(usdce),
            address(mu),
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
        mu.transfer(address(mubank), balanceOfmumubank);
        mu.transfer(address(pair), balanceOfmupair);
        mu.approve(attacker, UINT256_MAX);
        usdce.transfer(address(mubank), balanceOfusdcemubank);
        usdce.transfer(address(pair), balanceOfusdcepair);
        usdce.approve(attacker, UINT256_MAX);
        vm.stopPrank();
    }
}
