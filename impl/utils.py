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


def gen_result_paths(result_path: str, only_gt: bool, smtdiv: str, sketch_num: int):
    """
    returns list of func_name, output_path, err_path, smt_folder
    """
    result_paths: List[Tuple[str, str, str, str]] = []

    if smtdiv == "All":
        suffix = ""
        suffix_smt = ""
    elif smtdiv == "Models":
        suffix = "_smtdiv_models"
        suffix_smt = "_smtdiv_models"
    elif smtdiv == "None":
        suffix = "_smtdiv_none"
        suffix_smt = "_smtdiv_none"

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


def call_halmos(
    project_name: str,
    func_name: str,
    timeout: int,
    output_path: str,
    err_path: str,
    smt_folder: str,
    *extra_halmos_options,
    print_cmd_only: bool = False,
):
    """
    timeout count as seconds.
    """
    cmds = [
        "halmos",
        "-vvvvv",
        "--function",
        f"{func_name}",
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
        "--dump-smt-queries",
        smt_folder,
        *extra_halmos_options,
    ]
    if print_cmd_only:
        print(" ".join(cmds))
        return
    proc, err = None, None
    try:
        proc = run(cmds, text=True, capture_output=True)
    # except TimeoutExpired:
    #     err = {"error": "timeout", "details": ""}
    except Exception as e:
        err = {"error": "unknown", "details": str(e)}
    if proc:
        print(proc.stdout, proc.stderr)
    if err:
        with open(err_path, "w") as f:
            json.dump(err, f)
