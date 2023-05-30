import json
from dataclasses import dataclass, field
from os import path
from subprocess import PIPE, Popen
from typing import Dict, List
import re

from enum import Enum

from hashlib import sha3_256

ether = 10 ** 18
gwei = 10 ** 10
max_uint256 = 2 ** 256 - 1

ctrt_name_regex = re.compile(r"\ncontract (\w+)\s+{")


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
    attack_goal: str = ""
    contract_names: List[str] = field(default_factory=list)
    attack_state_variables: List[str] = field(default_factory=list)


class SolFunction:
    def __init__(self, ctrt_name: str, func_name: str, func_types: list) -> None:
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
    

class SolCallType(Enum):
    # payable(address).transfer(...)
    INTRINSIC = 0

    # _internalTransfer(addr1, addr2, amt)
    INTERNAL = 1

    # Token.transfer(addr1, amt)
    EXTERNAL = 2


class ConcreteSolFunction(SolFunction):

    def __init__(self, ctrt_name: str, func_name: str, func_types: list, func_args: list) -> None:
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


class Sketch:

    @classmethod
    def count_all(func_cands_num: int, steps: int = 3):
        last = 1
        count = 0
        for _ in range(steps):
            last *= func_cands_num
            count += last
        return count

    def __init__(self, funcs: List[SolFunction]) -> None:
        self.funcs = funcs

    def __str__(self) -> str:
        return " => ".join([f.canonical_name for f in self.funcs])


def init_config(bmk_dir: str) -> Config:
    config_path = path.join(bmk_dir, "_config.json")
    config_json = {}
    if path.exists(config_path):
        with open(config_path, "r") as f:
            config_json = json.load(f)
    config = Config(**config_json)
    return config


def get_solc_json(file, solc_binary="solc", solc_args: List[str] = None, solc_settings_json=None) -> dict:
    """

    :param file:
    :param solc_binary:
    :param solc_settings_json:
    :return:
    """
    if solc_args is None:
        cmd = [solc_binary, "--standard-json", "--allow-paths", ".,/"]
    else:
        cmd = [solc_binary, "--standard-json"] + solc_args

    settings = {}
    if solc_settings_json:
        with open(solc_settings_json) as f:
            settings = json.load(f)
    if "optimizer" not in settings:
        settings.update({"optimizer": {"enabled": False}})

    settings.update(
        {
            "outputSelection": {
                "*": {
                    "": ["ast"],
                    "*": [
                        "metadata",
                        "evm.bytecode",
                        "evm.deployedBytecode",
                        "evm.methodIdentifiers",
                    ],
                }
            },
        }
    )

    input_json = json.dumps(
        {
            "language": "Solidity",
            "sources": {file: {"urls": [file]}},
            "settings": settings,
        }
    )

    try:
        p = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
        stdout, stderr = p.communicate(bytes(input_json, "utf8"))

    except FileNotFoundError:
        raise CompilerError(
            "Compiler not found. Make sure that solc is installed and in PATH, or set the SOLC environment variable."
        )

    out = stdout.decode("UTF-8")

    try:
        result = json.loads(out)
    except json.JSONDecodeError:
        raise json.JSONDecodeError(
            f"Encountered a decode error.\n stdout:{out}\n stderr: {stderr}")

    for error in result.get("errors", []):
        if error["severity"] == "error":
            raise CompilerError(
                "Solc experienced a fatal error.\n\n%s" % error["formattedMessage"]
            )

    return result
