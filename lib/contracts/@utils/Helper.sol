// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@interfaces/IUniswapV2Pair.sol";
import {UniswapV2Library} from "@uniswapv2/libraries/UniswapV2Library.sol";

abstract contract Helper is Test {
    function concatString(
        string memory str1,
        string memory str2
    ) public pure returns (string memory) {
        return string(abi.encodePacked(str1, str2));
    }

    function queryERC20Balance(
        address token_addr,
        string memory token_name,
        address user_addr,
        string memory user_name
    ) public {
        IERC20 token = IERC20(token_addr);
        string memory prefix0 = concatString("uint256 balanceOf", token_name);
        string memory prefix1 = concatString(prefix0, user_name);
        emit log_named_uint(prefix1, token.balanceOf(user_addr));
    }

    function queryERC20BalanceBatch(
        address[] memory token_addrs,
        string[] memory token_names,
        address[] memory user_addrs,
        string[] memory user_names
    ) public {
        require(
            token_addrs.length == token_names.length,
            "Unmatched user names."
        );
        require(
            user_addrs.length == user_names.length,
            "Unmatched user names."
        );
        for (uint i = 0; i < user_addrs.length; i++) {
            string memory userName = concatString("UserName: ", user_names[i]);
            emit log_string(userName);
            for (uint j = 0; j < token_addrs.length; j++) {
                queryERC20Balance(
                    token_addrs[j],
                    token_names[j],
                    user_addrs[i],
                    user_names[i]
                );
            }
            emit log_string("");
        }
    }

    function queryERC20(
        address token_addr,
        string memory token_name,
        address[] memory user_addrs,
        string[] memory user_names
    ) public {
        require(
            user_addrs.length == user_names.length,
            "Unmatched user names."
        );

        emit log_string(concatString("----queryERC20 starts----", token_name));
        IERC20 token = IERC20(token_addr);
        emit log_named_uint(
            concatString("uint256 totalSupply", token_name),
            token.totalSupply()
        );
        for (uint i = 0; i < user_addrs.length; i++) {
            queryERC20Balance(
                token_addr,
                token_name,
                user_addrs[i],
                user_names[i]
            );
        }
        emit log_string(concatString("----queryERC20 ends----", token_name));
    }

    function queryUniswapV2Pair(
        address pair_addr,
        string memory pair_name
    ) public {
        emit log_string(
            concatString("----queryUniswapV2Pair starts----", pair_name)
        );
        IUniswapV2Pair pair = IUniswapV2Pair(pair_addr);

        (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast) = pair
            .getReserves();

        emit log_named_uint(
            concatString("uint112 reserve0", pair_name),
            reserve0
        );
        emit log_named_uint(
            concatString("uint112 reserve1", pair_name),
            reserve1
        );
        emit log_named_uint(
            concatString("uint32 blockTimestampLast", pair_name),
            blockTimestampLast
        );
        emit log_named_uint(
            concatString("uint256 kLast", pair_name),
            pair.kLast()
        );
        emit log_named_uint(
            concatString("uint256 price0CumulativeLast", pair_name),
            pair.price0CumulativeLast()
        );
        emit log_named_uint(
            concatString("uint256 price1CumulativeLast", pair_name),
            pair.price1CumulativeLast()
        );
        emit log_string(
            concatString("----queryUniswapV2Pair ends----", pair_name)
        );
    }

    function getAmountOut(
        address pairAddr,
        uint256 amountIn,
        address input
    ) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        address token0 = pair.token0();
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        return
            UniswapV2Library.getAmountOut(
                amountIn,
                reserveInput,
                reserveOutput
            );
    }

    function getAmountIn(
        address pairAddr,
        uint256 amountOut,
        address input
    ) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        address token0 = pair.token0();
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        return
            UniswapV2Library.getAmountIn(
                amountOut,
                reserveInput,
                reserveOutput
            );
    }
}
