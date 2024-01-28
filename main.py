import argparse
import os
from os import path
import random
from subprocess import CalledProcessError, run
import time
from impl.dsl.financial_constraints import SCALE, gen_attack_goal

from impl.synthesis.sol_builder import BenchmarkBuilder
from impl.synthesis.solver import VAR, FinancialExecution, eurus_solve, setup_solver
from impl.synthesis.synthesizer import Synthesizer
from impl.toolkit.foundry import LazyStorage, deploy_contract, init_anvil
from impl.toolkit.utils import gen_result_paths, get_bmk_dirs, prepare_subfolder, resolve_project_name, update_record

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
    help="Prepare a .sol file with exploit candidates.",
    action="store_true",
)

parser.add_argument(
    "-e",
    "--exec",
    help="Use Foray to generate the exploit.",
    action="store_true",
)

parser.add_argument(
    "-s",
    "--statistic",
    help="Print statistic.",
    action="store_true",
)

parser.add_argument(
    "-pg",
    "--printgt",
    help="Print groundtruth.",
    action="store_true",
)

# Parameters for evaluation.
parser.add_argument(
    "--timeout",
    help="Set the timeout for each sketch.",
    type=int,
    default=300 * 1000,
)

parser.add_argument(
    "--suffix",
    help="Special suffix to output",
    default="",
)

parser.add_argument(
    "--onlygt",
    help="Only process the ground truth.",
    action="store_true",
    default=False,
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
    default="z3",
)


def prepare(bmk_dir: str):
    project_name = resolve_project_name(bmk_dir)
    cache_path, result_path = prepare_subfolder(bmk_dir)
    output_file = path.join(bmk_dir, f"{project_name}.t.sol")
    print(f"Output path is: {output_file}")
    if path.exists(output_file):
        os.remove(output_file)
    builder = BenchmarkBuilder(bmk_dir)
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
        "-vv",
        "--fork-url",
        builder.config.blockchain,
        "--fork-block-number",
        str(builder.config.blocknumber),
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
    print("Execute: ", " ".join(cmds))
    try:
        out = run(cmds, text=True, check=True, capture_output=True)
    except Exception as err:
        if isinstance(err, CalledProcessError):
            print(err.stderr, err.stdout)
        print(f"\n\nBenchmark: {bmk_dir} ground truth doesn't work!")
        raise err


def foray_test(bmk_dir: str, args):

    # Setup parameters
    timeout: int = args.timeout
    suffix_spec: str = args.suffix
    only_gt: bool = args.onlygt
    global Z3_OR_GB
    Z3_OR_GB = "z3"
    VAR.clear_cache()

    # Setup builder, config, etc.
    builder = BenchmarkBuilder(bmk_dir)
    config = builder.config
    anvil_proc = init_anvil(config.blockchain, config.blocknumber)

    # 
    output_file = path.join(bmk_dir, f"{project_name}_candidates.t.sol")
    cache_file = path.join(cache_path, f"function_summary.pkl")

    timer = time.perf_counter()
    enumerator = Synthesizer(bmk_dir, cache_file)
    candidates = enumerator.infer_candidates()

    timecost = time.perf_counter() - timer

    builder.output_with_candidates(candidates, output_file)

    result = {"sketchgen_timecost": timecost}

    update_record(result_path, result)

    # Format
    cmd = [
        "npx",
        "prettier",
        "--write",
        "--plugin=prettier-plugin-solidity",
        f"{output_file}",
    ]
    run(cmd, text=True, check=True)

    timer = time.perf_counter()

    project_name = resolve_project_name(bmk_dir)
    cache_path, result_path = prepare_subfolder(bmk_dir)

    cache_file = path.join(cache_path, f"function_summary.pkl")
    synthesizer = Synthesizer(bmk_dir, cache_file)
    config = synthesizer.config

    timestamp = synthesizer.config.blocknumber

    anvil_proc = init_anvil(timestamp=int(timestamp) - 1)

    token, amount = config.attack_goal

    attack_goal = gen_attack_goal(token, amount, SCALE)

    try:
        snapshot_id, ctrt_name2addr = deploy_contract(bmk_dir)

        init_state = LazyStorage(bmk_dir, ctrt_name2addr, timestamp)

        result_paths = gen_result_paths(result_path, only_gt, "eurus", len(synthesizer.candidates), suffix_spec)
        result_paths = result_paths[start:end]

        for func_name, output_path, _, _ in result_paths:
            print(f"Solving: {func_name}")
            # Avoid stuck
            stuck_dict = {
                "EGD": [
                    "check_cand001",
                ],
                "MUMUG": [
                    "check_cand003",
                ],
                "Haven": [
                    "check_cand011",
                ],
            }
            stuck_list = stuck_dict.get(project_name, [])
            if func_name in stuck_list:
                # ms -> s
                timer -= timeout / 1000
                continue
            VAR.clear_cache()
            solver = setup_solver(timeout)
            origin_sketch = builder.get_sketch_by_func_name(func_name, synthesizer.candidates)
            exec = FinancialExecution(origin_sketch, solver, init_state, attack_goal)

            exec.execute()

            feasible = False
            idx = 0
            while not feasible:
                if Z3_OR_GB:
                    print(solver.sexpr())
                feasible = eurus_solve(solver, bmk_dir, func_name, ctrt_name2addr, output_path, exec, idx)
                if feasible == "UNSAT":
                    feasible = False
                    break
                if feasible:
                    break
                refinements = refine_constraints.get(project_name, [])
                if len(refinements) <= idx:
                    break
                refinement = refinements[idx]
                for s_sig, v in refinement.items():
                    s_idx = origin_sketch.get_action_idx_by_sig(s_sig)
                    if s_idx == -1:
                        raise ValueError(f"Unknown function signature: {s_sig} in sketch.")
                    for f_idx, func in enumerate(v):
                        exec.gen_constraint(s_idx, func, f"Ref{idx}_Step{s_idx}_{f_idx}")
                idx += 1
            if feasible:
                break
        if not only_gt:
            timecost = time.perf_counter() - timer
            new_record = {
                f"eurus_{suffix_spec}_solve_timecost": timecost,
                f"eurus_{suffix_spec}_all_timecost": timecost + synthesizer.timecost,
            }
            update_record(result_path, new_record)
        anvil_proc.kill()
    except Exception as err:
        anvil_proc.kill()
        raise err
    pass


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


def _main():
    SEED = 20230222
    random.seed(SEED)
    args = parser.parse_args()
    bmk_dirs = get_bmk_dirs(args.input)
    for bmk_dir in bmk_dirs:
        if args.prepare:
            prepare(bmk_dir)
        if args.exec:
            foray_test(bmk_dir, args)
        if args.printgt:
            print_groundtruth(bmk_dir)


if __name__ == "__main__":
    _main()
