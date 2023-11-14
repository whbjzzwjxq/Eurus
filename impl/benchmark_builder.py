import os
import subprocess
from os import path
from typing import Dict, List, Tuple

from .config import Config, init_config
from .dsl import *
from .utils import CornerCase, ATTACK_CONTRACT_CLS
from .synthesizer import Synthesizer


class BenchmarkBuilder:
    """
    Used for building test sol contract to do the test.
    """

    uniswap_pair_ctrt = "UniswapV2Pair"
    uniswap_factory_ctrt = "UniswapV2Factory"
    uniswap_router_ctrt = "UniswapV2Router"
    attack_ctrt_sv = "attackContract"
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

    check_cand_prefix = "check_cand"
    check_gt_prefix = "check_gt"
    test_gt_prefix = "test_gt"

    def __init__(self, bmk_dir: str, sketch_generation: bool = False) -> None:
        self.bmk_dir = bmk_dir
        _, result_path = prepare_subfolder(bmk_dir)
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
        self.extra_deployments_before = self.config.extra_deployments_before
        self.extra_statements = self.config.extra_statements

        # Uniswap pairs.
        self.uniswap_pairs: List[str] = self.config.uniswap_pairs

        # Uniswap pairs to token_names
        self.swap_pair2tokens = self.config.swappair2tokens

        self.uniswap_2tokens = {k: v for k, v in self.swap_pair2tokens.items() if self.roles[k].is_uniswap}

        # ERC20 tokens.
        self.erc20_tokens = self.config.erc20_tokens

        # Map state_variable name to its type and initial value.
        self.init_state: Dict[str, Tuple[str, str]] = {}

        # Collect all public action names.
        self.ava_action_names = []

        # Will print token_users' initial balances.
        self.token_users = list(self.ctrt_name2cls.keys())
        self.token_users.remove("router")
        self.token_users.remove("factory")

        # Lender Pool
        self.lend_pools = self.config.lend_pools

        actions = [init_action_from_list(a, True) for a in self.config.groundtruth]
        self.gt_sketch = Sketch(actions)

        self._init_state()
        self._init_ava_action_names()

        if sketch_generation:
            self.synthesizer = None
        else:
            self.synthesizer = Synthesizer(self.bmk_dir, record=load_record(result_path))


    def _init_state(self):
        # Handle the initial states print by foundry.
        # Look at: QueryBlockchain.sol and query_output_example.txt for more information.
        cache_path, result_path = prepare_subfolder(self.bmk_dir)
        cache_file = path.join(result_path, "_query.cache")
        if path.exists(cache_file):
            with open(cache_file, "r") as f:
                outputs = f.readlines()
                outputs = [l.removesuffix("\n") for l in outputs]
        else:
            cmd = [
                "forge",
                "test",
                "-vv",
                "--cache-path",
                cache_path,
                "--match-path",
                f"{self.bmk_dir}/{self.name}_query.t.sol",
                "--extra-output",
                "storageLayout",
                "metadata",
                "--root",
                os.getcwd(),
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
            self.init_state[sv_name] = (type_str, sv_val)

    def _init_ava_action_names(self):
        actions = self.gen_actions()
        func_name_regex = re.compile(r"function (.*?)\(")
        for l in actions:
            m = func_name_regex.match(l)
            if m:
                func_name = m.group(1)
                self.ava_action_names.append(func_name)

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
        contract_interfaces = []
        for k, v in self.ctrt_name2cls.items():
            if v == ATTACK_CONTRACT_CLS:
                contract_interfaces.append(f"{ATTACK_CONTRACT_CLS} {self.attack_ctrt_sv};")
            else:
                contract_interfaces.append(f"{v} {k};")
        users = [
            f"address owner;",
            f"address attacker;",
            *[f"address {c}Addr;" for c in self.ctrt_names],
        ]
        states = []
        for sv_name, v in self.init_state.items():
            type_str, sv_val = v
            output_str = f"{type_str} {sv_name} = {sv_val};"
            states.append(output_str)
        all = [*contract_interfaces, *users, *states]
        return all

    def gen_setup(self) -> List[str]:
        all = [
            "function setUp() public {",
            "owner = address(this);",
        ]

        # Deploy contracts
        for ctrt_name, stmt in self.ctrt_name2deploy:
            # Default deployment
            if stmt == "":
                ctrt_label = self.ctrt_name2cls[ctrt_name]
                if ctrt_label in self.default_erc20_tokens:
                    d_stmt = f"{ctrt_name} = new {ctrt_label}();"

                elif ctrt_label == self.uniswap_pair_ctrt:
                    token0, token1 = self.uniswap_2tokens[ctrt_name]
                    d_stmt = f"{ctrt_name} = new {self.uniswap_pair_ctrt}(\
                        address({token0}), address({token1}), \
                        reserve0{ctrt_name}, reserve1{ctrt_name}, \
                        blockTimestampLast{ctrt_name}, kLast{ctrt_name}, \
                        price0CumulativeLast{ctrt_name}, price1CumulativeLast{ctrt_name});"

                elif ctrt_label == self.uniswap_factory_ctrt:
                    pairs = self.uniswap_pairs
                    if len(pairs) > 3:
                        raise ValueError("More than 3 pairs are not supported.")
                    addrs = [f"address({pairs[i]})" if i < len(pairs) else "address(0x0)" for i in range(3)]
                    params = ["address(0xdead)", *addrs]
                    d_stmt = f'{ctrt_name} = new {self.uniswap_factory_ctrt}({",".join(params)});'

                elif ctrt_label == self.uniswap_router_ctrt:
                    d_stmt = f"{ctrt_name} = new {self.uniswap_router_ctrt}(address(factory), address(0xdead));"
                elif ctrt_label == ATTACK_CONTRACT_CLS:
                    d_stmt = f"{self.attack_ctrt_sv} = new {ATTACK_CONTRACT_CLS}();"
                else:
                    raise CornerCase(f"Unsupported default deployment: {ctrt_label}")
            else:
                d_stmt = f"{ctrt_name} = {stmt};"
            all.append(d_stmt)
            all.append(f"{ctrt_name}Addr = address({ctrt_name});")

        all.append(f"attacker = address({self.attack_ctrt_sv});")
        all.extend(self.extra_deployments_before)

        all.append("// Initialize balances and mock flashloan.")

        # Deploy tokens
        for u in self.token_users:
            addr = f"address({u})"
            for t in self.erc20_tokens:
                sv_name = f"balanceOf{t}{u}"
                _, val = self.init_state.get(sv_name, ("uint256", "0"))
                if val != "0":
                    stmt = f"{t}.transfer({addr}, {sv_name});"
                    all.append(stmt)

        all.extend(self.extra_deployments)

        all.append("}")
        return all

    def gen_helper_funcs(self) -> List[str]:
        # Action modifier
        action_mod = ["modifier eurus() {", "_;", "}"]

        # Print balance.
        printer = [
            "function printBalance(string memory tips) public {",
            "emit log_string(tips);",
        ]
        for u in self.token_users:
            addr = f"address({u})"
            printer.append(f'emit log_string("{u.capitalize()} Balances: ");')
            for t in self.erc20_tokens:
                printer.append(f"queryERC20BalanceDecimals(address({t}), {addr}, {t}.decimals());")
            printer.append('emit log_string("");')
        printer.append('emit log_string("");')
        printer.append('emit log_string("");')
        printer.append("}")

        # Attack goal
        token, amount = self.attack_goal
        attack_goal_func = [
            "function attackGoal() public view returns (bool) {",
            f"return {token}.balanceOf(attacker) >= {amount} + balanceOf{token}attacker;",
            "}",
        ]

        return [*action_mod, *printer, *attack_goal_func]

    def gen_actions(self) -> List[str]:
        # To distinguish with testing, all actions are modified by internal.
        # Actions
        actions = []
        extra_actions = self.config.extra_actions
        func_name_regex = re.compile(r"function (.*?)\(")
        extra_action_names = set([func_name_regex.match(a).group(1) for a in extra_actions])

        def add_func_to_actions(func_body: str):
            func_name = func_name_regex.match(func_body[0]).group(1)
            if func_name not in extra_action_names:
                actions.extend(func_body)

        # flashloan borrow-payback
        for l in self.lend_pools:
            addr = l if l == "owner" else f"address({l})"
            for t in self.erc20_tokens:
                borrow = [
                    f"function borrow_{t}_{l}(uint256 amount) internal eurus" + "{",
                    f"vm.stopPrank();",
                    f"vm.prank({addr});",
                    f"{t}.transfer(attacker, amount);",
                    f"vm.startPrank(attacker);",
                    "}",
                ]
                payback = [
                    f"function payback_{t}_{l}(uint256 amount) internal eurus" + "{",
                    f"{t}.transfer({addr}, amount);",
                    "}",
                ]
                add_func_to_actions(borrow)
                add_func_to_actions(payback)

        # swap by uniswap
        for u, t in self.uniswap_2tokens.items():
            token0, token1 = t
            swap0 = [
                f"function swap_{u}_attacker_{token0}_{token1}(uint256 amount, uint256 amountOut) internal eurus" + "{",
                f"{token0}.transfer(address({u}), amount);",
                f"{u}.swap(0, amountOut, attacker, new bytes(0));",
                "}",
            ]
            add_func_to_actions(swap0)
            swap1 = [
                f"function swap_{u}_attacker_{token1}_{token0}(uint256 amount, uint256 amountOut) internal eurus" + "{",
                f"{token1}.transfer(address({u}), amount);",
                f"{u}.swap(amountOut, 0, attacker, new bytes(0));",
                "}",
            ]
            add_func_to_actions(swap1)

        return [*actions, *self.extra_actions]

    def gen_gt(self) -> List[str]:
        # Build groundtruth test for forge
        test_gt = self.gt_sketch.output_verify("test_gt", self.extra_statements, print_balance=True)
        check_gt = self.gt_sketch.symbolic_copy().output("check_gt", self.extra_statements)
        all = [*test_gt, *check_gt]
        return all

    def output(self, output_path: str):
        results = [
            *self.gen_imports(),
            *self.gen_contract_header(),
            *self.gen_state_varibles(),
            *self.gen_setup(),
            *self.gen_helper_funcs(),
            *self.gen_actions(),
            *self.gen_gt(),
            "}",
        ]
        with open(output_path, "w") as f:
            for l in results:
                f.write(l)
                f.write("\n")

    def output_with_candidates(self, output_path: str):
        self.synthesizer = Synthesizer(self.bmk_dir, record=None)
        func_bodys: List[str] = []
        for idx, c in enumerate(self.synthesizer.candidates):
            suffix = str(idx).zfill(ZFILL_SIZE)
            func_name = self.check_cand_prefix + suffix
            func_bodys.extend(c.output(func_name, self.extra_statements))
        results = [
            *self.gen_imports(),
            *self.gen_contract_header(),
            *self.gen_state_varibles(),
            *self.gen_setup(),
            *self.gen_helper_funcs(),
            *self.gen_actions(),
            *func_bodys,
            *self.gen_gt(),
            "}",
        ]
        with open(output_path, "w") as f:
            for l in results:
                f.write(l)
                f.write("\n")
        return self.synthesizer.candidates, self.synthesizer.timecost

    def output_verify(self, verifiers: List[Tuple[str, Sketch, List[List[str]]]], output_path: str):
        results = [
            "// SPDX-License-Identifier: MIT",
            "pragma solidity ^0.8.10;",
            f'import "./{self.name}.t.sol";',
            f"contract {self.name}Verify is {self.name}Test" + "{",
        ]
        for func_name, candidate, arg_candidates in verifiers:
            if len(arg_candidates) == 0:
                continue
            for j, args in enumerate(arg_candidates):
                jdx = str(j).zfill(3)
                actual_name = f"test_verify_{func_name}_{jdx}"
                concre_sketch = candidate.concretize(args)
                results.extend(concre_sketch.output_verify(actual_name, self.extra_statements))
        results.extend(["}"])
        with open(output_path, "w") as f:
            for l in results:
                f.write(l)
                f.write("\n")

    def get_sketch_by_func_name(self, func_name: str, candidates: List[Sketch]):
        if func_name == self.check_gt_prefix:
            idx = -1
        else:
            idx = int(func_name.removeprefix("check_cand"))
        sketch = candidates[idx]
        return sketch
