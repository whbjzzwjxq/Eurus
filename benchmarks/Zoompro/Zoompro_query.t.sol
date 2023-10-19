// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 zoom = IERC20(0x9CE084C378B3E65A164aeba12015ef3881E0F853);
    IERC20 fusdt = IERC20(0x62D51AACb079e882b1cb7877438de485Cba0dD3f);

    // fusdt-zoom
    IUniswapV2Pair pair = IUniswapV2Pair(0x1c7ecBfc48eD0B34AAd4a9F338050685E66235C5);

    // Users
    address controller = address(0x47391071824569F29381DFEaf2f1b47A4004933B);

    // Different with the actual trader, but used to mock.
    address trader = address(0xf72Fd2A9cDF1DB6d000A6181655e0F072fc47208);
    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 21_055_930);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](4);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = controller;
        users[3] = trader;
        string[] memory user_names = new string[](4);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "controller";
        user_names[3] = "trader";
        queryERC20(address(usdt), "usdt", users, user_names);
        queryERC20(address(zoom), "zoom", users, user_names);
        queryERC20(address(fusdt), "fusdt", users, user_names);
        emit log_string("----query ends----");
    }
}
