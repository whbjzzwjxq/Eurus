from typing import List, Optional

from .utils import Config, init_config
from .utils_slither import SliContract, SliFunction, gen_slither


class Defi:
    def __init__(self, bmk_dir: str) -> None:
        self.config: Config = init_config(bmk_dir)
        self.ctrt_names = self.config.contract_names
        self.sli = gen_slither(bmk_dir)
        self.ctrts = self._init_ctrts()
        self.test_ctrt = self.sli.get_contract_from_name(f"{self.config.project_name}Test")[0]
        self.pub_actions_in_defi = self._init_pub_actions()

    def _init_ctrts(self) -> List[SliContract]:
        actual_ctrts = []
        for ctrt_name in self.ctrt_names:
            for ctrt in self.sli.contracts:
                if ctrt.name == ctrt_name:
                    actual_ctrts.append(ctrt)
        if len(self.ctrt_names) != len(actual_ctrts):
            raise ValueError("Unmatched contract_names and contracts!")
        return actual_ctrts

    def _init_pub_actions(self) -> List[SliFunction]:
        pub_actions = []
        for ctrt in self.ctrts:
            for f in ctrt.functions:
                if f.is_constructor or f.is_constructor_variables or not f.is_implemented:
                    continue
                if f.pure or f.view or f.visibility in ("internal", "private"):
                    continue
                pub_actions.append(f)
        return pub_actions

    def get_contract_by_name(self, name: str):
        for ctrt in self.ctrts:
            if ctrt.name == name:
                return ctrt
        return None

    def _get_function_by_name(self, ctrt: SliContract, name: str) -> Optional[SliFunction]:
        return next(
            (
                f
                for f in ctrt.functions
                if f.name ==
                # Make sure it is the implementation instead of interface
                name and f.canonical_name.startswith(ctrt.name)
            ),
            None,
        )

    def get_function_by_name(self, ctrt_name: str, func_name: str):
        ctrt = self.get_contract_by_name(ctrt_name)
        if ctrt is None:
            raise ValueError(f"Unknown contract name: {ctrt_name}")
        return self._get_function_by_name(ctrt, func_name)

    def get_variable_by_name(self, ctrt_name: str, var_name: str):
        ctrt = self.get_contract_by_name(ctrt_name)
        if ctrt is None:
            raise ValueError(f"Unknown contract name: {ctrt_name}")
        for sv in ctrt.state_variables:
            if sv.name == var_name:
                return sv
        return None

    def get_function_by_canonical_name(self, canonical_name: str, method_name: str):
        # Precise finding.
        tgt_ctrt_name = self.config.contract_names_mapping.get(canonical_name, None)
        tgt_ctrt = self.get_contract_by_name(tgt_ctrt_name)
        if tgt_ctrt is None:
            return None
        return self._get_function_by_name(tgt_ctrt, method_name)

    def get_function_by_interface(self, interface: SliContract, method_name: str):
        possible_funcs = []
        for ctrt in self.ctrts:
            for inter in ctrt.inheritance:
                if interface.name == inter.name:
                    res = self.get_function_by_name(ctrt, method_name)
                    if res is None:
                        continue
                    possible_funcs.append(res)
        return possible_funcs

    def get_function_by_method_name(self, method_name: str):
        # Imprecise finding.
        possible_funcs = []
        for ctrt in self.ctrts:
            res = self.get_function_by_name(ctrt, method_name)
            if res is None:
                continue
            possible_funcs.append(res)
        return possible_funcs

    def is_groundtruth(self, candidate: List[SliFunction]) -> bool:
        if len(candidate) != len(self.config.groundtruth):
            return False
        else:
            for f1, f2 in zip(candidate, self.config.groundtruth):
                f1_ctrt_name = f1.contract.name
                f1_func_name = f1.name
                f2_ctrt_name, f2_func_name = f2.split(".")
                if f1_ctrt_name != f2_ctrt_name or f1_func_name != f2_func_name:
                    return False
            return True
