// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// @Analysis
// https://twitter.com/BlockSecTeam/status/1602877048124735489
// @TX
// https://bscscan.com/tx/0x7d2d8d2cda2d81529e0e0af90c4bfb39b6e74fa363c60b031d719dd9d153b012
// https://bscscan.com/tx/0x42f56d3e86fb47e1edffa59222b33b73e7407d4b5bb05e23b83cb1771790f6c1

contract ContractTest is Test, BlockLoader {
    IERC20 gnimb = IERC20(0x99C486b908434Ae4adF567e9990A929854d0c955);
    IERC20 nimb = IERC20(0xCb492C701F7fe71bC9C4B703b84B0Da933fF26bB);
    IERC20 nbu = IERC20();

    IUniswapV2Pair pairnbugnimb = IUniswapV2Pair(0x68D8fa8a879237D5805F1FAd010d691fD5d4c23c);
    IUniswapV2Pair pairnbunimb = IUniswapV2Pair(0x7D88A2390F8B5070acF5188e8879aA7Ba2f2A60C);

    address attacker = address(0x86Aa1c46f2Ae35ba1B228dC69fB726813D95b597);
    address gslp = address(0x3aA2B9de4ce397d93E11699C3f07B769b210bBD5);

    function setUp() public {
        vm.createSelectFork("bsc", 23_639_507);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pairnbugnimb), "pairnbugnimb");
        queryUniswapV2Pair(address(pairnbunimb), "pairnbunimb");

        address[] memory users = new address[](4);
        users[0] = address(pairnbugnimb);
        users[1] = address(pairnbunimb);
        users[2] = attacker;
        users[3] = gslp;

        string[] memory user_names = new string[](4);
        user_names[0] = "pairnbugnimb";
        user_names[1] = "pairnbunimb";
        user_names[2] = "attacker";
        user_names[3] = "gslp";

        queryERC20(address(gnimb), "gnimb", users, user_names);
        queryERC20(address(nimb), "nimb", users, user_names);
        queryERC20(address(nbu), "nbu", users, user_names);
        emit log_string("----query ends----");
    }
}
