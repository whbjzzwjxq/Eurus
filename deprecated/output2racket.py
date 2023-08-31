# from slither.core.declarations.solidity_variables import SolidityVariable, SolidityFunction
# from slither.core.declarations.modifier import Modifier
# from slither.core.declarations.function_contract import FunctionContract, Function
# from slither.core.declarations.event import Event
# from slither.core.declarations.contract import Contract
# from slither.core.variables.variable import Variable
# from slither.core.variables.function_type_variable import FunctionTypeVariable
# from slither.core.variables.local_variable import LocalVariable
# from slither.core.variables.state_variable import StateVariable
# from slither.slithir.variables.reference import ReferenceVariable
# from slither.slithir.variables.temporary import TemporaryVariable

# from slither.core.expressions.assignment_operation import AssignmentOperation as AO
# from slither.core.expressions.expression import Expression
# from slither.core.expressions.binary_operation import BinaryOperation as BO
# from slither.core.expressions.call_expression import CallExpression as CE
# from slither.core.expressions.conditional_expression import ConditionalExpression as COE
# from slither.core.expressions.elementary_type_name_expression import ElementaryTypeNameExpression as ETE
# from slither.core.expressions.literal import Literal
# from slither.core.expressions.member_access import MemberAccess as MA
# from slither.core.expressions.type_conversion import TypeConversion as TC
# from slither.core.expressions.tuple_expression import TupleExpression as TE
# from slither.core.expressions.unary_operation import UnaryOperation as UO
# from slither.core.expressions.identifier import Identifier as ID
# from slither.core.expressions.index_access import IndexAccess as IA

# from .defi import Defi
# from .utils import CornerCase


# def output_defi(defi: Defi):
#     r_defi = {"contracts": [output_ctrt(ctrt) for ctrt in defi.ctrts], "project_name": defi.config.project_name}
#     return r_defi


# def output_ctrt(ctrt: Contract):
#     r_ctrt = {
#         "functions": [output_func(func) for func in ctrt.functions if func.expressions],
#         "state_variables": [output_var(var) for var in ctrt.state_variables],
#         "name": ctrt.name,
#     }
#     return r_ctrt


# def output_func(func: Function):
#     r_func = {
#         "parameters": [output_var(para) for para in func.parameters],
#         "statements": [output_expr(expr) for expr in func.expressions],
#         "name": func.name,
#         "ret": [output_var(v) for v in func.return_values],
#     }
#     return r_func


# def output_expr(expr: Expression):
#     if isinstance(expr, AO):
#         return output_assign_op_expr(expr)
#     if isinstance(expr, BO):
#         return output_binary_op_expr(expr)
#     if isinstance(expr, CE):
#         return output_call_expr(expr)
#     if isinstance(expr, COE):
#         return output_cond_expr(expr)
#     if isinstance(expr, ETE):
#         return output_ete_expr(expr)
#     if isinstance(expr, Literal):
#         return output_literal_expr(expr)
#     if isinstance(expr, MA):
#         return output_member_access_expr(expr)
#     if isinstance(expr, TC):
#         return output_type_conversion(expr)
#     if isinstance(expr, TE):
#         return output_tuple_expr(expr)
#     if isinstance(expr, UO):
#         return output_unary_op_expr(expr)
#     if isinstance(expr, IA):
#         return output_index_access_expr(expr)
#     if isinstance(expr, ID):
#         return output_identifier_expr(expr)

#     print(f"Expression: {expr}")
#     raise CornerCase("Uncovered expression.")


# def output_assign_op_expr(expr: AO):
#     operator = str(expr.type)
#     left = output_expr(expr.expression_left)
#     right = output_expr(expr.expression_right)
#     return {"type": "assign_op", "operator": operator, "left": left, "right": right}


# def output_binary_op_expr(expr: BO):
#     operator = str(expr.type)
#     left = output_expr(expr.expression_left)
#     right = output_expr(expr.expression_right)
#     return {"type": "binary_op", "operator": operator, "left": left, "right": right}


# def output_call_expr(expr: CE):
#     return {
#         "type": "call",
#         "called": output_expr(expr.called),
#         "arguments": [output_expr(arg) for arg in expr.arguments],
#         "eth_value": output_expr(expr.call_value) if expr.call_value is not None else 0,
#     }


# def output_cond_expr(expr: COE):
#     return {}


# def output_ete_expr(expr: ETE):
#     return {}


# def output_literal_expr(expr: Literal):
#     return {"type": "literal", "value": str(expr.value)}


# def output_type_conversion(expr: TC):
#     return {"type": "type_conversion", "from_expr": output_expr(expr.expression), "to_type": str(expr.type)}


# def output_tuple_expr(expr: TE):
#     return {"type": "tuple", "exprs": [output_expr(e) for e in expr.expressions]}


# def output_member_access_expr(expr: MA):
#     return {"type": "member_access", "member_name": expr.member_name, "from_expr": output_expr(expr.expression)}


# def output_unary_op_expr(expr: UO):
#     return {"type": "unary_op", "operator": str(expr.type), "right": output_expr(expr.expression)}


# def output_index_access_expr(expr: IA):
#     left = output_expr(expr.expression_left)
#     right = output_expr(expr.expression_right)
#     return {"type": "index_access", "left": left, "right": right}


# def output_identifier_expr(expr: ID):
#     return {"type": "identifier", "value": output_var(expr.value)}


# def output_var(var: Variable):
#     if isinstance(var, SolidityVariable):
#         return {
#             "name": var.name,
#             "type": str(var.type),
#         }
#     if isinstance(var, SolidityFunction):
#         return {
#             "name": var.name,
#             "type": "solidity_function",
#         }

#     if isinstance(var, FunctionContract):
#         return {
#             "name": var.name,
#             "type": "function",
#             "contract": var.contract.name,
#         }

#     if isinstance(var, Event):
#         return {"name": var.name, "type": "event"}

#     if isinstance(var, Modifier):
#         return {
#             "name": var.name,
#             "type": "modifier",
#             "contract": var.contract.name,
#         }

#     if isinstance(var, Contract):
#         return {
#             "name": var.name,
#             "type": "contract",
#         }

#     if isinstance(var, StateVariable):
#         return {
#             "is_constant": var.is_constant,
#             "is_immutable": var.is_immutable,
#             "is_reentrant": var.is_reentrant,
#             "is_scalar": var.is_scalar,
#             "is_storage": True,
#             "location": "storage",
#             "name": var.name,
#             "type": str(var.type),
#         }

#     if isinstance(var, LocalVariable):
#         return {
#             "is_constant": var.is_constant,
#             "is_immutable": var.is_immutable,
#             "is_reentrant": var.is_reentrant,
#             "is_scalar": var.is_scalar,
#             "is_storage": var.is_storage,
#             "location": var.location,
#             "name": var.name,
#             "type": str(var.type),
#         }

#     if isinstance(var, ReferenceVariable):
#         return {
#             "is_constant": var.is_constant,
#             "is_immutable": var.is_immutable,
#             "is_reentrant": var.is_reentrant,
#             "is_scalar": var.is_scalar,
#             "is_storage": False,
#             "location": "reference",
#             "name": var.name,
#             "type": str(var.type),
#         }

#     if isinstance(var, TemporaryVariable):
#         return {
#             "is_constant": var.is_constant,
#             "is_immutable": var.is_immutable,
#             "is_reentrant": var.is_reentrant,
#             "is_scalar": var.is_scalar,
#             "is_storage": False,
#             "location": "temporary",
#             "name": var.name,
#             "type": str(var.type),
#         }

#     print(f"Variable: {var}")
#     raise CornerCase("Uncovered variable.")
