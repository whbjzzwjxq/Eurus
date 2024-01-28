import pickle
import time
from typing import Dict, List

from impl.dsl.dsl import *
from impl.dsl.financial_constraints import *
from impl.toolkit.config import Config, init_config
from impl.toolkit.const import MODIFIER
from impl.toolkit.exceptions import *
from impl.toolkit.utils import *
from impl.toolkit.utils_slither import *

from .token_flow_graph import VOID, TFGManager


class Synthesizer:
    def __init__(self, bmk_dir: str, stored_cache_path: str) -> None:
        self.bmk_dir = bmk_dir
        self.config: Config = init_config(bmk_dir)

        # Grammar Sugars
        self.project_name = self.config.project_name
        self.roles = self.config.roles
        self.contract_infos = self.config.contract_infos
        self.account_infos = self.config.account_infos
        self.attack_goal = self.config.attack_goal

        # Get ground truth
        actions = [init_action_from_list(a, True) for a in self.config.groundtruth]
        self.gt_sketch = Sketch(actions).symbolic_copy()

        # Get Slither IR Object
        self.sli = gen_slither(bmk_dir)
        suffix = "TestBase"
        test_ctrt_name = f"{self.config.project_name}{suffix}"
        self.test_ctrt = self.sli.get_contract_from_name(test_ctrt_name)[0]

        # Get the mapping from the role name to Slither IR Object
        self.role2ctrt = {}
        for role_name, ctrt in self.contract_infos.items():
            ctrt_name = ctrt.cls_name
            for ctrt in self.sli.contracts:
                if ctrt.name == ctrt_name:
                    self.role2ctrt[role_name] = ctrt
        if len(self.contract_infos) != len(self.role2ctrt):
            raise ValueError("Unmatched contract_names and contracts!")

        self.ctrts = list(self.role2ctrt.values())

        # Infer summary for actions.
        self.func_summarys: Dict[str, AFLAction] = {}
        if path.exists(stored_cache_path):
            with open(stored_cache_path, "r") as f:
                self.func_summarys = pickle.load(f)
        else:
            # Infer public actions in the attack contract.
            for func in self.test_ctrt.functions:
                is_foray_action = any(m.full_name == f"{MODIFIER}()" for m in func.modifiers)
                if not is_foray_action:
                    continue
                func_summary = self._summary_action(func)
                self.func_summarys[func_summary.func_sig] = func_summary
            with open(stored_cache_path, "w") as f:
                pickle.dump(self.func_summarys, f)

    def _summary_action(self, func: SliFunction) -> AFLAction:
        args_in_name = func.name.split("_")
        args = [str(a) for a in func.parameters]
        action = init_action_from_list([*args_in_name, *args], False)
        token_flows = self.infer_token_flows(action)
        constraints = self.infer_constraints(action)
        action.update(token_flows, constraints)
        return action

    def infer_candidates(self):
        self.candidates: List[Sketch] = []

        # Generate sketch
        tokens = [VOID] + self.config.assets
        accounts = list(self.account_infos.keys()) + list(self.contract_infos.keys()) + [DEAD]
        func_summarys = list(self.func_summarys.values())
        attack_goal_token, _ = self.attack_goal
        tfg = TFGManager(tokens, accounts, func_summarys, attack_goal_token)

        candidates = tfg.gen_candidates()
        # Remove all candidates after the groundtruth
        gt_idx = -1
        for idx, c in enumerate(candidates):
            if len(c) != len(self.gt_sketch):
                continue
            if c == self.gt_sketch:
                gt_idx = idx
        if gt_idx == -1:
            raise ValueError("Ground truth is not covered by the candidates!")
        return candidates[: gt_idx + 1]

    def infer_token_flows(self, action: AFLAction) -> List[Tokenflow]:
        # We aren't inferring precise token flow here.
        # We are inferring the expected token flows for sketch enumeration.
        if action.action_name == "nop":
            return []
        elif action.action_name == "burn":
            return [Tokenflow(action.token0, action.account, DEAD, "")]
        elif action.action_name == "mint":
            return [Tokenflow(action.token0, DEAD, action.account, "")]
        elif action.action_name == "swap":
            return [
                Tokenflow(action.token0, action.swap_pair, action.account, ""),
                Tokenflow(action.token1, action.account, action.swap_pair, ""),
            ]
        elif action.action_name == "borrow":
            return [Tokenflow(action.token0, action.lender, action.account, "")]
        elif action.action_name == "payback":
            return [Tokenflow(action.token0, action.account, action.lender, "")]
        elif action.action_name == "addliquidity":
            if action.token0 != action.token1:
                return [
                    Tokenflow(action.token0, action.defi, action.swap_pair, ""),
                    Tokenflow(action.token1, action.defi, action.swap_pair, ""),
                ]
            else:
                return [Tokenflow(action.token0, action.defi, action.swap_pair, "")]
        elif action.action_name == "deposit":
            return [
                Tokenflow(action.token0, action.defi, action.account, ""),
                Tokenflow(action.token1, action.account, action.defi, ""),
            ]
        elif action.action_name == "withdraw":
            return [
                Tokenflow(action.token0, action.defi, action.account, ""),
                Tokenflow(action.token1, action.account, action.defi, ""),
            ]
        elif action.action_name == "transaction":
            return []

    def infer_constraints(self, action: AFLAction) -> ACTION_CONSTR:
        cur_hack_constraints = hack_constraints.get(self.config.project_name, {})
        if action.func_sig in cur_hack_constraints:
            return cur_hack_constraints[action.func_sig]
        if action.action_name == "nop":
            return []
        elif action.action_name == "burn":
            return gen_summary_burn(action.account, action.token0, "arg_0")
        elif action.action_name == "mint":
            return gen_summary_mint(action.account, action.token0, "arg_0")
        elif action.action_name == "swap":
            return gen_summary_uniswap(
                action.swap_pair, "attacker", "attacker", action.token0, action.token1, "arg_0", "arg_1"
            )
        elif action.action_name == "borrow":
            return gen_summary_transfer(action.lender, "attacker", action.token0, "arg_0")
        elif action.action_name == "payback":
            return gen_summary_payback("attacker", action.lender, action.token0, "arg_x0", "arg_0")
        elif action.action_name == "addliquidity":
            return []
        elif action.action_name == "deposit":
            return []
        elif action.action_name == "withdraw":
            return []
        elif action.action_name == "transaction":
            return []
