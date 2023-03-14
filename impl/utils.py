import json
from dataclasses import dataclass, field
from os import path
from subprocess import PIPE, Popen
from typing import Dict, List
import re

ether = 10 ** 18
gwei = 10 ** 10
max_uint256 = 2 ** 256 - 1

ctrt_name_regex = re.compile(r"\ncontract (\w+)\s+{")


class CompilerError(BaseException):
    """A Mythril exception denoting an error during code compilation."""
    pass

@dataclass
class Config:
    project_name: str = "None"
    contracts: Dict[str, List[str]] = field(default_factory=dict)
    attack_goal: str = ""
    attack_var: str = ""
    interface2contract: Dict[str, str] = field(default_factory=dict)


@dataclass
class FunctionInstance:
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


SKETCH = List[FunctionInstance]

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

def print_sketch(sketch: SKETCH):
    return " => ".join([f.canonical_name for f in sketch])

def get_solc_json(file, solc_binary="solc", solc_args: List[str]=None, solc_settings_json=None) -> dict:
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
        raise json.JSONDecodeError(f"Encountered a decode error.\n stdout:{out}\n stderr: {stderr}")

    for error in result.get("errors", []):
        if error["severity"] == "error":
            raise CompilerError(
                "Solc experienced a fatal error.\n\n%s" % error["formattedMessage"]
            )

    return result
