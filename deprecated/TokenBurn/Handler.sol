// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";

// import "@utils/WETH.sol";
// import "@utils/UniswapV1.sol";
// import "@utils/ForgeTestHelper.sol";

// import "benchmarks/toy/TokenBurn/BurningToken.sol";

// contract TokenBurnHandler is Handler {
//     address owner;
//     address dead = address(0xdead);

//     BurningToken token;
//     WETH weth;
//     UniswapV1 uniswap;

//     constructor(
//         address owner_,
//         address attacker_,
//         address token_,
//         address weth_,
//         address uniswap_
//     ) {
//         addresses = new address[](6);
//         addresses[0] = owner_;
//         addresses[1] = attacker_;
//         addresses[2] = dead;
//         addresses[3] = token_;
//         addresses[4] = weth_;
//         addresses[5] = uniswap_;
//         owner = owner_;
//         attacker = attacker_;
//         token = BurningToken(token_);
//         weth = WETH(token_);
//         uniswap = UniswapV1(uniswap_);
//     }

//     function callTransfer(uint256 to, uint256 amount) public sendByAttacker {
//         token.transfer(selectAddress(to), amount);
//     }

//     function callApprove(
//         uint256 spender,
//         uint256 amount
//     ) public sendByAttacker {
//         token.approve(selectAddress(spender), amount);
//     }

//     function callTransferFrom(
//         uint256 from,
//         uint256 to,
//         uint256 amount
//     ) public sendByAttacker {
//         token.transferFrom(selectAddress(from), selectAddress(to), amount);
//     }

//     function callBurn(uint256 spender, uint256 amount) public sendByAttacker {
//         token.burn(selectAddress(spender), amount);
//     }

//     function callSwapTokenToWETH(uint256 tokenAmount) public sendByAttacker {
//         uniswap.swapTokenToWETH(tokenAmount);
//     }

//     function callSwapWETHToToken(uint256 wethAmount) public sendByAttacker {
//         uniswap.swapWETHToToken(wethAmount);
//     }

//     function callWETHTransfer(uint256 to, uint256 amount) public sendByAttacker {
//         weth.transfer(selectAddress(to), amount);
//     }
// }
