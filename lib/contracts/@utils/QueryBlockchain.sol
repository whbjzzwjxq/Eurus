// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Pair.sol";

abstract contract BlockLoader is Test {
    function queryERC20Balance(address token_, address user_) public {
        IERC20 token = IERC20(token_);
        emit log_named_address("Token", token_);
        emit log_named_address("User", user_);
        emit log_named_uint("balanceOf", token.balanceOf(user_));
    }

    function queryERC20BalanceDecimals(address token_, address user_, uint8 decimals_) public {
        IERC20 token = IERC20(token_);
        emit log_named_address("Token", token_);
        emit log_named_address("User", user_);
        emit log_named_decimal_uint("balanceOf", token.balanceOf(user_), decimals_);
    }

    function queryERC20TotalSupply(address token_) public {
        IERC20 token = IERC20(token_);
        emit log_named_address("Token", token_);
        emit log_named_uint("totalSupply", token.totalSupply());
    }

    function queryUniswapV2(address pair_) public {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_);
        emit log_named_address("Pair", pair_);

        (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast) = pair
            .getReserves();

        emit log_named_uint("reserve0", reserve0);
        emit log_named_uint("reserve1", reserve1);
        emit log_named_uint("blockTimestampLast", blockTimestampLast);
        emit log_named_uint("kLast", pair.kLast());
        emit log_named_uint(
            "price0CumulativeLast",
            pair.price0CumulativeLast()
        );
        emit log_named_uint(
            "price1CumulativeLast",
            pair.price1CumulativeLast()
        );
        emit log_string("");

        address token0 = pair.token0();
        queryERC20Balance(token0, pair_);
        address token1 = pair.token1();
        queryERC20Balance(token1, pair_);
    }
}
