import os
from os import path
from subprocess import Popen, run

from .utils import prepare_subfolder, resolve_project_name

DEFAULT_ACCOUNT = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEFAULT_PK = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
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


def deploy_contract(bmk_dir: str):
    project_name = resolve_project_name(bmk_dir)
    cache_path, _ = prepare_subfolder(bmk_dir)
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
        out = run(cmd, text=True)
    except Exception as err:
        print(f"Deploy contract:{project_name}")
        raise err
    lines = out.stdout.splitlines(keepends=False)
    address = None
    for l in lines:
        if l.startswith("Deployed to: "):
            address = l.removeprefix("Deployed to: ").strip()
    if address is None:
        raise ValueError("Unknown address for deployment.")
    
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
