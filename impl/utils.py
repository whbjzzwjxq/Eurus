import json
from dataclasses import dataclass, field
from os import path
from typing import Dict, List, Tuple

from manticore.ethereum import ABI, EVMAccount, ManticoreEVM, EVMContract
from manticore.ethereum.state import State as MTState
from manticore.exceptions import NoAliveStates, SolverUnknown
from manticore.core.state import Concretize
from manticore.utils.log import set_verbosity
from slither.core.declarations.contract import Contract as SliContract
from slither.core.declarations.function import Function as SliFunction
from slither.core.declarations.solidity_variables import \
    SolidityFunction as SolFunction
from slither.core.variables.variable import Variable as SliVariable
from slither.core.variables.state_variable import StateVariable as SliStateVariable

ether = 10 ** 18
gwei = 10 ** 10

set_verbosity(0)


@dataclass
class Config:
    project_name: str
    contracts: Dict[str, List[str]]
    attack_goal: str = ""
    attack_var: str = ""
    interface2contract: Dict[str, str] = field(default_factory=dict)


@dataclass
class FunctionSummary:
    ctrt_name: str
    func_name: str
    func_signature: str

    @property
    def canonical_name(self):
        return f"{self.ctrt_name}.{self.func_name}{self.func_signature}"

    @property
    def name(self):
        return self.func_name

    def __hash__(self) -> int:
        return hash(self.canonical_name)

    def __str__(self) -> str:
        return self.canonical_name

    def __eq__(self, __o: object) -> bool:
        return hash(self) == hash(__o)


SKETCH = List[FunctionSummary]

def init_config(ctrt_dir: str) -> Config:
    config_path = path.join(ctrt_dir, "config.json")
    config_json = {}
    if path.exists(config_path):
        with open(config_path, "r") as f:
            config_json = json.load(f)
    config = Config(**config_json)
    return config

def count_sketch(func_cands_num: int, steps: int = 3):
    last = 1
    count = 0
    for _ in range(steps):
        last *= func_cands_num
        count += last
    return count

def print_sketch(sketch: "SKETCH"):
    return " => ".join([f.canonical_name for f in sketch])

__all__ = [
    "MTState",
    "SliContract",
    "SliFunction",
    "SliVariable",
    "SliStateVariable",
    "SolFunction",
    "Config",
    "ManticoreEVM",
    "EVMAccount",
    "EVMContract",
    "ABI",
    "NoAliveStates",
    "Concretize",
    "SolverUnknown"
    "FunctionSummary",
    "SKETCH",
    ether,
    gwei,
    count_sketch,
]
