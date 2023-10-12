import os
from os import path
from subprocess import Popen, run

import requests
import json

from .config import init_config

from .utils import prepare_subfolder, resolve_project_name

DEFAULT_ACCOUNT = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_PK = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
ATTACK_ACCOUNT = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
ATTACK_PK = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
DEFAULT_HOST = "http://127.0.0.1"
DEFAULT_PORT = "8545"

def init_anvil():
    cmd = [
        "anvil",
        "--timestamp",
        "0",
        "--base-fee",
        "0",
        "--gas-price",
        "0",
        "--code-size-limit",
        str(10 ** 8),
        "--gas-limit",
        str(10 ** 8),
    ]
    return Popen(cmd)


def create_snapshot() -> str:
    payload = {
        "id": 1337,
        "jsonrpc": "2.0",
        "method": "evm_snapshot",
        "params": []
    }
    url = f"{DEFAULT_HOST}:{DEFAULT_PORT}"
    headers = {
        "Content-Type": "application/json"
    }
    response = requests.post(url, data=json.dumps(payload), headers=headers)
    if response.status_code == 200:
        # snapshot id.
        return response.json()["result"]
    else:
        raise RuntimeError(f"Create snapshot failed! Error: {response.status_code} - {response.text}")


def deploy_contract(bmk_dir: str):
    project_name = resolve_project_name(bmk_dir)
    cache_path, _ = prepare_subfolder(bmk_dir)
    config = init_config(bmk_dir)

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
        path.join(bmk_dir, f"{project_name}.t.sol:{project_name}Test")
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
        str(10 ** 8),
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
    snapshot_id = create_snapshot()
    
    # Query storage to get the address of contracts
    cmd = [
        "cast",
        "storage",
        address,
    ]
    lines = out.stdout.splitlines(keepends=False)

