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
ATTACK_CONTRACT_CLS = "AttackContract"
DEAD = "dead"
OWENR = "owner"

ctrt_name_regex = re.compile(r"\ncontract (\w+)\s+{")
func_name_regex = re.compile(r"function (.*?)\(")


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


def gen_result_paths(result_path: str, only_gt: bool, tool_name: str, sketch_num: int, suffix: str):
    """
    returns list of func_name, output_path, err_path, smt_folder
    """
    result_paths: List[Tuple[str, str, str, str]] = []

    if only_gt:
        idx = "gt"
        output = path.join(result_path, f"{tool_name}_out_{idx}{suffix}.json")
        err_output = path.join(result_path, f"{tool_name}_err_{idx}{suffix}.json")
        smt_output = path.join(result_path, f"{tool_name}_smt_{idx}{suffix}")
        result_paths = [("check_gt", output, err_output, smt_output)]
    else:
        for i in range(sketch_num):
            idx = str(i).zfill(ZFILL_SIZE)
            output = path.join(result_path, f"{tool_name}_out_{idx}{suffix}.json")
            err_output = path.join(result_path, f"{tool_name}_err_{idx}{suffix}.json")
            smt_output = path.join(result_path, f"{tool_name}_smt_{idx}{suffix}")
            result_paths.append((f"check_cand{idx}", output, err_output, smt_output))
    return result_paths


def update_record(result_path: str, update: dict):
    record_path = path.join(result_path, "record.json")
    current = load_record(result_path)
    current.update(update)

    with open(record_path, "w") as f:
        json.dump(current, f)


def load_record(result_path: str) -> dict:
    record_path = path.join(result_path, "record.json")
    if not path.exists(record_path):
        current = {}
    else:
        try:
            with open(record_path, "r") as f:
                current = json.load(f)
        except Exception as err:
            current = {}
    return current


def query_z3(smtquery: str, timeout: int = 21600, mem_max: int = 31457280, parallel: bool = False):
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
                raise ValueError(f"Benchmark path should be a directory, current is: {bmk_dir}")
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
                arg_candidates.append([model[f"p_amt{j}_uint256"] for j in range(len(model))])
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
