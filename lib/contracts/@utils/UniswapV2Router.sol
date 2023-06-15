// // SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity ^0.8.0;

// //solhint-disable not-rely-on-time
// //solhint-disable var-name-mixedcase
// //solhint-disable reason-string

// import "@uniswapv2/contracts/interfaces/IUniswapV2Router.sol";
// import "@uniswapv2/contracts/interfaces/IUniswapV2Pair.sol";
// import "@uniswapv2/contracts/interfaces/IERC20.sol";
// import "@uniswapv2/contracts/interfaces/IWETH.sol";
// import "@uniswapv2/contracts/libraries/UniswapV2Library.sol";

// contract UniswapV2Router is IUniswapV2Router {
//     address public immutable override factory = address(0xfac5051);
//     IWETH public immutable weth;
//     IERC20 public immutable token0;
//     IERC20 public immutable token1;
//     IUniswapV2Pair public immutable pair;

//     modifier ensure(uint256 deadline) {
//         require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
//         _;
//     }

//     constructor(address weth_, address tokenA_, address tokenB_, address pair_) {
//         weth = IWETH(weth_);
//         token0 = IERC20(tokenA_);
//         token1 = IERC20(tokenB_);
//         pair = IUniswapV2Pair(pair_);
//     }

//     receive() external payable {
//         assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
//     }

//     // **** ADD LIQUIDITY ****
//     function _addLiquidity(
//         uint256 amountADesired,
//         uint256 amountBDesired,
//         uint256 amountAMin,
//         uint256 amountBMin
//     ) internal virtual returns (uint256 amountA, uint256 amountB) {
//         (uint256 reserveA, uint256 reserveB) = pair.getReserves();
//         if (reserveA == 0 && reserveB == 0) {
//             (amountA, amountB) = (amountADesired, amountBDesired);
//         } else {
//             uint256 amountBOptimal = UniswapV2Library.quote(
//                 amountADesired,
//                 reserveA,
//                 reserveB
//             );
//             if (amountBOptimal <= amountBDesired) {
//                 require(
//                     amountBOptimal >= amountBMin,
//                     "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
//                 );
//                 (amountA, amountB) = (amountADesired, amountBOptimal);
//             } else {
//                 uint256 amountAOptimal = UniswapV2Library.quote(
//                     amountBDesired,
//                     reserveB,
//                     reserveA
//                 );
//                 assert(amountAOptimal <= amountADesired);
//                 require(
//                     amountAOptimal >= amountAMin,
//                     "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
//                 );
//                 (amountA, amountB) = (amountAOptimal, amountBDesired);
//             }
//         }
//     }

//     function addLiquidity(
//         uint256 amountADesired,
//         uint256 amountBDesired,
//         uint256 amountAMin,
//         uint256 amountBMin,
//         address to,
//         uint256 deadline
//     )
//         external
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256 amountA, uint256 amountB, uint256 liquidity)
//     {
//         (amountA, amountB) = _addLiquidity(
//             amountADesired,
//             amountBDesired,
//             amountAMin,
//             amountBMin
//         );
//         token0.safeTransferFrom(msg.sender, pair, amountA);
//         token1.safeTransferFrom(msg.sender, pair, amountB);
//         liquidity = pair.mint(to);
//     }

//     function addLiquidityETH(
//         address token,
//         uint256 amountTokenDesired,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline
//     )
//         external
//         payable
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
//     {
//         // Remove this function
//     }

//     // **** REMOVE LIQUIDITY ****
//     function removeLiquidity(
//         address tokenA,
//         address tokenB,
//         uint256 liquidity,
//         uint256 amountAMin,
//         uint256 amountBMin,
//         address to,
//         uint256 deadline
//     )
//         public
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256 amountA, uint256 amountB)
//     {
//         pair.transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
//         (uint256 amount0, uint256 amount1) = pair.burn(to);
//         (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
//         (amountA, amountB) = tokenA == token0
//             ? (amount0, amount1)
//             : (amount1, amount0);
//         require(
//             amountA >= amountAMin,
//             "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
//         );
//         require(
//             amountB >= amountBMin,
//             "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
//         );
//     }

//     function removeLiquidityETH(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline
//     )
//         public
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256 amountToken, uint256 amountETH)
//     {
//         // Remove this function
//     }

//     function removeLiquidityWithPermit(
//         address tokenA,
//         address tokenB,
//         uint256 liquidity,
//         uint256 amountAMin,
//         uint256 amountBMin,
//         address to,
//         uint256 deadline,
//         bool approveMax,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external virtual override returns (uint256 amountA, uint256 amountB) {
//         address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
//         uint256 value = approveMax ? type(uint256).max : liquidity;
//         IUniswapV2Pair(pair).permit(
//             msg.sender,
//             address(this),
//             value,
//             deadline,
//             v,
//             r,
//             s
//         );
//         (amountA, amountB) = removeLiquidity(
//             tokenA,
//             tokenB,
//             liquidity,
//             amountAMin,
//             amountBMin,
//             to,
//             deadline
//         );
//     }

//     function removeLiquidityETHWithPermit(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline,
//         bool approveMax,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     )
//         external
//         virtual
//         override
//         returns (uint256 amountToken, uint256 amountETH)
//     {
//         address pair = UniswapV2Library.pairFor(factory, token, weth);
//         uint256 value = approveMax ? type(uint256).max : liquidity;
//         IUniswapV2Pair(pair).permit(
//             msg.sender,
//             address(this),
//             value,
//             deadline,
//             v,
//             r,
//             s
//         );
//         (amountToken, amountETH) = removeLiquidityETH(
//             token,
//             liquidity,
//             amountTokenMin,
//             amountETHMin,
//             to,
//             deadline
//         );
//     }

//     // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
//     function removeLiquidityETHSupportingFeeOnTransferTokens(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline
//     ) public virtual override ensure(deadline) returns (uint256 amountETH) {
//         (, amountETH) = removeLiquidity(
//             token,
//             weth,
//             liquidity,
//             amountTokenMin,
//             amountETHMin,
//             address(this),
//             deadline
//         );
//         TransferHelper.safeTransfer(
//             token,
//             to,
//             IERC20(token).balanceOf(address(this))
//         );
//         IWETH(weth).withdraw(amountETH);
//         TransferHelper.safeTransferETH(to, amountETH);
//     }

//     function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
//         address token,
//         uint256 liquidity,
//         uint256 amountTokenMin,
//         uint256 amountETHMin,
//         address to,
//         uint256 deadline,
//         bool approveMax,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external virtual override returns (uint256 amountETH) {
//         address pair = UniswapV2Library.pairFor(factory, token, weth);
//         uint256 value = approveMax ? type(uint256).max : liquidity;
//         IUniswapV2Pair(pair).permit(
//             msg.sender,
//             address(this),
//             value,
//             deadline,
//             v,
//             r,
//             s
//         );
//         amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
//             token,
//             liquidity,
//             amountTokenMin,
//             amountETHMin,
//             to,
//             deadline
//         );
//     }

//     // **** SWAP ****
//     // requires the initial amount to have already been sent to the first pair
//     function _swap(
//         uint256[] memory amounts,
//         address[] memory path,
//         address _to
//     ) internal virtual {
//         for (uint256 i; i < path.length - 1; i++) {
//             (address input, address output) = (path[i], path[i + 1]);
//             (address token0, ) = UniswapV2Library.sortTokens(input, output);
//             uint256 amountOut = amounts[i + 1];
//             (uint256 amount0Out, uint256 amount1Out) = input == token0
//                 ? (uint256(0), amountOut)
//                 : (amountOut, uint256(0));
//             address to = i < path.length - 2
//                 ? UniswapV2Library.pairFor(factory, output, path[i + 2])
//                 : _to;
//             IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
//                 .swap(amount0Out, amount1Out, to, new bytes(0));
//         }
//     }

//     function swapExactTokensForTokens(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     )
//         external
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256[] memory amounts)
//     {
//         amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
//         require(
//             amounts[amounts.length - 1] >= amountOutMin,
//             "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
//         );
//         TransferHelper.safeTransferFrom(
//             path[0],
//             msg.sender,
//             UniswapV2Library.pairFor(factory, path[0], path[1]),
//             amounts[0]
//         );
//         _swap(amounts, path, to);
//     }

//     function swapTokensForExactTokens(
//         uint256 amountOut,
//         uint256 amountInMax,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     )
//         external
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256[] memory amounts)
//     {
//         amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
//         require(
//             amounts[0] <= amountInMax,
//             "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
//         );
//         TransferHelper.safeTransferFrom(
//             path[0],
//             msg.sender,
//             UniswapV2Library.pairFor(factory, path[0], path[1]),
//             amounts[0]
//         );
//         _swap(amounts, path, to);
//     }

//     function swapExactETHForTokens(
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     )
//         external
//         payable
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256[] memory amounts)
//     {
//         require(path[0] == weth, "UniswapV2Router: INVALID_PATH");
//         amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
//         require(
//             amounts[amounts.length - 1] >= amountOutMin,
//             "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
//         );
//         IWETH(weth).deposit{value: amounts[0]}();
//         assert(
//             IWETH(weth).transfer(
//                 UniswapV2Library.pairFor(factory, path[0], path[1]),
//                 amounts[0]
//             )
//         );
//         _swap(amounts, path, to);
//     }

//     function swapTokensForExactETH(
//         uint256 amountOut,
//         uint256 amountInMax,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     )
//         external
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256[] memory amounts)
//     {
//         require(path[path.length - 1] == weth, "UniswapV2Router: INVALID_PATH");
//         amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
//         require(
//             amounts[0] <= amountInMax,
//             "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
//         );
//         TransferHelper.safeTransferFrom(
//             path[0],
//             msg.sender,
//             UniswapV2Library.pairFor(factory, path[0], path[1]),
//             amounts[0]
//         );
//         _swap(amounts, path, address(this));
//         IWETH(weth).withdraw(amounts[amounts.length - 1]);
//         TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
//     }

//     function swapExactTokensForETH(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     )
//         external
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256[] memory amounts)
//     {
//         require(path[path.length - 1] == weth, "UniswapV2Router: INVALID_PATH");
//         amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
//         require(
//             amounts[amounts.length - 1] >= amountOutMin,
//             "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
//         );
//         TransferHelper.safeTransferFrom(
//             path[0],
//             msg.sender,
//             UniswapV2Library.pairFor(factory, path[0], path[1]),
//             amounts[0]
//         );
//         _swap(amounts, path, address(this));
//         IWETH(weth).withdraw(amounts[amounts.length - 1]);
//         TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
//     }

//     function swapETHForExactTokens(
//         uint256 amountOut,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     )
//         external
//         payable
//         virtual
//         override
//         ensure(deadline)
//         returns (uint256[] memory amounts)
//     {
//         require(path[0] == weth, "UniswapV2Router: INVALID_PATH");
//         amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
//         require(
//             amounts[0] <= msg.value,
//             "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
//         );
//         IWETH(weth).deposit{value: amounts[0]}();
//         assert(
//             IWETH(weth).transfer(
//                 UniswapV2Library.pairFor(factory, path[0], path[1]),
//                 amounts[0]
//             )
//         );
//         _swap(amounts, path, to);
//         // refund dust eth, if any
//         if (msg.value > amounts[0])
//             TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
//     }

//     // **** SWAP (supporting fee-on-transfer tokens) ****
//     // requires the initial amount to have already been sent to the first pair
//     function _swapSupportingFeeOnTransferTokens(
//         address[] memory path,
//         address _to
//     ) internal virtual {
//         for (uint256 i; i < path.length - 1; i++) {
//             (address input, address output) = (path[i], path[i + 1]);
//             (address token0, ) = UniswapV2Library.sortTokens(input, output);
//             IUniswapV2Pair pair = IUniswapV2Pair(
//                 UniswapV2Library.pairFor(factory, input, output)
//             );
//             uint256 amountInput;
//             uint256 amountOutput;
//             {
//                 // scope to avoid stack too deep errors
//                 (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
//                 (uint256 reserveInput, uint256 reserveOutput) = input == token0
//                     ? (reserve0, reserve1)
//                     : (reserve1, reserve0);
//                 amountInput =
//                     IERC20(input).balanceOf(address(pair)) -
//                     reserveInput;
//                 amountOutput = UniswapV2Library.getAmountOut(
//                     amountInput,
//                     reserveInput,
//                     reserveOutput
//                 );
//             }
//             (uint256 amount0Out, uint256 amount1Out) = input == token0
//                 ? (uint256(0), amountOutput)
//                 : (amountOutput, uint256(0));
//             address to = i < path.length - 2
//                 ? UniswapV2Library.pairFor(factory, output, path[i + 2])
//                 : _to;
//             pair.swap(amount0Out, amount1Out, to, new bytes(0));
//         }
//     }

//     function swapExactTokensForTokensSupportingFeeOnTransferTokens(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external virtual override ensure(deadline) {
//         TransferHelper.safeTransferFrom(
//             path[0],
//             msg.sender,
//             UniswapV2Library.pairFor(factory, path[0], path[1]),
//             amountIn
//         );
//         uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
//         _swapSupportingFeeOnTransferTokens(path, to);
//         require(
//             IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >=
//                 amountOutMin,
//             "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
//         );
//     }

//     function swapExactETHForTokensSupportingFeeOnTransferTokens(
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external payable virtual override ensure(deadline) {
//         // Remove this function
//     }

//     function swapExactTokensForETHSupportingFeeOnTransferTokens(
//         uint256 amountIn,
//         uint256 amountOutMin,
//         address[] calldata path,
//         address to,
//         uint256 deadline
//     ) external virtual override ensure(deadline) {
//         // Remove this function
//     }

//     // **** LIBRARY FUNCTIONS ****
//     function quote(
//         uint256 amountA,
//         uint256 reserveA,
//         uint256 reserveB
//     ) public pure virtual override returns (uint256 amountB) {
//         return UniswapV2Library.quote(amountA, reserveA, reserveB);
//     }

//     function getAmountOut(
//         uint256 amountIn,
//         uint256 reserveIn,
//         uint256 reserveOut
//     ) public pure virtual override returns (uint256 amountOut) {
//         return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
//     }

//     function getAmountIn(
//         uint256 amountOut,
//         uint256 reserveIn,
//         uint256 reserveOut
//     ) public pure virtual override returns (uint256 amountIn) {
//         return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
//     }

//     function getAmountsOut(
//         uint256 amountIn,
//         address[] memory path
//     ) public view virtual override returns (uint256[] memory amounts) {
//         return UniswapV2Library.getAmountsOut(factory, amountIn, path);
//     }

//     function getAmountsIn(
//         uint256 amountOut,
//         address[] memory path
//     ) public view virtual override returns (uint256[] memory amounts) {
//         return UniswapV2Library.getAmountsIn(factory, amountOut, path);
//     }
// }
