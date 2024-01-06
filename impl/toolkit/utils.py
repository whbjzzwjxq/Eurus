import json
import os
import re
from os import path
from typing import List, Tuple

from impl.toolkit.const import ZFILL_SIZE

func_name_regex = re.compile(r"function (.*?)\(")


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
