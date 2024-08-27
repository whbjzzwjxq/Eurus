// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./AxiomaPresale.sol";
import "@utils/QueryBlockchain.sol";

contract ContractTest is Test, BlockLoader {
    address wbnb_usdt_b = 0xFeAFe253802b77456B4627F8c2306a9CeBb5d681; // dodo wbnb-usdt pool
    IERC20 wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 axt = IERC20(0xB6CF5b77B92a722bF34f6f5D6B1Fe4700908935E);
    
    // axt-wbnb
    IUniswapV2Pair pair = IUniswapV2Pair(0x6a3Fa7D2C71fd7D44BF3a2890aA257F34083c90f);
    AxiomaPresale axiomaPresale = AxiomaPresale(0x2C25aEe99ED08A61e7407A5674BC2d1A72B5D8E3);
    address attacker = address(0xb8D700f30d93FAb242429245E892600dCC03935D);

    function setUp() public {
        vm.createSelectFork("bsc", 27_620_321 - 1);
    }

    function test_query() public {
        emit log_string("----query starts----");
        queryBlockTimestamp();
        queryUniswapV2Pair(address(pair), "pair");
        address[] memory users = new address[](3);
        users[0] = address(pair);
        users[1] = address(axiomaPresale);
        users[2] = attacker;
        string[] memory user_names = new string[](3);
        user_names[0] = "pair";
        user_names[1] = "axiomaPresale";
        user_names[2] = "attacker";
        queryERC20(address(wbnb), "wbnb", users, user_names);
        queryERC20(address(axt), "axt", users, user_names);
        emit log_string("----query ends----");
    }
}
