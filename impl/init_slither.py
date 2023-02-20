from os import listdir, path
from typing import List, Tuple

from slither.slither import Slither

from .utils import Config, SliContract, init_config


def gen_slither_contracts(ctrt_dir: str) -> Tuple[List["SliContract"], Config]:
    root_dir = path.abspath(path.join(__file__, "../.."))
    work_dir = path.abspath(path.join(root_dir, "benchmarks"))
    ctrt_slis = []
    config = init_config(ctrt_dir)
    for file_name in listdir(ctrt_dir):
        if (not file_name.endswith(".sol")) or ("Attacker" in file_name):
            continue
        pure_name = file_name.replace(".sol", "")
        ctrt_path = path.abspath(path.join(ctrt_dir, file_name))
        solc_args = [
            f"--base-path {work_dir}",
            f"--include-path ./examples/{config.project_name}",
            f"--include-path ./contracts",
        ]
        slither_obj = Slither(ctrt_path, solc_args=" ".join(solc_args), solc_working_dir=work_dir)
        for ctrt_name in config.contracts[pure_name]:
            ctrt_sli = slither_obj.get_contract_from_name(ctrt_name)[0]
            ctrt_slis.append(ctrt_sli)
    return ctrt_slis, config
