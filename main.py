import argparse
import json
import os
from subprocess import run, TimeoutExpired, CalledProcessError
from os import path
from typing import List, Tuple
import time

from impl.solidity_builder import BenchmarkBuilder

parser = argparse.ArgumentParser()
parser.add_argument(
    "-p", "--prepare", help="Prepare all sol files to execute.", action="store_true"
)
parser.add_argument(
    "-i",
    "--input",
    help="Input benchmark directory. Set to all for all of benchmarks.",
    default="",
)
parser.add_argument(
    "-fo", "--forge", help="Do Foundry fuzzing test.", action="store_true"
)
parser.add_argument(
    "-ha", "--halmos", help="Do Halmos symbolic execution.", action="store_true"
)
parser.add_argument("-s", "--statistic", help="Print statistic.", action="store_true")
parser.add_argument(
    "--timeout", help="Set the total timeout.", type=int, default=3600 * 2
)


def get_bmk_dirs(bmk_dir: str) -> List[str]:
    # Don't use an absolute path, because Foundry doesn't support it.
    benmark_folder = "./benchmarks"
    if bmk_dir == "all":
        bmk_dirs = []
        for p in os.listdir(benmark_folder):
            bmk_dir = path.join(benmark_folder, p)
            if not path.isdir(bmk_dir):
                continue
            if not path.exists(path.join(bmk_dir, "_config.yaml")):
                continue
            bmk_dirs.append(bmk_dir)
    else:
        if not path.isdir(bmk_dir):
            raise ValueError(
                f"Benchmark path should be a directory, current is: {bmk_dir}"
            )
        bmk_dirs = [bmk_dir]
    return bmk_dirs


def resolve_project_name(bmk_dir: str):
    return path.basename(bmk_dir)


def prepare_subfolder(bmk_dir: str) -> Tuple[str, str]:
    cache_path = path.join(bmk_dir, ".cache")
    if not path.exists(cache_path):
        os.mkdir(cache_path)
    result_path = path.join(bmk_dir, "result")
    if not path.exists(result_path):
        os.mkdir(result_path)
    return cache_path, result_path


def prepare():
    bmk_dirs = get_bmk_dirs("all")
    for bmk_dir in bmk_dirs:
        project_name = resolve_project_name(bmk_dir)
        output_file = path.join(bmk_dir, f"{project_name}.t.sol")
        print(f"Output path is: {output_file}")
        if path.exists(output_file):
            os.remove(output_file)
        _ = prepare_subfolder(bmk_dir)
    for bmk_dir in bmk_dirs:
        project_name = resolve_project_name(bmk_dir)
        builder = BenchmarkBuilder(bmk_dir)
        output_file = path.join(bmk_dir, f"{project_name}.t.sol")
        builder.output(output_file)

        # Format
        cmd = [
            "npx",
            "prettier",
            "--write",
            "--plugin=prettier-plugin-solidity",
            f"{output_file}",
        ]
        run(cmd, text=True, check=True)


def forge_test(bmk_dir: str, timeout: int):
    project_name = resolve_project_name(bmk_dir)
    test_solfile = path.join(bmk_dir, f"{project_name}_forge.t.sol")
    cache_path, result_path = prepare_subfolder(bmk_dir)
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
        "--allow-failure",
    ]
    out = {}
    err = {}
    timer = time.perf_counter()
    try:
        out = run(cmds, timeout=timeout, text=True, check=True, capture_output=True)
    except TimeoutExpired:
        err = {"error": "timeout", "details": ""}
    except Exception as e:
        err = {"error": "unknown", "details": str(e)}
    if out:
        timecost = time.perf_counter() - timer
        out = {"time": timecost, "result": str(out)}
        with open(path.join(result_path, "forge_out.json"), "w") as f:
            json.dump(out, f)
    if err:
        with open(path.join(result_path, "forge_err.json"), "w") as f:
            json.dump(err, f)


def halmos_test(bmk_dir: str, timeout: int):
    project_name = resolve_project_name(bmk_dir)
    _, result_path = prepare_subfolder(bmk_dir)
    for i in range(100):
        idx = str(i).zfill(3)
        json_output = path.join(result_path, f"halmos_out{idx}.json")
        cmds = [
            "halmos",
            "-vvvvv",
            "--function",
            f"check_cand{idx}",
            "--contract",
            f"{project_name}Test",
            "--forge-build-out",
            ".cache",
            "--print-potential-counterexample",
            # It doesn't work.
            # "--symbolic-storage",
            "--solver-timeout-branching",
            "100000",
            "--solver-timeout-assertion",
            "100000",
            "--json-output",
            json_output,
        ]
        print(" ".join(cmds))
        proc, err = None, None
        try:
            proc = run(cmds, timeout=timeout, text=True, capture_output=True)
        except TimeoutExpired:
            err = {"error": "timeout", "details": ""}
        except Exception as e:
            err = {"error": "unknown", "details": str(e)}
        if proc:
            if "Error: No tests with the prefix" in proc.stdout:
                break
            print(proc.stdout, proc.stderr)
        if err:
            with open(path.join(result_path, f"halmos_err{idx}.json"), "w") as f:
                json.dump(err, f)


def _main():
    args = parser.parse_args()
    if args.prepare:
        prepare()
        return
    bmk_dirs = get_bmk_dirs(args.input)
    for bmk_dir in bmk_dirs:
        if args.forge:
            forge_test(bmk_dir, args.timeout)
        if args.halmos:
            halmos_test(bmk_dir, args.timeout)


if __name__ == "__main__":
    _main()
