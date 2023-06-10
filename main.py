import argparse
import json
import os
import time
from os import path
from subprocess import DEVNULL, PIPE, Popen, TimeoutExpired
from typing import List

from impl.defi import Defi
from impl.synthesizer import Synthesizer
from impl.output2racket import output_defi

parser = argparse.ArgumentParser()
parser.add_argument(
    "-i", "--input", help="Target contract directory.", default="")
parser.add_argument(
    "-f", "--forge", help="Do the forge invariant test.", action="store_true")
parser.add_argument(
    "--rwgraph", help="Generate the Read/Write analysis graph.", action="store_true")
parser.add_argument(
    "-m", "--mockeval", help="Mock the evaluation.", action="store_true")
parser.add_argument(
    "--outputrkt", help="Output to Racket.", action="store_true")
parser.add_argument("--timeout", help="Timeout.", type=int, default=3600)


def get_bmk_dirs(bmk_dir: str):
    toy_dir = path.abspath("./benchmarks/toy")
    realworld_dir = path.abspath("./benchmarks/realworld")
    if bmk_dir == "all":
        for n in os.listdir(toy_dir):
            bmk_dirs.append(path.join(toy_dir, n))
        for n in os.listdir(realworld_dir):
            bmk_dirs.append(path.join(realworld_dir, n))
        return bmk_dirs
    else:
        if not path.isdir(bmk_dir):
            raise ValueError(f"Benchmark path should be directory, current is: {bmk_dir}")
        if path.abspath(bmk_dir) == toy_dir:
            for n in os.listdir(toy_dir):
                bmk_dirs.append(path.join(toy_dir, n))
            return bmk_dirs
        if path.abspath(bmk_dir) == realworld_dir:
            for n in os.listdir(realworld_dir):
                bmk_dirs.append(path.join(realworld_dir, n))
            return bmk_dirs
        bmk_dirs = [bmk_dir]
        return bmk_dirs

def resolve_bmk_name(bmk_dir: str):
    return path.basename(bmk_dir)


def forge_test(bmk_dir: str, timeout: int):
    bmk_name = resolve_bmk_name(bmk_dir)
    test_solfile = path.join(bmk_dir, f"{bmk_name}.t.sol")
    cache_path = path.join(bmk_dir, "cache")
    if not path.exists(cache_path):
        os.mkdir(cache_path)
    result_path = path.join(bmk_dir, "result")
    if not path.exists(result_path):
        os.mkdir(result_path)
    cmds = [
        "forge",
        "test",
        "-C",
        bmk_dir,
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


def mock_evaluate(bmk_dir: str):
    defi = Defi(bmk_dir)
    synthesizer = Synthesizer(defi)
    output_path = path.abspath(path.join(bmk_dir, "_rw_eval.csv"))
    synthesizer.mock_eval(output_path)

def generate_rw_graph(bmk_dir: str):
    defi = Defi(bmk_dir)
    output_path = path.abspath(path.join(bmk_dir, "_rw.gv"))
    defi.print_rw_graph(output_path)

def output2racket(bmk_dir: str):
    defi = Defi(bmk_dir)
    output_path = path.abspath(path.join(bmk_dir, "_defi_racket.json"))
    obj = output_defi(defi)
    with open(output_path, "w") as f:
        json.dump(obj, f)
    
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
    bmk_dirs = get_bmk_dirs(args.input)
    for bmk_dir in bmk_dirs:
        if args.forge:
            forge_test(bmk_dir, args.timeout)
        if args.rwgraph:
            generate_rw_graph(bmk_dir)
        if args.mockeval:
            mock_evaluate(bmk_dir)
        if args.outputrkt:
            output2racket(bmk_dir)

if __name__ == "__main__":
    _main()
