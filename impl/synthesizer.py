import itertools
from enum import Enum
from hashlib import sha3_256
from typing import Iterable, List

import pandas as pd

from .defi import Defi
from .utils import *
from .utils_slither import *


class SolCallType(Enum):
    # payable(address).transfer(...)
    INTRINSIC = 0

    # _internalTransfer(addr1, addr2, amt)
    INTERNAL = 1

    # Token.transfer(addr1, amt)
    EXTERNAL = 2


class SolFunction:
    def __init__(self, ctrt_name: str, func_name: str, func_types: List[SliElementaryType]):
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
        return sha3_256(self.func_signature.encode('utf-8')).hexdigest()

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

    def __init__(self, ctrt_name: str, func_name: str, func_types: List[SliElementaryType], func_args: list) -> None:
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

    def __init__(self, funcs: Iterable[SolFunction]) -> None:
        self.funcs = list(funcs)

    def __str__(self) -> str:
        return " => ".join([f.canonical_name for f in self.funcs])


class Synthesizer:

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
        for s in range(1, self.max_steps + 1):
            candidates = itertools.product(self.defi.pub_actions, repeat=s)
            for c in candidates:
                yield Candidate(funcs=c)

    def pruned_by_rw(self, candidate: Candidate) -> bool:
        # RW Pruning
        sv_written = set()
        for func in candidate.funcs:
            sv_written = sv_written.union(self.defi.get_func_rw_set(func)[1])
        return not self.defi.analyze_rw(sv_written)
    
    def pruned_by_idempotency(self, candidate: Candidate) -> bool:
        # It is not the sound version, we just do the rough mock.
        for i in range(0, len(candidate.funcs) - 1):
            cur = candidate.funcs[i]
            nxt = candidate.funcs[i + 1]
            if cur == nxt:
                return True
        return False

    def is_groundtruth(self, candidate: Candidate) -> bool:
        return self.defi.is_groundtruth(candidate.funcs)

    def mock_eval(self, output_path: str):
        i = 0
        df = pd.DataFrame(columns=["index", "candidate", "pruned_by_rw", "pruned_by_idempotency"])
        for c in self.iter_candidate():
            df.loc[len(df.index)] = [i, str(c), self.pruned_by_rw(c), self.pruned_by_idempotency(c)]
            if self.is_groundtruth(c):
                break
            i += 1
        df.loc[len(df.index)] = [i, "Sum", df["pruned_by_rw"].sum(), df["pruned_by_idempotency"].sum()]
        df.to_csv(output_path, index=False)
