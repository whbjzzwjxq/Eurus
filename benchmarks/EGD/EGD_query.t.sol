// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import "@utils/QueryBlockchain.sol";

// @KeyInfo - Total Lost : ~36,044 US$
// Attacker : 0xee0221d76504aec40f63ad7e36855eebf5ea5edd
// Attack Contract : 0xc30808d9373093fbfcec9e026457c6a9dab706a7
// Vulnerable Contract : 0x34bd6dba456bc31c2b3393e499fa10bed32a9370 (Proxy)
// Vulnerable Contract : 0x93c175439726797dcee24d08e4ac9164e88e7aee (Logic)
// Attack Tx : https://bscscan.com/tx/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

// @Info
// Vulnerable Contract Code : https://bscscan.com/address/0x93c175439726797dcee24d08e4ac9164e88e7aee#code#F1#L254
// Stake Tx : https://bscscan.com/tx/0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

// @Analysis
// Blocksec : https://twitter.com/BlockSecTeam/status/1556483435388350464
// PeckShield : https://twitter.com/PeckShieldAlert/status/1556486817406283776

contract ContractTest is Test, BlockLoader {
    // Tokens
    IERC20 egd = IERC20(0x202b233735bF743FA31abb8f71e641970161bF98);
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);

    // Pair
    IUniswapV2Pair pair = IUniswapV2Pair(0xa361433E409Adac1f87CDF133127585F8a93c67d);

    // Users
    address attacker = address(0x4e77DF7b9cDcECeC4115e59546F3EAcBA095a89f);
    address egdstaking = address(0x34Bd6Dba456Bc31c2b3393e499fa10bED32a9370);

    function setUp() public {
        vm.createSelectFork("bsc", 20_245_522);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = attacker;
        users[2] = egdstaking;
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "attacker";
        user_names[2] = "egdstaking";

        queryERC20(address(egd), "egd", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        emit log_string("----query ends----");
    }
}
