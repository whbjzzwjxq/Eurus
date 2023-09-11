// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Pair.sol";

abstract contract BlockLoader is Test {
    function concatString(
        string memory str1,
        string memory str2
    ) public pure returns (string memory) {
        return string(abi.encodePacked(str1, str2));
    }

    function queryERC20Balance(address token_, address user_) public {
        IERC20 token = IERC20(token_);
        emit log_named_address("Token", token_);
        emit log_named_address("User", user_);
        emit log_named_uint("balanceOf", token.balanceOf(user_));
    }

    function queryERC20BalanceDecimals(
        address token_,
        address user_,
        uint8 decimals_
    ) public {
        IERC20 token = IERC20(token_);
        emit log_named_address("Token", token_);
        emit log_named_address("User", user_);
        emit log_named_decimal_uint(
            "balanceOf",
            token.balanceOf(user_),
            decimals_
        );
    }

    function queryERC20(
        address token_,
        string memory name,
        address[] memory users,
        string[] memory user_names
    ) public {
        require(users.length == user_names.length, "Unmatched user names.");
        emit log_string(concatString("----queryERC20 starts----", name));
        IERC20 token = IERC20(token_);
        emit log_named_uint(concatString("uint256 totalSupply", name), token.totalSupply());
        for (uint i = 0; i < users.length; i++) {
            string memory prefix0 = concatString("uint256 balanceOf", name);
            string memory prefix1 = concatString(prefix0, user_names[i]);
            emit log_named_uint(prefix1, token.balanceOf(users[i]));
        }
        emit log_string(concatString("----queryERC20 ends----", name));
    }

    function queryUniswapV2Pair(address pair_, string memory name) public {
        emit log_string(
            concatString("----queryUniswapV2Pair starts----", name)
        );
        IUniswapV2Pair pair = IUniswapV2Pair(pair_);

        (uint256 reserve0, uint256 reserve1, uint256 blockTimestampLast) = pair
            .getReserves();

        emit log_named_uint(concatString("uint112 reserve0", name), reserve0);
        emit log_named_uint(concatString("uint112 reserve1", name), reserve1);
        emit log_named_uint(
            concatString("uint32 blockTimestampLast", name),
            blockTimestampLast
        );
        emit log_named_uint(concatString("uint256 kLast", name), pair.kLast());
        emit log_named_uint(
            concatString("uint256 price0CumulativeLast", name),
            pair.price0CumulativeLast()
        );
        emit log_named_uint(
            concatString("uint256 price1CumulativeLast", name),
            pair.price1CumulativeLast()
        );
        emit log_string(concatString("----queryUniswapV2Pair ends----", name));
    }

    function queryBlockTimestamp() public {
        emit log_string("----queryBlockTimestamp starts----");
        emit log_named_uint("uint256 blockTimestamp", block.timestamp);
        emit log_string("----queryBlockTimestamp ends----");
    }
}
