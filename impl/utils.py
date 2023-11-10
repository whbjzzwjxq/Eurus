import json
import os
import random
import re
import time
from os import path
from subprocess import TimeoutExpired, run
from typing import List, Optional, Tuple

ZFILL_SIZE = 3
MAX_SKETCH_NUM = 10 ** (ZFILL_SIZE - 1)

SEED = 20230222
random.seed(SEED)

ether = 10**18
gwei = 10**10
max_uint256 = 2**256 - 1

SENDER = "msg.sender"
ATTACKER = "attacker"
DEAD = "dead"
OWENR = "owner"

ctrt_name_regex = re.compile(r"\ncontract (\w+)\s+{")


def decimal_to_n_base(decimal: int, base: int) -> List[int]:
    result = []

    while decimal > 0:
        decimal, remainder = divmod(decimal, base)
        result.append(remainder)

    result.reverse()
    return result


def parse_smt_output(key: str, lines: List[str]) -> Optional[str]:
    result = None
    for idx, l in enumerate(lines):
        if key in l:
            result = lines[idx + 1].strip().removesuffix(")").replace("#", "0")
            break
    return result


class CompilerError(BaseException):
    """An error happened during code compilation."""

    pass


class CornerCase(BaseException):
    """A corner case has been reached."""

    pass


class FrozenObject(RuntimeError):
    """Don't add item in a freeze graph."""

    pass


def gen_result_paths(result_path: str, only_gt: bool, smtdiv: str, sketch_num: int, suffix_spec: str):
    """
    returns list of func_name, output_path, err_path, smt_folder
    """
    result_paths: List[Tuple[str, str, str, str]] = []

    if smtdiv == "All":
        suffix = ""
        suffix_smt = ""
    else:
        suffix = f"_smtdiv_{smtdiv.lower()}"
        suffix_smt = f"_smtdiv_{smtdiv.lower()}"
    
    suffix += suffix_spec
    suffix_smt += suffix_spec

    if only_gt:
        idx = "gt"
        output = path.join(result_path, f"halmos_out{idx}{suffix}.json")
        err_output = path.join(result_path, f"halmos_err{idx}{suffix}.json")
        smt_output = path.join(result_path, f"smt_{idx}{suffix_smt}")
        if not path.exists(smt_output):
            os.mkdir(smt_output)
        result_paths = [("check_gt", output, err_output, smt_output)]
    else:
        for i in range(sketch_num):
            idx = str(i).zfill(ZFILL_SIZE)
            output = path.join(result_path, f"halmos_out{idx}{suffix}.json")
            err_output = path.join(result_path, f"halmos_err{idx}{suffix}.json")
            smt_output = path.join(result_path, f"smt_{idx}{suffix_smt}")
            if not path.exists(smt_output):
                os.mkdir(smt_output)
            result_paths.append((f"check_cand{idx}", output, err_output, smt_output))
    return result_paths


def query_z3(
    smtquery: str, timeout: int = 21600, mem_max: int = 31457280, parallel: bool = False
):
    timer = time.perf_counter()
    cmds = [
        "z3",
        "--model",
        f"-T:{timeout}",
        # f"memory_max_size={mem_max}",
        # f"parallel.enable={str(parallel).lower()}",
        smtquery,
    ]
    print(" ".join(cmds))
    timecost, proc, err = 0, None, ""
    try:
        proc = run(cmds, timeout=timeout, check=True, text=True, capture_output=True)
    except TimeoutExpired:
        err = f"timeout: {timeout}"
    except Exception as e:
        err = str(e)
    timecost = time.perf_counter() - timer
    return timecost, proc, err


def gen_model_by_z3(
    smtquery_path: str,
    smtquery_resultpath: str,
    timeout: int = 21600,
    mem_max: int = 31457280,
    parallel: bool = False,
):
    timecost, proc, err = query_z3(smtquery_path, timeout, mem_max, parallel)
    if err != "":
        with open(smtquery_resultpath, "w") as f:
            f.write(err)
        return
    results = proc.stdout.strip().split("\n", 1)
    status = results[0]
    if status == "unsat":
        # Impossible
        with open(smtquery_resultpath, "w") as f:
            f.write(f"{status}\n")
            f.write(f"{timecost}\n")
        return
    # status == "sat"
    assert status == "sat"
    model = results[1]
    with open(smtquery_resultpath, "w") as f:
        f.write(f"{status}\n")
        f.write(f"{timecost}\n")
        f.write(model)


def is_result_sat(smtquery_resultpath: str):
    with open(smtquery_resultpath, "r") as f:
        status = f.readline().strip()
        return status == "sat"


def prepare_subfolder(bmk_dir: str) -> Tuple[str, str]:
    cache_path = path.join(bmk_dir, ".cache")
    if not path.exists(cache_path):
        os.mkdir(cache_path)
    result_path = path.join(bmk_dir, "result")
    if not path.exists(result_path):
        os.mkdir(result_path)
    return cache_path, result_path


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
