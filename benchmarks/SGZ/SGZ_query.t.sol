// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

/* @KeyInfo - Total Lost : 25,378 BUSD
    Attacker Wallet : https://bscscan.com/address/0x00a62eb08868ec6feb23465f61aa963b89e57e57
    Attack Contract : https://bscscan.com/address/0x3d817ea746edd02c088c4df47c0ece0bd28dcd72
    SpaceGodzilla : https://bscscan.com/address/0x2287c04a15bb11ad1358ba5702c1c95e2d13a5e0
    Attack Tx : https://bscscan.com/tx/0x7f183df11f1a0225b5eb5bb2296b5dc51c0f3570e8cc15f0754de8e6f8b4cca4*/

/* @News
    BlockSec : https://mobile.twitter.com/BlockSecTeam/status/1547456591900749824
    PANews : https://www.panewslab.com/zh_hk/articledetails/u25j5p3kdvu9.html*/

/* @Reports
    Numen Cyber Labs : https://medium.com/numen-cyber-labs/spacegodzilla-attack-event-analysis-d29a061b17e1
    Learnblockchain.cn Analysis : https://learnblockchain.cn/article/4396
    Learnblockchain.cn Analysis : https://learnblockchain.cn/article/4395*/

contract ContractTest is Test, BlockLoader {
    IERC20 sgz = IERC20(0x2287C04a15bb11ad1358BA5702C1C95E2D13a5E0);
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);

    IUniswapV2Pair pair = IUniswapV2Pair(0x8AfF4e8d24F445Df313928839eC96c4A618a91C8);

    address attacker = address(0x00a62EB08868eC6fEB23465F61aA963B89e57e57);

    function setUp() public {
        vm.createSelectFork("bsc", 19_523_980);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = address(sgz);
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "sgz";
        queryERC20(address(sgz), "sgz", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        emit log_string("----query ends----");
    }
}
