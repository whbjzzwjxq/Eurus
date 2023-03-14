import argparse
from subprocess import DEVNULL, PIPE, Popen, TimeoutExpired
import time

import json
import os
from os import path

from typing import Dict, List
from impl.utils import init_config

parser = argparse.ArgumentParser()
parser.add_argument(
    "-i", "--input", help="Target contract directory.", default="")
parser.add_argument(
    "-f", "--forge", help="Do the forge invariant test.", action="store_true")
parser.add_argument("--timeout", help="Timeout.", type=int, default=3600)


def get_bmks(bmk_path: str):
    if bmk_path:
        bmk_paths = [bmk_path]
    else:
        bmk_paths = []
        for n in os.listdir("./benchmarks"):
            bmk_paths.append(path.join("./benchmarks", n))
    return bmk_paths

def resolve_bmk_name(bmk_path: str):
    return path.basename(bmk_path)


def forge_test(bmk_path: str, timeout: int):
    bmk_name = resolve_bmk_name(bmk_path)
    test_solfile = path.join(bmk_path, f"{bmk_name}.t.sol")
    cache_path = path.join(bmk_path, "cache")
    if not path.exists(cache_path):
        os.mkdir(cache_path)
    result_path = path.join(bmk_path, "result")
    if not path.exists(result_path):
        os.mkdir(result_path)
    cmds = [
        "forge",
        "test",
        "-C",
        bmk_path,
        "-vvvv",
        "--cache-path",
        cache_path,
        "--match-path",
        test_solfile,
        "--allow-failure"
    ]
    out = {}
    err = {}
    try:
        init_timer = time.perf_counter()
        out, _ = execute(cmds, timeout=timeout, stdout=PIPE, stderr=PIPE)
        timecost = time.perf_counter() - init_timer
    except TimeoutExpired:
        err = {"error": "timeout"}
    except Exception as e:
        err = {"error": str(e)}
    if out:
        out = {"time": timecost, "result": str(out)}
        with open(path.join(result_path, "out.log"), "w") as f:
            json.dump(out, f)
    if err:
        with open(path.join(result_path, "err.log"), "w") as f:
            json.dump(err, f)


def execute(cmds: List[str], timeout=1200, stdout=DEVNULL, stderr=DEVNULL):
    cmd = " ".join(cmds)
    print(cmd)
    proc = Popen(cmd, shell=True, stdout=stdout, stderr=stderr)
    try:
        return proc.communicate(timeout=timeout)
    except TimeoutExpired as tee:
        proc.terminate()
        proc.communicate()
        raise tee


def _main():
    args = parser.parse_args()
    # config = init_config(args.input)
    bmk_paths = get_bmks(args.input)
    for bmk_path in bmk_paths:
        if args.forge:
            forge_test(bmk_path, args.timeout)


if __name__ == "__main__":
    _main()
