from typing import Optional
from os import path

from slither.slither import Slither
from slither.core.declarations.contract import Contract as SliContract
from slither.core.declarations.function import Function as SliFunction
from slither.core.variables.variable import Variable as SliVariable
from slither.core.variables.state_variable import StateVariable as SliStateVariable
from slither.core.expressions.expression import Expression as SliExpression
from slither.core.expressions.member_access import MemberAccess as SliMemberAccess
from slither.core.expressions.identifier import Identifier as SliIdentifier


def gen_slither(bmk_dir: str) -> Slither:
    root_dir = path.abspath(path.join(__file__, "../.."))
    bmk_dir = path.abspath(bmk_dir)
    lib_dir = "./lib"
    ctrt_path = path.join(bmk_dir, f"{path.basename(bmk_dir)}.t.sol")
    # Parse the XXX.t.sol.
    solc_args = [
        f"--base-path {root_dir}",
        f"--include-path {bmk_dir}",
        f"--include-path {lib_dir}",
    ]
    solc_args = " ".join(solc_args)
    solc_remaps = [
        f"@openzeppelin/={lib_dir}/contracts/@openzeppelin/",
        f"@utils/={lib_dir}/contracts/@utils/",
        f"forge-std={lib_dir}/forge-std/src",
        f"ds-test={lib_dir}/forge-std/lib/ds-test/src"
    ]
    solc_remaps = " ".join(solc_remaps)
    sli = Slither(ctrt_path, solc_args=solc_args,
                  solc_working_dir=root_dir, solc_remaps=solc_remaps)
    return sli


def get_function_from_name(ctrt: SliContract, name: str) -> Optional[SliFunction]:
    return next(
        (f for f in ctrt.functions if f.name ==
         # Make sure it is the implementation instead of interface
         name and f.canonical_name.startswith(ctrt.name)),
        None,
    )
