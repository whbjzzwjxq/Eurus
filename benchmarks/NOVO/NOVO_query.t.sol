// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// Exploit Alert ref: https://www.panewslab.com/zh_hk/articledetails/f40t9xb4.html
// Origin Attack Transaction: 0xc346adf14e5082e6df5aeae650f3d7f606d7e08247c2b856510766b4dfcdc57f
// Blocksec Txinfo: https://versatile.blocksecteam.com/tx/bsc/0xc346adf14e5082e6df5aeae650f3d7f606d7e08247c2b856510766b4dfcdc57f

// Attack Addr: 0x31a7cc04987520cefacd46f734943a105b29186e
// Attack Contract: 0x3463a663de4ccc59c8b21190f81027096f18cf2a

// Vulnerable Contract: https://bscscan.com/address/0xa0787daad6062349f63b7c228cbfd5d8a3db08f1#code

contract ContractTest is Test, BlockLoader {
    IERC20 novo = IERC20(0x6Fb2020C236BBD5a7DDEb07E14c9298642253333);
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    IUniswapV2Pair pair = IUniswapV2Pair(0x128cd0Ae1a0aE7e67419111714155E1B1c6B2D8D);

    address attacker = 0x31A7CC04987520cEfaCd46F734943A105b29186E;

    function setUp() public {
        vm.createSelectFork("bsc", 18_225_002);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = address(novo);
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "novo";
        queryERC20(address(novo), "novo", users, user_names);
        queryERC20(address(wbnb), "wbnb", users, user_names);
        emit log_string("----query ends----");
    }
}
