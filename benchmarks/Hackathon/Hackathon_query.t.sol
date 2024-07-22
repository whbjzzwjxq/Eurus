// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 hackathon = IERC20(0x11cee747Faaf0C0801075253ac28aB503C888888);
    
    // busd-hackathon
    IUniswapV2Pair pair = IUniswapV2Pair(0xd46f4a4B57D8EC355fe83F9AE75d4cC04DE371ED);
    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 37854043);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](2);
        users[0] = address(pair);
        users[1] = address(attacker);
        string[] memory user_names = new string[](2);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        queryERC20(address(busd), "busd", users, user_names);
        queryERC20(address(hackathon), "hackathon", users, user_names);
        emit log_string("----query ends----");
    }
}
