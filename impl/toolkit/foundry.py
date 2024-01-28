import json
import re
from os import path
from subprocess import DEVNULL, Popen, run
from typing import Dict, List, Tuple

from ..eth_storage.read import (StorageDescriber, StorageLayout, TypeDescriber,
                                get_var)
from .config import init_config
from .utils import *

DEFAULT_ACCOUNT = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_PK = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_HOST = "http://127.0.0.1"
DEFAULT_PORT = "8545"


def init_anvil(blockchain: str, blocknumber: int):
    cmd = [
        "anvil",
        "--fork-url",
        blockchain,
        "--fork-block-number",
        str(blocknumber),
        "--base-fee",
        "0",
        "--gas-price",
        "0",
        "--code-size-limit",
        str(10**8),
        "--gas-limit",
        str(10**8),
    ]
    return Popen(cmd, stdout=DEVNULL)


def verify_model_on_anvil(ctrt_name2addr: Dict[str, str], func_name: str, params: List[str]) -> bool:
    owner_address = ctrt_name2addr["owner"]
    labels = []
    for k, v in ctrt_name2addr.items():
        labels.append("--labels")
        labels.append(f"{v}:{k}")
    param_types = ",".join(["uint256"] * len(params))
    func_name = f"{func_name}({param_types})"
    cmd = [
        "cast",
        "call",
        "--trace",
        "--verbose",
        *labels,
        "--rpc-url",
        f"{DEFAULT_HOST}:{DEFAULT_PORT}",
        "--private-key",
        DEFAULT_PK,
        "--gas-limit",
        str(10**8),
        owner_address,
        func_name,
        *params,
    ]
    try:
        out = run(cmd, text=True, capture_output=True, check=True)
    except Exception as err:
        print(err)
        return False
    print(out.stdout)
    output = out.stdout.splitlines()[-5]
    feasible = output.endswith("0x4e487b710000000000000000000000000000000000000000000000000000000000000001")
    if not feasible:
        print(out.stdout)
    return feasible


class LazyStorage:
    uniswap_pair_ctrt = "UniswapV2Pair"
    uniswap_factory_ctrt = "UniswapV2Factory"
    uniswap_router_ctrt = "UniswapV2Router"
    default_erc20_tokens = [
        "USDCE",
        "USDT",
        "WETH",
        "WBNB",
        "BUSD",
    ]

    def __init__(self, bmk_dir: str, ctrt_name2addr: Dict[str, str], timestamp: str) -> None:
        self.bmk_dir = bmk_dir
        self.config = init_config(bmk_dir)
        self.project_name = self.config.project_name
        self.ctrt_name2addr: Dict[str, str] = ctrt_name2addr
        self.ctrt_name2stor_layout: Dict[str, StorageLayout] = {}
        self.timestamp = timestamp

        cache_path, _ = prepare_subfolder(bmk_dir)

        sol_file_cache: dict = {}
        with open(path.join(cache_path, "solidity-files-cache.json"), "r") as f:
            sol_file_cache = json.load(f)["files"]

        for ctrt_name, ctrt_filename in self.config.ctrt_name2cls:
            if ctrt_filename in (
                self.uniswap_pair_ctrt,
                self.uniswap_factory_ctrt,
                self.uniswap_router_ctrt,
                *self.default_erc20_tokens,
            ):
                key = f"lib/contracts/@utils/{ctrt_filename}.sol"
            else:
                key = f"benchmarks/{self.project_name}/{ctrt_filename}.sol"
            compiled_file = list(sol_file_cache[key]["artifacts"][ctrt_filename].values())[0]
            source_output = path.join(
                ".cache",
                compiled_file,
            )
            with open(source_output, "r") as f:
                compile_output = json.load(f)
                self.add_layout(ctrt_name, compile_output["storageLayout"])

        self._cache: Dict[str, str] = {}

    def add_layout(self, ctrt_name: str, contract_layout: Dict[str, dict]):
        label_defs = [StorageDescriber(storage_describer) for storage_describer in contract_layout["storage"]]
        type_def_mapping: Dict[str, TypeDescriber] = {}
        types_layout = contract_layout["types"]
        for type_name, _ in types_layout.items():
            type_def_mapping[type_name] = TypeDescriber(type_name, types_layout)
        self.ctrt_name2stor_layout[ctrt_name] = (label_defs, type_def_mapping)

    def bind_value(self, value_str: str) -> str:
        if value_str in self.ctrt_name2addr:
            return self.ctrt_name2addr[value_str]
        elif value_str.startswith("uint256"):
            # uint256(0)
            v = value_str.removeprefix("uint256(").removesuffix(")")
            v = "0x" + hex(int(v)).removeprefix("0x").zfill(64)
            return v
        else:
            return value_str

    def parse_key(self, key: str) -> Tuple[str, str, List[str]]:
        # A.userInfo[attacker].userId
        ctrt_name, var = key.split(".", 1)

        # userInfo[attacker]; userId
        vars = var.split(".")
        temps = []
        for v in vars:
            ks = v.split("[")
            for k in ks:
                k = k.strip("]")
                temps.append(k)
        var_name = temps[0]
        keys = [self.bind_value(v) for v in temps[1:]]
        return ctrt_name, var_name, keys

    def parse_func_call(self, key: str) -> Tuple[str, str, List[str]]:
        func_name2sig = {
            "balanceOf": "balanceOf(address)(uint256)",
            "investedBalanceInUSD": "investedBalanceInUSD()(uint256)",
            "totalSupply": "totalSupply()(uint256)",
        }
        # A.balanceOf(pair)
        ctrt_name, func_call = key.split(".", 1)

        # balanceOf, pair)
        func_name, func_args = func_call.split("(")

        # pair
        func_args = func_args.strip(")")
        func_sig = func_name2sig[func_name]
        func_args = [self.bind_value(v) for v in func_args.split(",")]
        return ctrt_name, func_sig, func_args

    def get(self, key: str):
        # A.balanceOf()
        func_call_regex = re.compile(r"\w*\.\w*\(.*")

        # vm.warp(block.timestamp)
        vmwarp_regex = re.compile(r"vm\.warp\((.*)\)")
        if key in self._cache:
            return self._cache[key]
        if key == "block.timestamp":
            value = self.timestamp
            for stmt in self.config.extra_statements:
                m = vmwarp_regex.match(stmt)
                if m:
                    expr: str = m.groups()[0]
                    expr = expr.replace("block.timestamp", value)
                    value = str(eval(expr))
        elif func_call_regex.match(key):
            ctrt_name, func_sig, func_args = self.parse_func_call(key)
            if ctrt_name not in self.ctrt_name2addr:
                raise ValueError(f"Unknown contract: {ctrt_name}")
            ctrt_addr = self.ctrt_name2addr[ctrt_name]
            cmd = ["cast", "call", ctrt_addr, func_sig, *func_args]
            output = run(cmd, capture_output=True, text=True)
            value = output.stdout.strip().removesuffix("\n")
            # To deal with the case in Anvil 0.2.0
            if " " in value:
                value = value.split(" ")[0]
        else:
            ctrt_name, var_name, keys = self.parse_key(key)
            if ctrt_name not in self.ctrt_name2addr:
                raise ValueError(f"Unknown contract: {ctrt_name}")
            ctrt_addr = self.ctrt_name2addr[ctrt_name]
            layout = self.ctrt_name2stor_layout[ctrt_name]
            value = get_var(ctrt_addr, var_name, keys, layout)
        self._cache[key] = value
        return value
