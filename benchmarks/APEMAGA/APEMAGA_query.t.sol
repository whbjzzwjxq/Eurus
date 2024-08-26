// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 apemaga = IERC20(0x56FF4AfD909AA66a1530fe69BF94c74e6D44500C);
    
    // hct-wbnb
    IUniswapV2Pair pair = IUniswapV2Pair(0x85705829c2f71EE3c40A7C28f6903e7c797c9433);
    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("mainnet", 20175261);
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
        queryERC20(address(weth), "wbnb", users, user_names);
        queryERC20(address(apemaga), "apemaga", users, user_names);
        emit log_string("----query ends----");
    }
}
