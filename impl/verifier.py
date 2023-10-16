import json
import os

from os import path
from subprocess import run
from typing import List, Tuple

from .dsl import Sketch
from .benchmark_builder import BenchmarkBuilder
from .utils import prepare_subfolder


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
        # Keep consistent with Halmos
        "--root",
        os.getcwd(),
        "--extra-output",
        "storageLayout",
        "metadata",
    ]
    try:
        out = run(cmds, text=True, capture_output=True)
    except Exception as err:
        print(err)
        return False
    lines = out.stdout.splitlines()
    try:
        result = json.loads(lines[-1])
        result = list(result.values())[0]["test_results"]
    except Exception as err:
        print(out.stderr)
        raise err
    result.pop("test_gt()")
    verified_sketches = []
    for k, v in result.items():
        if v["status"] == "Success":
            verified_sketches.append(k)
        else:
            print(f"Contrat {k}: failed, reason: {v.get('reason', '')}")
    verified_sketches = sorted(verified_sketches)
    os.remove(verify_sol_path)
    return len(verified_sketches) != 0


def verify_model_on_anvil(address: str, ):
    pass
