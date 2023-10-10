import argparse
import json
import os
import shutil
import time
from os import path
from subprocess import CalledProcessError, TimeoutExpired, run

from impl.eurus import eurus_test

from impl.solidity_builder import BenchmarkBuilder, get_sketch_by_func_name
from impl.synthesizer import Synthesizer
from impl.utils import (
    gen_result_paths,
    get_bmk_dirs,
    load_smt_model,
    prepare_subfolder,
    resolve_project_name,
)
from impl.verifier import verify_model
from impl.halmos import exec_halmos

parser = argparse.ArgumentParser()

parser.add_argument(
    "-i",
    "--input",
    type=str,
    action="append",
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
    "-vr",
    "--verify-result-path",
    help="The result path of verification.",
    default="",
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
    "-e",
    "--eurus",
    help="Use eurus to solve the groundtruth.",
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
    "-ps",
    "--printsmt",
    help="Print SMTQuery generated by Halmos",
    action="store_true",
)

# Parameters for evaluation.
parser.add_argument(
    "--timeout",
    help="Set the total timeout.",
    type=int,
    default=3600 * 2,
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
    choices=[
        "All",
        "Models",
        "None",
        "DataDepDiv",
        "CtrlDepDiv",
        "DataDepOnly",
        "CtrlDepOnly",
        "HackFirstDev",
    ],
    default="All",
)

parser.add_argument(
    "--suffix",
    help="Special suffix to output",
    default="",
)

parser.add_argument(
    "--unsat-core",
    help="Use unsat-core based solution.",
    action="store_true",
)

parser.add_argument(
    "--solver",
    help="Used Solver.",
    choices=["z3", "gp"],
)


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
        "--extra-output",
        "storageLayout",
        "metadata",
        "--root",
        os.getcwd(),
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
        "-vvv",
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


def clean_result(
    bmk_dir: str, only_gt: bool, smtdiv: str, start: int, end: int, suffix_spec: str
):
    builder = BenchmarkBuilder(bmk_dir)
    synthesizer = Synthesizer(builder.config)
    _, result_path = prepare_subfolder(bmk_dir)
    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates), suffix_spec
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


def verify_result(
    bmk_dir: str, only_gt: bool, smtdiv: str, verify_result_path: str, suffix_spec: str
):
    builder = BenchmarkBuilder(bmk_dir)
    synthesizer = Synthesizer(builder.config)
    _, result_path = prepare_subfolder(bmk_dir)
    project_name = resolve_project_name(bmk_dir)

    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates), suffix_spec
    )

    verifiers = []

    for func_name, output_path, _, _ in result_paths:
        output_path = verify_result_path if verify_result_path != "" else output_path
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


def call_halmos(
    bmk_dir: str,
    project_name: str,
    func_name: str,
    timeout: int,
    output_path: str,
    err_path: str,
    *extra_halmos_options,
):
    """
    timeout count as seconds.
    """
    args = [
        "-vvvvv",
        "--function",
        f"{func_name}",
        "--bmk-dir",
        f"{bmk_dir}",
        "--contract",
        f"{project_name}Test",
        "--forge-build-out",
        ".cache",
        "--print-potential-counterexample",
        # Use default setting.
        # "--solver-timeout-branching",
        # "100000",
        "--solver-timeout-assertion",
        f"{timeout * 1000}",
        "--json-output",
        output_path,
        *extra_halmos_options,
    ]
    print(" ".join(args))
    exec_halmos(*args)


def halmos_test(
    bmk_dir: str,
    args,
):
    timeout: int = args.timeout
    only_gt: bool = args.gt
    smtdiv: str = args.smtdiv
    start: int = args.start
    end: int = args.end
    print_only: bool = args.printsmt
    suffix_spec: str = args.suffix
    builder = BenchmarkBuilder(bmk_dir)
    synthesizer = Synthesizer(builder.config)
    project_name = resolve_project_name(bmk_dir)
    _, result_path = prepare_subfolder(bmk_dir)

    result_paths = gen_result_paths(
        result_path, only_gt, smtdiv, len(synthesizer.candidates), suffix_spec
    )

    result_paths = result_paths[start:end]

    for func_name, output_path, err_path, smt_folder in result_paths:
        if not print_only and (path.exists(output_path) or path.exists(err_path)):
            print(f"Previous result is here, {func_name} had been tested!")
            continue
        extra_halmos_options = [
            f"--smtdiv={smtdiv}",
            "--dump-smt-queries",
            smt_folder,
        ]
        if print_only:
            extra_halmos_options = [
                *extra_halmos_options,
                "--solver-only-dump",
            ]
        if args.unsat_core:
            extra_halmos_options.append(
                "--unsat-core",
            )

        call_halmos(
            bmk_dir,
            project_name,
            func_name,
            timeout,
            output_path,
            err_path,
            *extra_halmos_options,
        )


def _main():
    args = parser.parse_args()
    bmk_dirs = get_bmk_dirs(args.input)
    for bmk_dir in bmk_dirs:
        if args.prepare:
            prepare(bmk_dir)
        if args.forge:
            forge_test(bmk_dir, args.timeout)
        if args.clean:
            clean_result(
                bmk_dir, args.gt, args.smtdiv, args.start, args.end, args.suffix
            )
        if args.printgt:
            print_groundtruth(bmk_dir)
        if args.verify:
            verify_result(
                bmk_dir, args.gt, args.smtdiv, args.verify_result_path, args.suffix
            )
        if args.halmos or args.printsmt:
            halmos_test(bmk_dir, args)
        if args.eurus:
            eurus_test(bmk_dir, args)


if __name__ == "__main__":
    _main()
