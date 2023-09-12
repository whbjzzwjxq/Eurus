import os
import subprocess
from typing import List, Dict, Tuple

from decimal import Decimal

from .config import Config, init_config
from .utils import CornerCase
from .synthesizer import Synthesizer
from .dsl import *


class BenchmarkBuilder:
    """
    Used for building test sol contract to do the test.
    """

    uniswap_pair_ctrt = "UniswapV2Pair"
    uniswap_factory_ctrt = "UniswapV2Factory"
    uniswap_router_ctrt = "UniswapV2Router"
    default_erc20_tokens = [
        "USDCE",
        "USDT",
        "WETH",
        "WBNB",
    ]
    default_import_ctrts = [
        *default_erc20_tokens,
        uniswap_pair_ctrt,
        uniswap_factory_ctrt,
        uniswap_router_ctrt,
    ]

    def __init__(self, bmk_dir: str) -> None:
        self.bmk_dir = bmk_dir
        self.config: Config = init_config(bmk_dir)
        self.name = self.config.project_name
        self.roles = self.config.roles

        # Map contract's variable name to its contract label.
        self.ctrt_name2cls = {name: cls for name, cls in self.config.ctrt_name2cls}
        self.ctrt_name2deploy = self.config.ctrt_name2deploy
        # Like pair, router, usdt, etc.
        self.ctrt_names = list(self.ctrt_name2cls.keys())
        # Like UniswapV2Router, USDCE, USDT, etc.
        self.ctrt_cls = set(self.ctrt_name2cls.values())

        self.attack_goal = self.config.attack_goal
        self.extra_actions = self.config.extra_actions
        self.extra_deployments = self.config.extra_deployments
        self.extra_constraints = self.config.extra_constraints

        # Uniswap pairs.
        self.uniswap_pairs: List[str] = [
            name for name, role in self.roles.items() if len(role.uniswap_order) != 0
        ]

        # Uniswap pairs to token_names
        self.uniswap_pair2tokens: Dict[str, Tuple[str, str]] = {
            u: tuple(self.roles[u].uniswap_order) for u in self.uniswap_pairs
        }

        # ERC20 tokens.
        self.erc20_tokens = [name for name, role in self.roles.items() if role.is_erc20]

        # Map state_variable name to its type and initial value.
        self.init_states: Dict[str, Tuple[str, str]] = {}

        # Will print token_users' initial balances.
        self.token_users = [
            c
            for c in self.ctrt_names
            if (c not in self.erc20_tokens) and (c in self.roles)
        ] + ["attacker"]

        actions = [init_action_from_list(a, True) for a in self.config.groundtruth]
        self.sketch = Sketch(actions)
        self.flashloan_amount = Decimal(self.sketch.actions[0].amount)

    def get_initial_state(self) -> List[str]:
        # Handle the initial states print by foundry.
        # Look at: QueryBlockchain.sol and query_output_example.txt for more information.
        cache_file = path.join(self.bmk_dir, "result", "_query.cache")
        if path.exists(cache_file):
            with open(cache_file, "r") as f:
                outputs = f.readlines()
                outputs = [l.removesuffix("\n") for l in outputs]
        else:
            cmd = [
                "forge",
                "test",
                "-vv",
                "--match-path",
                f"{self.bmk_dir}/{self.name}_query.t.sol",
            ]
            print(" ".join(cmd))
            try:
                proc = subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    cwd=os.getcwd(),
                    check=True,
                )
            except Exception as err:
                err.add_note("Forge test failed!")
                raise err
            outputs = proc.stdout + proc.stderr
            with open(cache_file, "w") as f:
                f.write(outputs)
            outputs = outputs.split("\n")
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
        for c in self.ctrt_cls:
            if c in self.default_import_ctrts:
                imports.append(f'import {{{c}}} from "@utils/{c}.sol";')
            else:
                imports.append(f'import "./{c}.sol";')
        imports = sorted(imports)
        all = [license, pragma, *imports]
        return all

    def gen_contract_header(self) -> List[str]:
        return [f"contract {self.name}Test is Test, BlockLoader " + "{"]

    def gen_state_varibles(self) -> List[str]:
        contract_interfaces = [f"{v} {k};" for k, v in self.ctrt_name2cls.items()]
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
            "vm.warp(blockTimestamp);",
            "attacker = address(this);",
            "vm.startPrank(owner);",
        ]

        # Deploy contracts
        for ctrt_name, stmt in self.ctrt_name2deploy:
            # Default deployment
            if stmt == "":
                ctrt_label = self.ctrt_name2cls[ctrt_name]
                if ctrt_label in self.default_erc20_tokens:
                    d_stmt = f"{ctrt_name} = new {ctrt_label}();"

                elif ctrt_label == self.uniswap_pair_ctrt:
                    token0, token1 = self.uniswap_pair2tokens[ctrt_name]
                    d_stmt = f"{ctrt_name} = new {self.uniswap_pair_ctrt}(\
                        address({token0}), address({token1}), \
                        reserve0{ctrt_name}, reserve1{ctrt_name}, \
                        blockTimestampLast{ctrt_name}, kLast{ctrt_name}, \
                        price0CumulativeLast{ctrt_name}, price1CumulativeLast{ctrt_name});"

                elif ctrt_label == self.uniswap_factory_ctrt:
                    pairs = self.uniswap_pairs
                    if len(pairs) > 3:
                        raise ValueError("More than 3 pairs are not supported.")
                    addrs = [
                        f"address({pairs[i]})" if i < len(pairs) else "address(0x0)"
                        for i in range(3)
                    ]
                    params = ["address(0xdead)", *addrs]
                    d_stmt = f'{ctrt_name} = new {self.uniswap_factory_ctrt}({",".join(params)});'

                elif ctrt_label == self.uniswap_router_ctrt:
                    d_stmt = f"{ctrt_name} = new {self.uniswap_router_ctrt}(address(factory), address(0xdead));"
                else:
                    raise CornerCase(f"Unsupported default deployment: {ctrt_label}")
            else:
                d_stmt = f"{ctrt_name} = {stmt};"
            all.append(d_stmt)

        all.extend(self.extra_deployments)

        all.append("// Initialize balances and mock flashloan.")

        # Deploy tokens
        for u in self.token_users:
            addr = f"address({u})" if u != "attacker" else u
            for t in self.erc20_tokens:
                sv_name = f"balanceOf{t}{u}"
                _, val = self.init_states.get(sv_name, ("uint256", "0"))
                if val != "0":
                    stmt = f"{t}.transfer({addr}, {sv_name});"
                    all.append(stmt)

                # Use approve-transfer to mock flashloan
                if u == "attacker":
                    all.append(f"{t}.approve(attacker, UINT256_MAX);")

        all.append("vm.stopPrank();")
        all.append("}")
        return all

    def gen_helper_funcs(self) -> List[str]:
        # Print balance.
        printer = [
            "function printBalance(string memory tips) public {",
            "emit log_string(tips);",
        ]
        for u in self.token_users:
            addr = f"address({u})" if u != "attacker" else u
            printer.append(f'emit log_string("{u.capitalize()} Balances: ");')
            for t in self.erc20_tokens:
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
            f"return {self.attack_goal};",
            "}",
        ]

        nop = ["function nop(uint256 amount) internal pure {", "return;", "}"]

        # Actions
        actions = []
        # flashloan borrow-payback
        for t in self.erc20_tokens:
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
        for u, t in self.uniswap_pair2tokens.items():
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

        # sync uniswap
        for uniswap in self.uniswap_pairs:
            sync = [
                f"function sync_{uniswap}() internal" + "{",
                f"{uniswap}.sync();",
                "}",
            ]
            actions.extend(sync)

        all = [*printer, *attack_goal, *nop, *actions, *self.extra_actions]
        return all

    def gen_gt_for_forge_and_halmos(self) -> List[str]:
        # Build groundtruth test for forge
        test_gt = self.sketch.output_test("test_gt")
        check_gt = self.sketch.symbolic_copy().output(
            "check_gt", self.flashloan_amount, self.extra_constraints
        )
        all = [*test_gt, *check_gt]
        return all

    def gen_candidates(self) -> List[str]:
        synthesizer = Synthesizer(self.config)
        return synthesizer.output_default(self.flashloan_amount, self.extra_constraints)

    def output(self, output_path: str):
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
