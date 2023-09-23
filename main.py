import argparse
import json
import math
import os
import random
import re
import shutil
import time
from os import path
from subprocess import CalledProcessError, TimeoutExpired, run
from typing import List, Tuple

from impl.dsl import Sketch
from impl.solidity_builder import BenchmarkBuilder
from impl.synthesizer import Synthesizer
from impl.utils import (
    gen_model_by_z3,
    gen_result_paths,
    is_result_sat,
    parse_smt_output,
)

parser = argparse.ArgumentParser()

parser.add_argument(
    "-i",
    "--input",
    type=str,
    action='append',
    help="Input benchmark directory. Set to `all` for all of benchmarks.",
    required=True,
)

# Actions, select one of them.
parser.add_argument(
    "-p",
    "--prepare",
    help="Prepare all sol files to execute.",
    action="store_true",
)

parser.add_argument(
    "-v",
    "--verify",
    help="Verify the result of sketch.",
    action="store_true",
)

parser.add_argument(
    "-fo",
    "--forge",
    help="Do Foundry fuzzing test.",
    action="store_true",
)

parser.add_argument(
    "-ha",
    "--halmos",
    help="Do Halmos symbolic execution.",
    action="store_true",
)

parser.add_argument(
    "-s",
    "--statistic",
    help="Print statistic.",
    action="store_true",
)

parser.add_argument(
    "-c",
    "--clean",
    help="Clean the cache.",
    action="store_true",
)

parser.add_argument(
    "-pg",
    "--printgt",
    help="Print GroundTruth",
    action="store_true",
)

parser.add_argument(
    "--fuzz-smtdiv",
    help="Fuzzing the replaced smtdiv to find the upper bound",
    action="store_true",
)

# Parameters for evaluation.
parser.add_argument(
    "--timeout",
    help="Set the total timeout.",
    type=int,
    default=3600 * 12,
)

parser.add_argument(
    "--start",
    help="Start sketch.",
    type=int,
    default=0,
)

parser.add_argument(
    "--end",
    help="End sketch",
    type=int,
    default=100,
)

parser.add_argument(
    "--gt",
    help="Only evaluate groundtruth",
    action="store_true",
)

parser.add_argument(
    "--smtdiv",
    help="Apply smt-div in which phases",
    choices=["All", "Models", "None"],
    default="All",
)

parser.add_argument(
    "--fuzz-times",
    type=int,
    default=1000,
)

# parallel actually doesn't work, don't use it.
parser.add_argument(
    "--solver-parallel",
    help="Allow parallet in solver",
    action="store_true",
)


def get_bmk_dirs(i_bmk_dirs: str) -> List[str]:
    # Don't use an absolute path, because Foundry doesn't support it.
    benmark_folder = "./benchmarks"
    bmk_dirs = []
    if "all" in i_bmk_dirs:
        for p in os.listdir(benmark_folder):
            bmk_dir = path.join(benmark_folder, p)
            if not path.isdir(bmk_dir):
                continue
            if not path.exists(path.join(bmk_dir, "_config.yaml")):
                continue
            bmk_dirs.append(bmk_dir)
    else:
        for bmk_dir in i_bmk_dirs:
            if not path.isdir(bmk_dir):
                raise ValueError(
                    f"Benchmark path should be a directory, current is: {bmk_dir}"
                )
            config_file = path.join(bmk_dir, "_config.yaml")
            if not path.exists(config_file):
                continue

            bmk_dirs.append(bmk_dir)
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


def prepare(bmk_dir: str):
    project_name = resolve_project_name(bmk_dir)
    cache_path, result_path = prepare_subfolder(bmk_dir)
    output_file = path.join(bmk_dir, f"{project_name}.t.sol")
    print(f"Output path is: {output_file}")
    if path.exists(output_file):
        os.remove(output_file)
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

    # Run ground truth
    cmds = [
        "forge",
        "test",
        "-vvv",
        "--cache-path",
        cache_path,
        "--match-path",
        output_file,
    ]
    try:
        out = run(cmds, text=True, check=True, capture_output=True)
    except Exception as err:
        if isinstance(err, CalledProcessError):
            print(err.stderr, err.stdout)
        print(f"\n\nBenchmark: {bmk_dir} ground truth doesn't work!")
        print("Execute: ", " ".join(cmds))
        raise err


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


def halmos_test(
    bmk_dir: str,
    timeout: int,
    only_gt: bool,
    smtdiv: str,
    start: int,
    end: int,
    parallel: bool,
):
    builder = BenchmarkBuilder(bmk_dir)
    synthesizer = Synthesizer(builder.config)
    project_name = resolve_project_name(bmk_dir)
    solver_timeout = timeout // 2
    _, result_path = prepare_subfolder(bmk_dir)

    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates)
    )

    result_paths = result_paths[start:end]

    for _, _, _, smt_folder in result_paths:
        if not path.exists(smt_folder):
            os.mkdir(smt_folder)
        for smtquerys in os.listdir(smt_folder):
            if not smtquerys.endswith("smt2"):
                continue
            base_smtquery_path = path.join(smt_folder, smtquerys)
            base_smtquery_resultpath = base_smtquery_path.replace(".smt2", ".smt2.out")
            if not path.exists(base_smtquery_resultpath):
                gen_model_by_z3(
                    base_smtquery_path,
                    base_smtquery_resultpath,
                    solver_timeout,
                    parallel=parallel,
                )
            succeed = verify_result(bmk_dir, only_gt, smtdiv)
            if succeed:
                break


def clean_result(bmk_dir: str, only_gt: bool, smtdiv: str, start: int, end: int):
    builder = BenchmarkBuilder(bmk_dir)
    synthesizer = Synthesizer(builder.config)
    _, result_path = prepare_subfolder(bmk_dir)
    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates)
    )
    result_paths = result_paths[start:end]
    for _, output_path, err_path, smt_folder in result_paths:
        if path.exists(output_path):
            os.remove(output_path)
        if path.exists(err_path):
            os.remove(err_path)
        if path.exists(smt_folder):
            shutil.rmtree(smt_folder)


def print_groundtruth(bmk_dir: str):
    builder = BenchmarkBuilder(bmk_dir)
    sketch = builder.gt_sketch
    print("----Groundtruth----\n")
    for a in sketch.pure_actions:
        print(str(a))
    print("\n\n----Groundtruth Sketch----\n")
    s_sketch = sketch.symbolic_copy()
    for a in s_sketch.pure_actions:
        print(str(a))


def load_smt_model(file_path: str) -> List[List[str]]:
    if not path.exists(file_path):
        return []
    if file_path.endswith(".json"):
        with open(file_path, "r") as f:
            result = json.load(f)
        result = list(result["test_results"].values())[0][0]
        if len(result["models"]) == 0:
            return []
        arg_candidates = []
        for model in result["models"]:
            if isinstance(model, str):
                smtout = model.removeprefix("see ")
                arg_candidates.extend(load_smt_model(smtout))
            else:
                arg_candidates.append(
                    [model[f"p_amt{j}_uint256"] for j in range(len(model))]
                )
        return arg_candidates
    elif file_path.endswith(".smt2.out"):
        with open(file_path, "r") as f:
            lines = f.readlines()
        if lines[0].strip() != "sat":
            return []
        values = [parse_smt_output(f"p_amt{j}_uint256", lines) for j in range(10)]
        values = [v for v in values if v is not None]
        return [values]
    else:
        raise ValueError(f"Unknown file for smt model: {file_path}")


def verify_model(bmk_dir: str, verifiers: List[Tuple[str, Sketch, List[List[str]]]]):
    builder = BenchmarkBuilder(bmk_dir)
    cache_path, _ = prepare_subfolder(bmk_dir)

    # Verification for Halmos.
    verify_sol_path = path.join(bmk_dir, f"verify.t.sol")
    if path.exists(verify_sol_path):
        os.remove(verify_sol_path)

    builder.output_verify(verifiers, verify_sol_path)

    cmds = [
        "forge",
        "test",
        "-j",
        "--cache-path",
        cache_path,
        "--match-path",
        verify_sol_path,
    ]
    try:
        out = run(cmds, text=True, capture_output=True)
    except Exception:
        pass
    lines = out.stdout.splitlines()
    result = json.loads(lines[-1])
    result = list(result.values())[0]["test_results"]
    result.pop("test_gt()")
    verified_sketches = [k for k, v in result.items() if v["status"] == "Success"]
    verified_sketches = sorted(verified_sketches)
    os.remove(verify_sol_path)
    return len(verified_sketches) != 0


def verify_result(bmk_dir: str, only_gt: bool, smtdiv: str):
    builder = BenchmarkBuilder(bmk_dir)
    synthesizer = Synthesizer(builder.config)
    _, result_path = prepare_subfolder(bmk_dir)
    project_name = resolve_project_name(bmk_dir)

    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates)
    )

    verifiers = []

    for func_name, output_path, _, _ in result_paths:
        sketch = get_sketch_by_func_name(builder, synthesizer, func_name)
        model = load_smt_model(output_path)
        if len(model) == 0:
            continue
        verifiers.append((func_name, sketch, model))

    succeed = verify_model(bmk_dir, verifiers)
    if succeed:
        print(
            f"Great! Benchmark: {project_name} is solved by setting: only_gt={only_gt}, smtdiv={smtdiv}"
        )
    else:
        print(
            f"Benchmark: {project_name} is NOT solved by setting: only_gt={only_gt}, smtdiv={smtdiv}"
        )
    return succeed


def prepare_smtquery(bmk_dir: str, only_gt: bool, smtdiv: str, timeout: int):
    builder = BenchmarkBuilder(bmk_dir)
    synthesize = Synthesizer(builder.config)
    _, result_path = prepare_subfolder(bmk_dir)
    project_name = resolve_project_name(bmk_dir)

    # func_name, output_path, err_path, smt_folder
    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesize.candidates)
    )

    result_paths = [
        (func_name, a, b, c)
        for func_name, a, b, c in result_paths
        if not (path.exists(a) and path.exists(c))
    ]

    for func_name, output_path, err_path, smt_folder in result_paths:
        cmds = [
            "halmos",
            "-vvvvv",
            "--function",
            f"{func_name}",
            "--contract",
            f"{project_name}Test",
            "--forge-build-out",
            ".cache",
            "--solver-timeout-branching",
            "100",
            "--solver-timeout-assertion",
            "0",
            "--json-output",
            output_path,
            "--solver-only-dump",
            "--dump-smt-queries",
            smt_folder,
        ]
        if smtdiv == "All":
            cmds.append("--smt-div")
            cmds.append("--solver-smt-div")
        elif smtdiv == "Models":
            cmds.append("--solver-smt-div")
        print(" ".join(cmds))
        proc, err = None, None
        try:
            proc = run(cmds, timeout=timeout, text=True, capture_output=True)
        except TimeoutExpired:
            err = {"error": "timeout", "details": ""}
        except Exception as e:
            err = {"error": "unknown", "details": str(e)}
        if proc:
            print(proc.stdout, proc.stderr)
        if err:
            with open(err_path, "w") as f:
                json.dump(err, f)


def get_sketch_by_func_name(b: BenchmarkBuilder, s: Synthesizer, func_name: str):
    if func_name == "check_gt":
        sketch = b.gt_sketch.symbolic_copy()
    else:
        sketch = s.candidates[int(func_name.removeprefix("check_cand"))]
    return sketch


def fuzz_smtquery(
    bmk_dir: str,
    only_gt: bool,
    smtdiv: str,
    timeout: int,
    fuzz_times: int,
    parallel: bool,
):
    pattern = re.compile(r"evm_bvudiv")
    replacement = "bvudiv"
    builder = BenchmarkBuilder(bmk_dir)
    synthesizer = Synthesizer(builder.config)
    _, result_path = prepare_subfolder(bmk_dir)

    # Timeout for one query
    solver_timeout = (timeout // fuzz_times) * 10

    # func_name, output_path, err_path, smt_folder
    result_paths: List[Tuple[str, str, str, str]] = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates)
    )

    def variable_replace(match, r):
        # Decide whether to replace or keep the match
        return replacement if random.random() <= r else match.group()

    for func_name, _, _, smt_folder in result_paths:
        for smtquerys in os.listdir(smt_folder):
            if not smtquerys.endswith("smt2"):
                continue
            base_smtquery_path = path.join(smt_folder, smtquerys)
            base_smtquery_resultpath = base_smtquery_path.replace(".smt2", ".smt2.out")
            if not path.exists(base_smtquery_resultpath):
                gen_model_by_z3(
                    base_smtquery_path,
                    base_smtquery_resultpath,
                    parallel=parallel,
                )
            if not is_result_sat(base_smtquery_resultpath):
                continue
            with open(base_smtquery_path, "r") as f:
                smtquery = f.read()
            for i in range(fuzz_times):
                idx = str(i).zfill(int(math.ceil(math.log10(fuzz_times))))
                smtquery_path = path.join(
                    smt_folder, smtquerys.replace(".smt2", f"_{idx}.smt2")
                )
                smtquery_resultpath = smtquery_path.replace(".smt2", ".smt2.out")
                if not path.exists(smtquery_path):
                    new_smtquery = re.sub(
                        pattern,
                        lambda m: variable_replace(m, 0.8 * i / fuzz_times + 0.2),
                        smtquery,
                    )
                    with open(smtquery_path, "w") as f:
                        f.write(new_smtquery)
                if not path.exists(smtquery_resultpath):
                    gen_model_by_z3(
                        smtquery_path,
                        smtquery_resultpath,
                        solver_timeout,
                        parallel=parallel,
                    )
                if is_result_sat(smtquery_resultpath):
                    # func_name == "check_gt"
                    sketch = get_sketch_by_func_name(builder, synthesizer, func_name)
                    models = load_smt_model(smtquery_resultpath)
                    verifiers = [(func_name, sketch, models)]
                    feasible = verify_model(bmk_dir, verifiers)
                    if feasible:
                        print(f"Result is feasible at: {smtquery_resultpath}")
                        break


def _main():
    args = parser.parse_args()
    bmk_dirs = get_bmk_dirs(args.input)
    for bmk_dir in bmk_dirs:
        if args.prepare:
            prepare(bmk_dir)
        if args.forge:
            forge_test(bmk_dir, args.timeout)
        if args.halmos:
            prepare_smtquery(bmk_dir, args.gt, args.smtdiv, args.timeout)
            halmos_test(
                bmk_dir,
                args.timeout,
                args.gt,
                args.smtdiv,
                args.start,
                args.end,
                args.solver_parallel,
            )
        if args.clean:
            clean_result(bmk_dir, args.gt, args.smtdiv, args.start, args.end)
        if args.printgt:
            print_groundtruth(bmk_dir)
        if args.verify:
            verify_result(bmk_dir, args.gt, args.smtdiv)
        if args.fuzz_smtdiv:
            prepare_smtquery(bmk_dir, True, "Models", args.timeout)
            fuzz_smtquery(
                bmk_dir,
                True,
                "Models",
                args.timeout,
                args.fuzz_times,
                args.solver_parallel,
            )


if __name__ == "__main__":
    _main()
