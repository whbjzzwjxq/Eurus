from os import path

from slither.core.declarations.contract import Contract as SliContract
from slither.core.declarations.function import Function as SliFunction
from slither.core.declarations.modifier import Modifier as SliModifier
from slither.core.declarations.solidity_variables import SolidityVariable
from slither.core.declarations.solidity_variables import SolidityFunction
from slither.core.declarations.event import Event as SliEvent
from slither.core.declarations.function_contract import FunctionContract as SliFunctionContract
from slither.core.expressions.expression import Expression as SliExpression
from slither.core.expressions.identifier import Identifier as SliIdentifier
from slither.core.expressions.member_access import MemberAccess as SliMemberAccess
from slither.core.expressions.new_elementary_type import NewElementaryType as SliNewElementaryType
from slither.core.expressions.new_array import NewArray as SliNewArray
from slither.core.expressions.new_contract import NewContract as SliNewContract
from slither.core.expressions.type_conversion import TypeConversion as SliTypeConversion
from slither.core.expressions.call_expression import CallExpression as SliCallExpression
from slither.core.expressions.tuple_expression import TupleExpression as SliTupleExpression
from slither.core.expressions.index_access import IndexAccess as SliIndexAccess
from slither.core.expressions.literal import Literal as SliLiteral
from slither.core.solidity_types import ArrayType as SliArrayType
from slither.core.solidity_types import ElementaryType as SliElementaryType
from slither.core.solidity_types import MappingType as SliMappingType
from slither.core.solidity_types import UserDefinedType as SliUserDefinedType
from slither.core.variables.state_variable import StateVariable as SliStateVariable
from slither.core.variables.variable import Variable as SliVariable
from slither.core.variables.local_variable import LocalVariable as SliLocalVariable
from slither.slither import Slither
from slither.analyses.data_dependency.data_dependency import is_dependent


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
        f"@uniswapv2/={lib_dir}/contracts/@uniswapv2/",
        f"forge-std={lib_dir}/forge-std/src",
        f"ds-test={lib_dir}/forge-std/lib/ds-test/src",
    ]
    solc_remaps = " ".join(solc_remaps)
    sli = Slither(ctrt_path, solc_args=solc_args, solc_working_dir=root_dir, solc_remaps=solc_remaps)
    return sli
