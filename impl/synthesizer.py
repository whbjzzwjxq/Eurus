import itertools
from enum import Enum
from hashlib import sha3_256
from typing import Iterable, List

import pandas as pd

from impl.utils import List

from .defi import Defi
from .utils import *
from .utils_slither import *
from .config import Config


class SolCallType(Enum):
    # payable(address).transfer(...)
    INTRINSIC = 0

    # _internalTransfer(addr1, addr2, amt)
    INTERNAL = 1

    # Token.transfer(addr1, amt)
    EXTERNAL = 2


class SolFunction:
    def __init__(
        self, ctrt_name: str, func_name: str, func_types: List[SliElementaryType]
    ):
        self.ctrt_name = ctrt_name
        self.func_name = func_name
        self.func_types = func_types
        self.func_type_strs = [str(t) for t in self.func_types]

    @property
    def func_signature(self):
        func_types_str = ",".join(self.func_types)
        return f"{self.func_name}({func_types_str})"

    @property
    def keccak_hash(self):
        return sha3_256(self.func_signature.encode("utf-8")).hexdigest()

    @property
    def canonical_name(self):
        func_types_str = ",".join(self.func_types)
        return f"{self.ctrt_name}.{self.func_name}({func_types_str})"

    @property
    def name(self):
        return self.canonical_name

    def __hash__(self) -> int:
        return hash(self.canonical_name)

    def __str__(self) -> str:
        return self.canonical_name

    def __eq__(self, __value: object) -> bool:
        return hash(self) == hash(__value)


class ConcreteSolFunction(SolFunction):
    def __init__(
        self,
        ctrt_name: str,
        func_name: str,
        func_types: List[SliElementaryType],
        func_args: list,
    ) -> None:
        super().__init__(ctrt_name, func_name, func_types)
        not_none_args = [f for f in func_args if f is not None]
        if len(not_none_args) == 0:
            raise ValueError("At least one value shall be concrete.")
        self.is_partial = len(not_none_args) < len(func_args)
        self.func_args = func_args

    @property
    def concrete_name(self):
        vs = [v if v is not None else "_" for v in self.func_args]
        func_args_str = ",".join(vs)
        return f"{self.ctrt_name}.{self.func_name}({func_args_str})"


class Candidate:
    def __init__(self, funcs: Iterable[SliFunction], index: int) -> None:
        self.funcs = list(funcs)
        self.index = index

    def __str__(self) -> str:
        return " => ".join([f.canonical_name for f in self.funcs])


class OldSynthesizer:
    def __init__(self, defi: Defi):
        self.defi = defi
        self.max_steps = len(defi.config.groundtruth)
        if self.max_steps == 0:
            raise ValueError("No groundtruth is provided!")
        self.actions_count = len(self.defi.pub_actions)
        if self.actions_count == 0:
            raise ValueError("No actions is provided!")
        self.candidates_count = self._init_candidates_count()

    def _init_candidates_count(self):
        last = 1
        count = 0
        for _ in range(self.max_steps):
            last *= self.actions_count
            count += last
        return count

    def iter_candidate(self) -> Iterable[Candidate]:
        i = 0
        for s in range(1, self.max_steps + 1):
            candidates = itertools.product(self.defi.pub_actions, repeat=s)
            for c in candidates:
                i += 1
                yield Candidate(funcs=c, index=i)

    def pruned_by_gsv(self, candidate: Candidate) -> bool:
        # RW Pruning
        sv_interested = set()
        for sv_name in self.defi.config.attack_state_variables:
            ctrt_name, var_name = sv_name.split(".")
            sv = self.defi.get_variable_by_name(ctrt_name, var_name)
            if sv is None:
                raise ValueError(f"Unknown state variable name: {sv_name}")
            sv_interested.add(sv)
        for sli_func in reversed(candidate.funcs):
            sv_read, sv_written = self.defi.get_func_rw_set(sli_func)
            if not sv_written.intersection(sv_interested):
                return True
            # Not sound yet
            # sv_interested -= sv_written
            sv_interested_new = set()
            for sv_w in sv_written:
                for sv_r in sv_read:
                    if is_dependent(sv_w, sv_r, sli_func):
                        sv_interested_new.add(sv_r)
                    # Hacking
                    if sv_r.name == "_owner":
                        sv_interested_new.add(sv_r)
            sv_interested = sv_interested.union(sv_interested_new)
        return False

    def pruned_by_ai(self, candidate: Candidate) -> bool:
        # AI Pruning, Hacking
        for i in reversed(range(0, len(candidate.funcs) - 1)):
            sli_func = candidate.funcs[i]
            target_ctrts: List[SliContract] = []
            if sli_func.name == "transferFrom":
                target_ctrts = [sli_func.contract]
            else:
                ext_calls = self.defi.ext_calls.get(sli_func.canonical_name, [])
                for e_call in ext_calls:
                    if e_call.name == "transferFrom":
                        target_ctrts.append(e_call.contract)
            if len(target_ctrts) == 0:
                continue
            if i == 0:
                return True
            approved = True
            before = candidate.funcs[0 : i - 1]
            for ctrt in target_ctrts:
                approve_func = self.defi.get_function_by_name(ctrt, "approve")
                if approve_func is None:
                    raise ValueError("Error IERC20 contract.")
                if approve_func not in before:
                    approved = False
            if not approved:
                return True

    def is_groundtruth(self, candidate: Candidate) -> bool:
        return self.defi.is_groundtruth(candidate.funcs)

    def mock_eval(self, output_path: str):
        i = 0
        df = pd.DataFrame(
            columns=["index", "candidate", "pruned_by_rw", "pruned_by_ai"]
        )
        for c in self.iter_candidate():
            i += 1
            if self.pruned_by_gsv(c):
                df.loc[len(df.index)] = [i, str(c), True, False]
            elif self.pruned_by_ai(c):
                df.loc[len(df.index)] = [i, str(c), False, True]
            else:
                df.loc[len(df.index)] = [i, str(c), False, False]
            if self.is_groundtruth(c):
                break
        df.loc[len(df.index)] = [
            i,
            "Sum",
            df["pruned_by_rw"].sum(),
            df["pruned_by_ai"].sum(),
        ]
        df.to_csv(output_path, index=False)


class ArgumentType(Enum):
    Asset = 0
    SwapPair = 1
    DeFiEntry = 2
    UINT256 = 3


class DSLAction:
    def __init__(
        self, action_name: str, args_in_name: List[str], args: List[str]
    ) -> None:
        self.action_name = action_name
        self.args_in_name = args_in_name
        self.args = args

    def __eq__(self, __value: "DSLAction") -> bool:
        if self.action_name == "nop" and __value.action_name == "nop":
            return True
        return (
            (self.action_name == __value.action_name)
            and (self.args_in_name == __value.args_in_name)
            and (self.args == __value.args)
        )

    def __str__(self) -> str:
        func_names = "_".join([self.action_name, *self.args_in_name])
        arg_names = ", ".join(self.args)
        return f"{func_names}({arg_names})"


class NOP(DSLAction):
    def __init__(self, args_in_name: List[str], args: List[str]) -> None:
        super().__init__("nop", args_in_name, args)


class Swap(DSLAction):
    def __init__(self, swap_pair: str, asset0: str, asset1: str, amount: str) -> None:
        if asset0 == asset1:
            super().__init__("nop", [], [amount])
            return
        super().__init__("swap", [swap_pair, asset0, asset1], [amount])
        self.swap_pair = swap_pair
        self.asset0 = asset0
        self.asset1 = asset1
        self.amount = amount


class Borrow(DSLAction):
    def __init__(self, asset: str, amount: str) -> None:
        super().__init__("borrow", [asset], [amount])


class Payback(DSLAction):
    def __init__(self, asset: str, amount: str) -> None:
        super().__init__("payback", [asset], [amount])


class HackedAction(DSLAction):
    def __init__(self, defi_entry: str, asset_hacked: str, amount: str) -> None:
        super().__init__("hackedAction", [defi_entry, asset_hacked], [amount])


class Sketch:
    def __init__(self, actions: List[DSLAction]) -> None:
        self.actions = actions

    @property
    def len(self):
        return self.actions.__len__()

    @property
    def pure_len(self):
        return self.pure_actions.__len__()

    @property
    def pure_actions(self):
        return [a for a in self.actions if a.action_name != "nop"]

    def __eq__(self, __value: "Sketch") -> bool:
        if self.pure_len != __value.pure_len:
            return False
        pa0 = self.pure_actions
        pa1 = __value.pure_actions
        sames = [a == b for a, b in zip(pa0, pa1)]
        return all(sames)


class Synthesizer:
    def __init__(self, config: Config):
        self.config = config
        self.roles = self.config.roles

    def check_duplicated(self, actions: Sketch, candidates: List[Sketch]) -> bool:
        return any([actions == c for c in candidates])

    def output(self) -> List[str]:
        if self.config.pattern == "Price Discrepancy":
            return self.gen_candidate_template_pricediscrepancy()
        if self.config.pattern == "BuySell Manipulation":
            return self.gen_candidate_template_buysell()
        raise CornerCase("Unknown pattern!")

    def gen_candidate_template_pricediscrepancy(self) -> List[str]:
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]

        candidates: List[Sketch] = []
        for (
            asset0,
            swap_pair0,
            asset1,
            swap_pair1,
            swap_pair2,
            stable_coin,
            swap_pair3,
        ) in itertools.product(
            assets, swap_pairs, assets, swap_pairs, swap_pairs, stable_coins, swap_pairs
        ):
            if asset0 == asset1:
                continue

            # SwapPair 0
            if asset1 not in self.roles[swap_pair0].support_swaps.get(asset0, []):
                continue

            # SwapPair 1
            if asset0 not in self.roles[swap_pair1].support_swaps.get(asset1, []):
                continue

            # SwapPair 2
            if stable_coin not in self.roles[swap_pair2].support_swaps.get(asset0, []):
                continue

            # SwapPair 3
            if stable_coin not in self.roles[swap_pair3].support_swaps.get(asset1, []):
                continue

            actions0: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                Swap(swap_pair1, asset1, asset0, "amt2"),
                Payback(asset0, "amt5"),
            ]

            actions1: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                Swap(swap_pair1, asset1, asset0, "amt2"),
                Swap(swap_pair3, asset1, stable_coin, "amt4"),
                Payback(asset0, "amt5"),
            ]

            actions2: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                Swap(swap_pair1, asset1, asset0, "amt2"),
                Swap(swap_pair2, asset0, stable_coin, "amt3"),
                Payback(asset0, "amt5"),
            ]

            actions3: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                Swap(swap_pair1, asset1, asset0, "amt2"),
                Swap(swap_pair2, asset0, stable_coin, "amt3"),
                Swap(swap_pair3, asset1, stable_coin, "amt4"),
                Payback(asset0, "amt5"),
            ]

            skecthes = [
                Sketch(actions0),
                Sketch(actions1),
                Sketch(actions2),
                Sketch(actions3),
            ]

            for s in skecthes:
                if not self.check_duplicated(s, candidates):
                    candidates.append(s)

        candidates = sorted(candidates, key=lambda s: s.pure_len)
        func_bodys = []

        params = [f"uint256 amt{i}" for i in range(self.config.total_amt)]

        for idx, c in enumerate(candidates):
            func_body = [f"{str(s)};" for s in c.pure_actions]
            checker = [
                f'function check_cand{idx}({",".join(params)}) public ' + "{",
                *[f"vm.assume({c});" for c in self.config.constraints],
                *func_body,
                "assert(!attackGoal());",
                "}",
            ]
            func_bodys.extend(checker)
        return func_bodys

    def gen_candidate_template_buysell(self) -> List[str]:
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
        defi_entrys = [k for k, v in self.roles.items() if v.is_defientry]
        hacked_defi = [k for k, v in self.roles.items() if v.hacked_assets]

        if len(hacked_defi) == 0:
            return []

        candidates = []
        for (
            asset0,
            swap_pair0,
            asset1,
            defi_entry,
            asset_hacked,
            swap_pair1,
            swap_pair2,
            stable_coin,
            swap_pair3,
        ) in itertools.product(
            assets,
            swap_pairs,
            assets,
            defi_entrys,
            assets,
            swap_pairs,
            swap_pairs,
            stable_coins,
            swap_pairs,
        ):
            actions: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                HackedAction(defi_entry, asset_hacked, "amt2"),
                Swap(swap_pair1, asset1, asset0, "amt3"),
                Swap(swap_pair2, asset_hacked, stable_coin, "amt4"),
                Swap(swap_pair3, stable_coin, asset0, "amt5"),
                Payback(asset0, "amt6"),
            ]
            if asset0 == asset1:
                continue
            # SwapPair 0
            if asset1 not in self.roles[swap_pair0].support_swaps.get(asset0, []):
                continue

            # SwapPair 1
            if asset0 not in self.roles[swap_pair1].support_swaps.get(asset1, []):
                continue

            # SwapPair 2
            if stable_coin not in self.roles[swap_pair2].support_swaps.get(
                asset_hacked, []
            ):
                continue

            # SwapPair 3
            if asset0 not in self.roles[swap_pair3].support_swaps.get(stable_coin, []):
                continue

            # DeFi
            if asset_hacked not in self.roles[defi_entry].hacked_assets:
                continue

            if not self.check_duplicated(actions, candidates):
                candidates.append(actions)

        func_bodys = []
        total_parameters = 6

        for idx, c in enumerate(candidates):
            action_str = "".join([f"{str(s)};\n" for s in c])
            constraint_str = "".join(
                [f"vm.assume({c});\n" for c in self.config.constraints]
            )
            func_body = f"""
                function check_cand{idx}(
                    uint256 amt0,
                    uint256 amt1,
                    uint256 amt2,
                    uint256 amt3,
                    uint256 amt4,
                    uint256 amt5,
                    uint256 amt6) public {{
                        {constraint_str + action_str}
                        assert(!attackGoal());
                    }}

            """
            func_bodys.append(func_body)
        return func_bodys
