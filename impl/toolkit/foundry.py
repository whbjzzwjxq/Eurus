import os
from os import path
from subprocess import Popen, run, DEVNULL

from typing import List, Dict, Tuple

from dataclasses import dataclass

import re

import requests
import json

from ..storage.read import StorageDescriber, StorageLayout, TypeDescriber, get_var
from ..storage.utils import int2address

from .config import init_config

from .utils import *

DEFAULT_ACCOUNT = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_PK = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
ATTACK_ACCOUNT = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
ATTACK_PK = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
DEFAULT_HOST = "http://127.0.0.1"
DEFAULT_PORT = "8545"


def init_anvil(timestamp: int):
    cmd = [
        "anvil",
        "--timestamp",
        str(timestamp),
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


@dataclass
class CastStorageInfo:
    name: str
    type: str
    slot: str
    offset: str
    bytes: str
    value: str
    contract: str


def parse_cast_storage_info(lines: List[str]) -> Dict[str, CastStorageInfo]:
    # |Name|Type|Slot|Offset|Bytes|Value|Contract|
    # | A  | B  | C  | D    | E   | F   | G      |
    results = {}
    storage_regex = re.compile(r"\|[\w\s\|]+\|")
    for l in lines:
        if not storage_regex.match(l):
            continue
        record = l.split("|")
        record = [r.strip() for r in record if r]
        if record[0] == "Name":
            # Title itself
            continue
        results[record[0]] = CastStorageInfo(*record)
    return results


def deploy_contract(bmk_dir: str):
    project_name = resolve_project_name(bmk_dir)
    cache_path, _ = prepare_subfolder(bmk_dir)
    config = init_config(bmk_dir)

    ctrt_path = path.join(bmk_dir, f"{project_name}_candidates.t.sol")

    # Deploy
    cmd = [
        "forge",
        "create",
        "--rpc-url",
        f"{DEFAULT_HOST}:{DEFAULT_PORT}",
        "--private-key",
        DEFAULT_PK,
        "--cache-path",
        cache_path,
        "--extra-output",
        "storageLayout",
        "metadata",
        "--root",
        os.getcwd(),
        f"{ctrt_path}:{project_name}Test",
    ]
    try:
        out = run(cmd, text=True, capture_output=True)
    except Exception as err:
        print(f"Deploy contract:{project_name} failed!")
        raise err
    lines = out.stdout.splitlines(keepends=False)
    address = None
    for l in lines:
        if l.startswith("Deployed to: "):
            address = l.removeprefix("Deployed to: ").strip()
    if address is None:
        raise ValueError("Unknown address for deployment.")

    # Run setup
    cmd = [
        "cast",
        "send",
        "--rpc-url",
        f"{DEFAULT_HOST}:{DEFAULT_PORT}",
        "--private-key",
        DEFAULT_PK,
        "--gas-limit",
        str(10**8),
        address,
        "setUp()",
        "",
    ]
    try:
        out = run(cmd, text=True, capture_output=True)
    except Exception as err:
        print(f"Setup contract:{project_name} failed!")
        raise err

    # Run snapshot
    snapshot_id = 0

    # Query storage to get the address of contracts
    cmd = [
        "cast",
        "storage",
        "--silent",
        address,
    ]
    try:
        out = run(cmd, text=True, capture_output=True)
    except Exception as err:
        print(f"Query storage contract:{project_name} failed!")
        raise err

    lines = out.stdout.splitlines(keepends=False)

    init_storage = parse_cast_storage_info(lines)
    ctrt_name2addr: Dict[str, str] = {}

    for role, _ in config.ctrt_name2cls:
        addr_var = init_storage[f"{role}Addr"]
        ctrt_name2addr[role] = int2address(int(addr_var.value))
    ctrt_name2addr["attacker"] = int2address(int(init_storage["attacker"].value))
    ctrt_name2addr["owner"] = address
    ctrt_name2addr["dead"] = "0x000000000000000000000000000000000000dEaD"
    return snapshot_id, ctrt_name2addr



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
    pass
