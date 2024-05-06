// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./LUSD.sol";
import "./Loan.sol";
import "./LUSDPool.sol";
import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    // address wbnb_usdt_b = 0xFeAFe253802b77456B4627F8c2306a9CeBb5d681; // dodo wbnb-usdt pool
    IERC20 lusd = IERC20(0x3cD632C25A4Db4c1A636cFb23B9285Be1097A60d);
    IERC20 usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 btcb = IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    
    // usdt-btcb
    IUniswapV2Pair pairub = IUniswapV2Pair(0x3F803EC2b816Ea7F06EC76aA2B6f2532F9892d62);
    
    // btcb-lusd
    Loan loan = Loan(0xdeC12a1dCbC1F741cCD02dFd862ab226F6383003);

    // lusd-usdt
    LUSDPool lusdpool = LUSDPool(0x637De69F45F3b66D5389F305088A38109aA0cf7C);

    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 29_756_866);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pairub), "pairub");
        address[] memory users = new address[](4);
        users[0] = address(pairub);
        users[1] = address(loan);
        users[2] = address(lusdpool);
        users[3] = attacker;
        // users[1] = address(axiomaPresale);
        // users[2] = attacker;
        string[] memory user_names = new string[](4);
        user_names[0] = "pairub";
        user_names[1] = "loan";
        user_names[2] = "lusdpool";
        user_names[3] = "attacker";

        // user_names[1] = "axiomaPresale";
        queryERC20(address(lusd), "lusd", users, user_names);
        queryERC20(address(usdt), "usdt", users, user_names);
        queryERC20(address(btcb), "btcb", users, user_names);
        emit log_string("----query ends----");
    }
}
