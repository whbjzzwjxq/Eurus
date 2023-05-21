from os import listdir, path
from typing import List, Tuple

from slither.slither import Slither

from .utils import init_config, Config, CornerCase


def gen_slither_contracts(ctrt_dir: str) -> Tuple[List["Slither"], Config]:
    root_dir = path.abspath(path.join(__file__, "../.."))
    work_dir = path.abspath(path.join(root_dir, "benchmarks"))
    ctrt_slis = []
    config = init_config(ctrt_dir)
    # Parse all contracts.
    for file_name in listdir(ctrt_dir):
        if (not file_name.endswith(".sol")) or ("Attacker" in file_name) or file_name.endswith(".t.sol"):
            continue
        ctrt_path = path.abspath(path.join(ctrt_dir, file_name))
        solc_args = [
            f"--base-path {work_dir}",
            f"--include-path ./benchmarks/{config.project_name}",
            f"--include-path ./contracts",
        ]
        sli = Slither(ctrt_path, solc_args=" ".join(solc_args), solc_working_dir=work_dir)
        ctrt_slis.append(sli)
    return ctrt_slis, config

def get_func(ctrt_slis: List["Slither"], ctrt_name: str, func_name: str):
    for ctrt_sli in ctrt_slis:
        ctrts = ctrt_sli.get_contract_from_name(ctrt_name)
        if len(ctrts) == 0:
            continue
        if len(ctrts) > 1:
            raise CornerCase(f"Duplicated contract name: {ctrt_name}")
        ctrt = ctrts[0]
        for f in ctrt.functions:
            if f.name == func_name:
                return f
    raise ValueError(f"Unknown function: {func_name}")
