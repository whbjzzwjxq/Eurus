import os
import subprocess
from typing import List

from .config import Config, init_config
from .utils import CornerCase
from .synthesizer import Synthesizer


class BenchmarkBuilder:
    """
    Used for building test sol contract to do the test.
    """

    stable_coins = ("USDCE", "USDT", "WETH")
    pair_name = "UniswapV2Pair"

    def __init__(self, bmk_dir: str) -> None:
        self.bmk_dir = bmk_dir
        self.config: Config = init_config(bmk_dir)
        self.name = self.config.project_name
        # Map contract's variable name to its contract label.
        self.ctrt_name_mapping = self.config.ctrt_name_mapping
        # Like pair, router, usdt, etc.
        self.ctrt_names = list(self.ctrt_name_mapping.keys())
        # Like UniswapV2Router, USDCE, USDT, etc.
        self.ctrt_labels = set(self.ctrt_name_mapping.values())

        # Map state_variable name to its type and initial value.
        self.init_states = {}

    def get_initial_state(self) -> List[str]:
        # bmk_dir = os.path.abspath(os.path.join(os.getcwd(), self.bmk_dir))
        bmk_dir = self.bmk_dir
        # Handle the initial states print by foundry.
        # Look at: QueryBlockchain.sol
        cmd = [
            "forge",
            "test",
            "-vv",
            "--match-path",
            f"{bmk_dir}/{self.name}_query.t.sol",
        ]
        try:
            proc = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=os.getcwd(),
            )
        except Exception as err:
            err.add_note("Forge test failed!")
            raise err
        outputs = proc.stdout.split("\n") + proc.stderr.split("\n")
        states = []
        for output in outputs:
            if output.startswith("  ----"):
                continue
            if output == "":
                continue
            if not output.startswith("  "):
                continue
            result = [s for s in output.split(" ") if s != ""]
            if len(result) != 3:
                continue
            type_str, sv_name, sv_val = result
            type_str = type_str.removeprefix(" ")
            sv_name = sv_name.removesuffix(":")
            self.init_states[sv_name] = (type_str, sv_val)
            output_str = f"{type_str} {sv_name} = {sv_val};"
            states.append(output_str)
        return states

    def gen_imports(self) -> List[str]:
        license = "// SPDX-License-Identifier: MIT"
        pragma = "pragma solidity ^0.8.0;"
        imports = [
            'import "forge-std/Test.sol";',
            'import "@utils/QueryBlockchain.sol";',
        ]
        for c in self.ctrt_labels:
            if c in ("USDCE", "USDT", "WETH"):
                imports.append(f'import "@utils/{c}.sol";')
            elif c == "UniswapV2Pair":
                imports.append(
                    'import {UniswapV2Pair} from "@utils/UniswapV2Pair.sol";'
                )
            elif c == "UniswapV2Factory":
                imports.append(
                    'import {UniswapV2Factory} from "@utils/UniswapV2Factory.sol";'
                )
            elif c == "UniswapV2Router":
                imports.append(
                    'import {UniswapV2Router} from "@utils/UniswapV2Router.sol";'
                )
            else:
                special_import = f'import "./{c}.sol";'
                imports.append(special_import)
        all = [license, pragma, *imports]
        return all

    def gen_contract_header(self) -> List[str]:
        return [f"contract {self.name}Test is Test, BlockLoader " + "{"]

    def gen_state_varibles(self) -> List[str]:
        contract_interfaces = [f"{v} {k};" for k, v in self.ctrt_name_mapping.items()]
        users = [
            f"address attacker;",
            "address constant owner = address(0x123456);",
        ]
        states = self.get_initial_state()
        all = [*contract_interfaces, *users, *states]
        return all

    def gen_setup(self) -> List[str]:
        all = [
            "function setUp() public {",
            "attacker = address(this);",
            "vm.startPrank(owner);",
        ]

        # Deploy contracts
        for d in self.config.deployments:
            ctrt_name, stmt = d
            # Default deployment
            if stmt == "":
                ctrt_label = self.ctrt_name_mapping[ctrt_name]
                if ctrt_label in self.stable_coins:
                    d_stmt = f"{ctrt_name} = new {ctrt_label}();"
                elif ctrt_label == "UniswapV2Pair":
                    token0, token1 = self.config.uniswap_mapping[ctrt_name]
                    d_stmt = f"{ctrt_name} = new UniswapV2Pair(\
                        address({token0}), address({token1}), \
                        reserve0{ctrt_name}, reserve1{ctrt_name}, \
                        blockTimestampLast{ctrt_name}, kLast{ctrt_name}, \
                        price0CumulativeLast{ctrt_name}, price1CumulativeLast{ctrt_name});"
                elif ctrt_label == "UniswapV2Factory":
                    pairs = [
                        k
                        for k, v in self.ctrt_name_mapping.items()
                        if v == "UniswapV2Pair"
                    ]
                    if len(pairs) > 3:
                        raise ValueError("More than 3 pairs are not supported.")
                    while len(pairs) < 3:
                        pairs.append("0x0")
                    d_stmt = f"{ctrt_name} = new UniswapV2Factory(address(0xdead), \
                        address({pairs[0]}), address({pairs[1]}), address({pairs[2]}));"
                elif ctrt_label == "UniswapV2Router":
                    d_stmt = f"{ctrt_name} = new UniswapV2Router(address(factory), address(0xdead));"
                else:
                    raise CornerCase("Unsupported default deployment.")
            else:
                d_stmt = f"{ctrt_name} = {stmt};"
            all.append(d_stmt)

        all.append("// Initialize balances and mock flashloan.")

        # Deploy tokens
        for t in self.config.tokens:
            for u in self.config.token_users:
                sv_name = f"balanceOf{t}{u}"
                val = self.init_states.get(sv_name, "0")
                if val != "0":
                    stmt = f"{t}.transfer(address({u}), {sv_name});"
                    all.append(stmt)
            all.append(f"{t}.approve(attacker, UINT256_MAX);")

        all.extend(self.config.extra_deployments)
        all.append("vm.stopPrank();")
        all.append("}")
        return all

    def gen_helper_funcs(self) -> List[str]:
        # Print balance.
        printer = [
            "function printBalance(string memory tips) public {",
            "emit log_string(tips);",
        ]
        tokens = self.config.tokens
        users = self.config.token_users + ["attacker"]
        for u in users:
            printer.append(f'emit log_string("{u.capitalize()} Balances: ");')
            addr = f"address({u})" if u != "attacker" else u
            for t in tokens:
                printer.append(
                    f"queryERC20BalanceDecimals(address({t}), {addr}, {t}.decimals());"
                )
            printer.append('emit log_string("");')
        printer.append('emit log_string("");')
        printer.append('emit log_string("");')
        printer.append("}")

        # Attack goal
        attack_goal = [
            "function attackGoal() public view returns (bool) {",
            f"return {self.config.attack_goal};",
            "}",
        ]

        nop = ["function nop(uint256 amount) internal pure {", "return;", "}"]

        # Actions
        actions = []
        # flashloan borrow-payback
        for t in self.config.tokens:
            borrow = [
                f"function borrow_{t}(uint256 amount) internal " + "{",
                f"{t}.transferFrom(owner, attacker, amount);",
                "}",
            ]
            payback = [
                f"function payback_{t}(uint256 amount) internal " + "{",
                f"{t}.transfer(owner, amount);",
                "}",
            ]
            actions.extend(borrow)
            actions.extend(payback)

        # swap by uniswap
        router_name = "router"
        for u, t in self.config.uniswap_mapping.items():
            token0, token1 = t
            swap0 = [
                f"function swap_{u}_{token0}_{token1}(uint256 amount) internal" + "{",
                f"{token0}.approve(address({router_name}), type(uint).max);",
                f"address[] memory path = new address[](2);",
                f"path[0] = address({token0});",
                f"path[1] = address({token1});",
                f"router.swapExactTokensForTokensSupportingFeeOnTransferTokens( \
                    amount, 1, path, attacker, block.timestamp);",
                "}",
            ]
            actions.extend(swap0)
            token1, token0 = t
            swap1 = [
                f"function swap_{u}_{token0}_{token1}(uint256 amount) internal" + "{",
                f"{token0}.approve(address({router_name}), type(uint).max);",
                f"address[] memory path = new address[](2);",
                f"path[0] = address({token0});",
                f"path[1] = address({token1});",
                f"router.swapExactTokensForTokensSupportingFeeOnTransferTokens( \
                    amount, 1, path, attacker, block.timestamp);",
                "}",
            ]
            actions.extend(swap1)

        all = [*printer, *attack_goal, *nop, *actions, *self.config.actions]
        return all

    def gen_gt_for_forge_and_halmos(self) -> List[str]:
        # Build groundtruth test for forge
        func_body = []
        for idx, g in enumerate(self.config.groundtruth):
            name, arg = g
            if name != "nop":
                func_body.append(f'printBalance("Before step{idx}: ");')
                func_body.append(f"{name}({arg});")
        test_gt = [
            "function test_gt() public {",
            *func_body,
            'require(attackGoal(), "Attack failed!");',
            '}'
        ]

        # Build groundtruth test for halmos
        params = [f"uint256 amt{idx}" for idx in range(self.config.total_amt)]
        func_body = []
        for idx, g in enumerate(self.config.groundtruth):
            name, _ = g
            if name != "nop":
                func_body.append(f"{name}(amt{idx});")
        check_gt = [
            f'function check_gt({",".join(params)}) public ' + "{",
            "".join([f"vm.assume({c});\n" for c in self.config.constraints]),
            *func_body,
            "assert(!attackGoal());",
            "}",
        ]
        all = [*test_gt, *check_gt]
        return all
    
    def gen_candidates(self) -> List[str]:
        synthesizer = Synthesizer(self.config)
        return synthesizer.output()

    def output(self, output_path: str):
        if os.path.exists(output_path):
            os.remove(output_path)
        results = [
            *self.gen_imports(),
            *self.gen_contract_header(),
            *self.gen_state_varibles(),
            *self.gen_setup(),
            *self.gen_helper_funcs(),
            *self.gen_gt_for_forge_and_halmos(),
            *self.gen_candidates(),
            "}",
        ]
        with open(output_path, "w") as f:
            for l in results:
                f.write(l)
                f.write("\n")

        # Format
