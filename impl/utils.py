import json
import re
from dataclasses import dataclass, field
from os import path
from typing import Dict, List

ether = 10 ** 18
gwei = 10 ** 10
max_uint256 = 2 ** 256 - 1

ctrt_name_regex = re.compile(r"\ncontract (\w+)\s+{")


def decimal_to_n_base(decimal: int, base: int) -> List[int]:
    result = []

    while decimal > 0:
        decimal, remainder = divmod(decimal, base)
        result.append(remainder)

    result.reverse()
    return result


class CompilerError(BaseException):
    """An error happened during code compilation."""
    pass


class CornerCase(BaseException):
    """A corner case has been reached."""
    pass


class FrozenObject(RuntimeError):
    """Don't add item in a freeze graph."""
    pass


@dataclass
class Config:
    project_name: str = "None"
    contract_names: List[str] = field(default_factory=list)
    contract_names_mapping: Dict[str, str] = field(default_factory=dict)
    groundtruth: List[str] = field(default_factory=list)
    attack_state_variables: List[str] = field(default_factory=list)


def init_config(bmk_dir: str) -> Config:
    config_path = path.join(bmk_dir, "_config.json")
    config_json = {}
    if path.exists(config_path):
        with open(config_path, "r") as f:
            config_json = json.load(f)
    config = Config(**config_json)
    return config
