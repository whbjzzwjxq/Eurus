import itertools
from typing import List, Tuple

from impl.utils import List

from .utils import *
from .utils_slither import *
from .config import Config

from .dsl import *

# class SolCallType(Enum):
#     # payable(address).transfer(...)
#     INTRINSIC = 0

#     # _internalTransfer(addr1, addr2, amt)
#     INTERNAL = 1

#     # Token.transfer(addr1, amt)
#     EXTERNAL = 2


# class SolFunction:
#     def __init__(
#         self, ctrt_name: str, func_name: str, func_types: List[SliElementaryType]
#     ):
#         self.ctrt_name = ctrt_name
#         self.func_name = func_name
#         self.func_types = func_types
#         self.func_type_strs = [str(t) for t in self.func_types]

#     @property
#     def func_signature(self):
#         func_types_str = ",".join(self.func_types)
#         return f"{self.func_name}({func_types_str})"

#     @property
#     def keccak_hash(self):
#         return sha3_256(self.func_signature.encode("utf-8")).hexdigest()

#     @property
#     def canonical_name(self):
#         func_types_str = ",".join(self.func_types)
#         return f"{self.ctrt_name}.{self.func_name}({func_types_str})"

#     @property
#     def name(self):
#         return self.canonical_name

#     def __hash__(self) -> int:
#         return hash(self.canonical_name)

#     def __str__(self) -> str:
#         return self.canonical_name

#     def __eq__(self, __value: object) -> bool:
#         return hash(self) == hash(__value)


# class ConcreteSolFunction(SolFunction):
#     def __init__(
#         self,
#         ctrt_name: str,
#         func_name: str,
#         func_types: List[SliElementaryType],
#         func_args: list,
#     ) -> None:
#         super().__init__(ctrt_name, func_name, func_types)
#         not_none_args = [f for f in func_args if f is not None]
#         if len(not_none_args) == 0:
#             raise ValueError("At least one value shall be concrete.")
#         self.is_partial = len(not_none_args) < len(func_args)
#         self.func_args = func_args

#     @property
#     def concrete_name(self):
#         vs = [v if v is not None else "_" for v in self.func_args]
#         func_args_str = ",".join(vs)
#         return f"{self.ctrt_name}.{self.func_name}({func_args_str})"


# class Candidate:
#     def __init__(self, funcs: Iterable[SliFunction], index: int) -> None:
#         self.funcs = list(funcs)
#         self.index = index

#     def __str__(self) -> str:
#         return " => ".join([f.canonical_name for f in self.funcs])


# class OldSynthesizer:
#     def __init__(self, defi: Defi):
#         self.defi = defi
#         self.max_steps = len(defi.config.groundtruth)
#         if self.max_steps == 0:
#             raise ValueError("No groundtruth is provided!")
#         self.actions_count = len(self.defi.pub_actions)
#         if self.actions_count == 0:
#             raise ValueError("No actions is provided!")
#         self.candidates_count = self._init_candidates_count()

#     def _init_candidates_count(self):
#         last = 1
#         count = 0
#         for _ in range(self.max_steps):
#             last *= self.actions_count
#             count += last
#         return count

#     def iter_candidate(self) -> Iterable[Candidate]:
#         i = 0
#         for s in range(1, self.max_steps + 1):
#             candidates = itertools.product(self.defi.pub_actions, repeat=s)
#             for c in candidates:
#                 i += 1
#                 yield Candidate(funcs=c, index=i)

#     def pruned_by_gsv(self, candidate: Candidate) -> bool:
#         # RW Pruning
#         sv_interested = set()
#         for sv_name in self.defi.config.attack_state_variables:
#             ctrt_name, var_name = sv_name.split(".")
#             sv = self.defi.get_variable_by_name(ctrt_name, var_name)
#             if sv is None:
#                 raise ValueError(f"Unknown state variable name: {sv_name}")
#             sv_interested.add(sv)
#         for sli_func in reversed(candidate.funcs):
#             sv_read, sv_written = self.defi.get_func_rw_set(sli_func)
#             if not sv_written.intersection(sv_interested):
#                 return True
#             # Not sound yet
#             # sv_interested -= sv_written
#             sv_interested_new = set()
#             for sv_w in sv_written:
#                 for sv_r in sv_read:
#                     if is_dependent(sv_w, sv_r, sli_func):
#                         sv_interested_new.add(sv_r)
#                     # Hacking
#                     if sv_r.name == "_owner":
#                         sv_interested_new.add(sv_r)
#             sv_interested = sv_interested.union(sv_interested_new)
#         return False

#     def pruned_by_ai(self, candidate: Candidate) -> bool:
#         # AI Pruning, Hacking
#         for i in reversed(range(0, len(candidate.funcs) - 1)):
#             sli_func = candidate.funcs[i]
#             target_ctrts: List[SliContract] = []
#             if sli_func.name == "transferFrom":
#                 target_ctrts = [sli_func.contract]
#             else:
#                 ext_calls = self.defi.ext_calls.get(sli_func.canonical_name, [])
#                 for e_call in ext_calls:
#                     if e_call.name == "transferFrom":
#                         target_ctrts.append(e_call.contract)
#             if len(target_ctrts) == 0:
#                 continue
#             if i == 0:
#                 return True
#             approved = True
#             before = candidate.funcs[0 : i - 1]
#             for ctrt in target_ctrts:
#                 approve_func = self.defi.get_function_by_name(ctrt, "approve")
#                 if approve_func is None:
#                     raise ValueError("Error IERC20 contract.")
#                 if approve_func not in before:
#                     approved = False
#             if not approved:
#                 return True

#     def is_groundtruth(self, candidate: Candidate) -> bool:
#         return self.defi.is_groundtruth(candidate.funcs)

#     def mock_eval(self, output_path: str):
#         i = 0
#         df = pd.DataFrame(
#             columns=["index", "candidate", "pruned_by_rw", "pruned_by_ai"]
#         )
#         for c in self.iter_candidate():
#             i += 1
#             if self.pruned_by_gsv(c):
#                 df.loc[len(df.index)] = [i, str(c), True, False]
#             elif self.pruned_by_ai(c):
#                 df.loc[len(df.index)] = [i, str(c), False, True]
#             else:
#                 df.loc[len(df.index)] = [i, str(c), False, False]
#             if self.is_groundtruth(c):
#                 break
#         df.loc[len(df.index)] = [
#             i,
#             "Sum",
#             df["pruned_by_rw"].sum(),
#             df["pruned_by_ai"].sum(),
#         ]
#         df.to_csv(output_path, index=False)


class Synthesizer:
    def __init__(self, config: Config):
        self.config = config
        self.roles = self.config.roles
        if self.config.pattern == "BuySell Manipulation":
            candidates = self.gen_candidates_buysell()
        elif self.config.pattern == "Price Discrepancy":
            candidates = self.gen_candidates_pricediscrepancy()
        elif self.config.pattern == "Token Burn":
            candidates = self.gen_candidates_tokenburn()
        else:
            raise CornerCase(f"Unknown pattern: {self.config.pattern}!")
        self.candidates: List[Sketch] = candidates

    def check_duplicated(self, sketch: Sketch, candidates: List[Sketch]) -> bool:
        return any([sketch == c for c in candidates])

    def extend_candidates_from_template(
        self,
        template: List[DSLAction],
        template_times: List[int],
        exist_candidates: List[Sketch],
    ):
        sketches: List[Sketch] = []
        for times in itertools.product(*template_times):
            actions = []
            for i in range(len(template)):
                t = times[i]
                actions.extend([template[i]] * t)
            # Rename parameters
            sketch = Sketch(actions).symbolic_copy()
            sketches.append(sketch)

        for s in sketches:
            if not s.check_implemented(self.roles):
                continue
            if self.check_duplicated(s, exist_candidates):
                continue
            exist_candidates.append(s)

    def output_default(
        self, flashloan_amount: Decimal, constraints: List[str]
    ) -> List[str]:
        candidates = sorted(self.candidates, key=lambda s: s.pure_len)
        func_bodys: List[str] = []
        for idx, c in enumerate(candidates):
            func_bodys.extend(
                c.output(f"check_cand{idx}", flashloan_amount, constraints)
            )
        return func_bodys

    def gen_candidates_buysell(self) -> List[Sketch]:
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
        defi_entrys = [k for k, v in self.roles.items() if v.is_defientry]
        candidates: List[Sketch] = []
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
            if asset0 == asset1:
                continue

            template: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                Transaction(defi_entry, asset_hacked, "amt2"),
                Swap(swap_pair1, asset1, asset0, "amt3"),
                Swap(swap_pair2, asset_hacked, stable_coin, "amt4"),
                Swap(swap_pair3, stable_coin, asset0, "amt5"),
                Payback(asset0, "amt6"),
            ]

            template_times = [
                (1,),
                (1,),
                (1,),
                (1,),
                (1,),
                (1,),
                (1,),
            ]

            self.extend_candidates_from_template(template, template_times, candidates)

        return candidates

    def gen_candidates_pricediscrepancy(self) -> Tuple[List[DSLAction], List[int]]:
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

            template: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                Swap(swap_pair1, asset1, asset0, "amt2"),
                Swap(swap_pair2, asset0, stable_coin, "amt3"),
                Swap(swap_pair3, asset1, stable_coin, "amt4"),
                Payback(asset0, "amt5"),
            ]

            template_times = [
                (1,),
                (1,),
                (1,),
                (0, 1),
                (0, 1),
                (1,),
            ]
            self.extend_candidates_from_template(template, template_times, candidates)

        return candidates

    def gen_candidates_tokenburn(self) -> List[Sketch]:
        assets = [k for k, v in self.roles.items() if v.is_asset]
        stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
        swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
        oracles = [k for k, v in self.roles.items() if v.is_oracle]

        candidates: List[Sketch] = []
        for (
            asset0,
            swap_pair0,
            asset1,
            oracle,
            swap_pair1,
            swap_pair2,
            stable_coin,
        ) in itertools.product(
            assets, swap_pairs, assets, oracles, swap_pairs, swap_pairs, stable_coins
        ):
            if asset0 == asset1:
                continue

            template: List[DSLAction] = [
                Borrow(asset0, "amt0"),
                Swap(swap_pair0, asset0, asset1, "amt1"),
                Burn(oracle, asset1, "amt2"),
                Sync(oracle),
                Swap(swap_pair0, asset1, asset0, "amt3"),
                Swap(swap_pair1, asset0, stable_coin, "amt4"),
                Swap(swap_pair2, asset1, stable_coin, "amt5"),
                Payback(asset0, "amt6"),
            ]
            template_times = [
                (1,),
                (1,),
                # Use 5 to replace maxmium loop.
                [i for i in range(5)],
                (0, 1),
                (1,),
                (0, 1),
                (0, 1),
                (1,),
            ]
            self.extend_candidates_from_template(template, template_times, candidates)

        return candidates
