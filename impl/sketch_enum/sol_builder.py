import re
from typing import List

from impl.dsl import Sketch, init_action_from_list
from impl.toolkit.config import Config, init_config
from impl.toolkit.const import ATTACKER
from impl.utils import (ZFILL_SIZE, func_name_regex, load_record,
                        prepare_subfolder)

from .synthesizer import Synthesizer


class BenchmarkBuilder:
    """
    Build *.t.sol contract to enumerate sketch candidates.
    """

    check_cand_prefix = "check_cand"
    check_gt_prefix = "check_gt"
    test_gt_prefix = "test_gt"

    predefined_interfaces = ["IERC20", "IUniswapV2Pair"]

    def __init__(self, bmk_dir: str, sketch_generation: bool = False) -> None:
        self.bmk_dir = bmk_dir
        _, result_path = prepare_subfolder(bmk_dir)
        self.config: Config = init_config(bmk_dir)

        # Grammar Sugars
        self.project_name = self.config.project_name
        self.roles = self.config.roles
        self.contract_infos = self.config.contract_infos
        self.attack_goal = self.config.attack_goal
        self.extra_actions = self.config.extra_actions
        self.uniswap_pairs = self.config.uniswap_pairs
        self.swappair2tokens = self.config.swappair2tokens
        self.uniswap2tokens = self.config.uniswap2tokens
        self.erc20_tokens = self.config.erc20_tokens
        self.lendpools = self.config.lendpools
        self.attacker_addr = self.config.attacker_addr
        self.extra_deployments = self.config.extra_deployments
        self.extra_statements = self.config.extra_statements

        # Get all token users
        self.token_user2addrs = {ATTACKER: ATTACKER}
        for c in self.contract_infos.values():
            if c.interface_name == "":
                self.token_user2addrs[c.name] = c.name
            else:
                self.token_user2addrs[c.name] = f"address({c.name})"

        # Get ground truth
        actions = [init_action_from_list(a, True) for a in self.config.groundtruth]
        self.gt_sketch = Sketch(actions)

        # Collect all public action names.
        self.ava_action_names = self._init_ava_action_names()

        if sketch_generation:
            self.synthesizer = None
        else:
            self.synthesizer = Synthesizer(self.bmk_dir, record=load_record(result_path))

    def _init_ava_action_names(self):
        ava_action_names = []
        actions = self.gen_actions()
        for l in actions:
            m = func_name_regex.match(l)
            if m:
                func_name = m.group(1)
                ava_action_names.append(func_name)
        return ava_action_names

    def gen_imports(self) -> List[str]:
        license = "// SPDX-License-Identifier: MIT"
        pragma = "pragma solidity ^0.8.0;"
        imports = [
            'import "@utils/Helper.sol";',
        ]
        for c in self.contract_infos.values():
            i_name = c.interface_name
            if i_name in self.predefined_interfaces or i_name == "":
                continue
            imports.append(f'import {{{i_name}}} from "./contracts/{i_name}.sol";')
        imports = sorted(imports)
        all = [license, pragma, *imports]
        return all

    def gen_pre_definitions(self, suffix: str) -> List[str]:
        # Contracts
        contract_decl = [f"contract {self.project_name}{suffix} is Test, Helper " + "{"]
        contract_interfaces = []
        for c in self.contract_infos.values():
            if c.interface_name != "":
                s = f"{c.interface_name} {c.name} = {c.interface_name}({c.address});"
            else:
                s = f"address {c.name} = address({c.address});"
            contract_interfaces.append(s)

        # Attackers

        attack_goal_token, attack_goal_amt = self.attack_goal
        init_balance_attacker_sv = f"balanceOf{attack_goal_token}{ATTACKER}"
        balance_attacker_sv = f"{attack_goal_token}.balanceOf({ATTACKER})"
        attacker_svs = [
            f"uint256 {init_balance_attacker_sv};",
        ]

        state_variables = [*contract_interfaces, *attacker_svs]

        # The modifier used to identify actions in Slither IR.
        action_mod = [
            "modifier foray() {",
            "_;",
            "}",
        ]

        mods = [*action_mod]

        # Setup
        setup_func = [
            "function setUp() public {",
            *self.extra_deployments,
            f"{init_balance_attacker_sv} = {balance_attacker_sv};",
            "}",
        ]

        # Print balance.
        print_content = [
            f"address[] memory token_addrs = new address[]({len(self.erc20_tokens)});",
            f"string[] memory token_names = new string[]({len(self.erc20_tokens)});",
            f"address[] memory user_addrs = new address[]({len(self.token_user2addrs)});",
            f"string[] memory user_names = new string[]({len(self.token_user2addrs)});",
        ]
        i = 0
        for name in self.erc20_tokens:
            s0 = f"token_addrs[{i}] = address({name});"
            s1 = f"token_names[{i}] = \"{name}\";"
            print_content.append(s0)
            print_content.append(s1)
            i += 1
        i = 0
        for name, addr in self.token_user2addrs.items():
            s0 = f"user_addrs[{i}] = {addr};"
            s1 = f"user_names[{i}] = \"{name}\";"
            print_content.append(s0)
            print_content.append(s1)
            i += 1
        print_func = [
            "function printBalance(string memory tips) public {",
            "emit log_string(tips);",
            *print_content,
            "queryERC20BalanceBatch(token_addrs, token_names, user_addrs, user_names);",
            "}",
        ]

        # Attack goal
        attack_goal_func = [
            "function attackGoal() public view returns (bool) {",
            f"return {balance_attacker_sv} >= {attack_goal_amt} + {init_balance_attacker_sv};",
            "}",
        ]

        helper_funcs = [*setup_func, *print_func, *attack_goal_func]

        return [*contract_decl, *state_variables, *mods, *helper_funcs]

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
        for l in self.lendpools:
            addr = f"address({l})"
            for t in self.erc20_tokens:
                borrow = [
                    f"function borrow_{t}_{l}(uint256 amount) internal foray" + "{",
                    f"vm.stopPrank();",
                    f"vm.prank({addr});",
                    f"{t}.transfer(attacker, amount);",
                    f"vm.startPrank(attacker);",
                    "}",
                ]
                payback = [
                    f"function payback_{t}_{l}(uint256 amount) internal foray" + "{",
                    f"{t}.transfer({addr}, amount);",
                    "}",
                ]
                add_func_to_actions(borrow)
                add_func_to_actions(payback)

        # swap by uniswap
        for u, t in self.uniswap2tokens.items():
            token0, token1 = t
            swap0 = [
                f"function swap_{u}_attacker_{token0}_{token1}(uint256 amount, uint256 amountOut) internal foray" + "{",
                f"{token0}.transfer(address({u}), amount);",
                f"{u}.swap(0, amountOut, attacker, new bytes(0));",
                "}",
            ]
            add_func_to_actions(swap0)
            swap1 = [
                f"function swap_{u}_attacker_{token1}_{token0}(uint256 amount, uint256 amountOut) internal foray" + "{",
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
            *self.gen_pre_definitions("TestBase"),
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
            *self.gen_pre_definitions("Test"),
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

    def get_sketch_by_func_name(self, func_name: str, candidates: List[Sketch]):
        if func_name == self.check_gt_prefix:
            idx = -1
        else:
            idx = int(func_name.removeprefix("check_cand"))
        sketch = candidates[idx]
        return sketch
