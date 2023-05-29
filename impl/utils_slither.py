import os
from os import path
from typing import List

from slither.slither import Slither
from slither.core.declarations.contract import Contract as SliContract
from slither.core.declarations.function import Function as SliFunction
from slither.core.declarations.solidity_variables import \
    SolidityFunction as SolFunction
from slither.core.variables.variable import Variable as SliVariable
from slither.core.variables.state_variable import StateVariable as SliStateVariable
from slither.core.expressions.member_access import MemberAccess

from .utils import CornerCase, SolCallType


def gen_slither_contracts(bmk_dir: str) -> List[Slither]:
    bmk_dir = path.abspath(bmk_dir)
    ctrt_slis = []
    # Parse all contracts.
    for file_name in os.listdir(bmk_dir):
        if (not file_name.endswith(".sol")) or ("Handler" in file_name) or file_name.endswith(".t.sol"):
            continue
        ctrt_path = path.abspath(path.join(bmk_dir, file_name))
        solc_args = [
            f"--base-path {bmk_dir}",
            f"--include-path {bmk_dir}",
            f"--include-path ../../lib/contracts",
        ]
        solc_args = " ".join(solc_args)
        sli = Slither(ctrt_path, solc_args=solc_args, solc_working_dir=bmk_dir)
        ctrt_slis.append(sli)
    return ctrt_slis


def get_func(ctrt_slis: List[Slither], ctrt_name: str, func_name: str):
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


def get_call_type(called: MemberAccess) -> SolCallType:
    pass
