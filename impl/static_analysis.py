from typing import List

from .asset_flow_graph import AssetFlowGraph, ctrt_global

from slither.core.solidity_types.user_defined_type import UserDefinedType
from slither.core.expressions.member_access import MemberAccess
from .utils import SolFunction, SliContract, SliFunction, SliVariable, Config, CornerCase


def init_temp_variable(name: str, ctrt: "SliContract") -> "SliVariable":
    variable = SliVariable()
    variable.name = name
    variable.contract = ctrt
    return variable

def judge_called_type(called: "MemberAccess"):
    # Case 1 means: payable(address).transfer(...).
    # Case 2 means: Contract(address).call(...).
    # Case 3 means: Var.call(...) and Var is a contract.
    called_expr_type = called.expression.type
    if called_expr_type is not None:
        if hasattr(called_expr_type, "name"):
            if called_expr_type.name == "address":
                return 1
            else:
                raise CornerCase
        if isinstance(called_expr_type, UserDefinedType):
            return 2
        else:
            raise CornerCase
    else:
        return 3


def analysis_read_and_write(ctrt_slis: List["SliContract"], config: "Config") -> "AssetFlowGraph":
    static_graph = AssetFlowGraph()

    temp_vars = {}

    def track_var(func: "SliFunction"):
        # Analyze normal storage variables usage.
        l_state_vars_read = set([r for r in func.state_variables_read if not r.is_immutable])
        l_state_vars_written = set(func.state_variables_written)

        # Analyze solidity transfer.
        for e_call_expr in func.external_calls_as_expressions:
            called: "MemberAccess" = e_call_expr.called
            called_type = judge_called_type(called)
            if called_type == 1:
                if called.member_name == "transfer":
                    dest_name = called.expression.expression.value.name
                    if dest_name == "msg.sender":
                        dest_name = "attacker"
                    dest_name = f"address({dest_name}).balance"
                    source_name = f"address({ctrt_sli.name}).balance"
                    if dest_name in temp_vars:
                        temp_var0 = temp_vars[dest_name]
                    else:
                        temp_var0 = init_temp_variable(name=dest_name, ctrt=ctrt_global)
                        temp_vars[dest_name] = temp_var0
                    if source_name in temp_vars:
                        temp_var1 = temp_vars[source_name]
                    else:
                        temp_var1 = init_temp_variable(name=source_name, ctrt=ctrt_global)
                        temp_vars[source_name] = temp_var1
                    l_state_vars_written.update([temp_var0, temp_var1])
                else:
                    raise ValueError("Unknown member to address.")
            else:
                if called_type == 2:
                    ctrt_name = called.expression.type.type.name
                    func_name = called.member_name
                else:
                    ctrt_name = called.expression.value.signature[2]
                    func_name = called.member_name
                ctrt_name = config.interface2contract.get(ctrt_name, ctrt_name)
                target_func = seek_func(ctrt_name, func_name)
                i_state_vars_read, i_state_vars_written = track_var(target_func)
                l_state_vars_read = l_state_vars_read.union(i_state_vars_read)
                l_state_vars_written = l_state_vars_written.union(i_state_vars_written)

        # Track internal function calls
        for i_call in func.internal_calls:
            if isinstance(i_call, SliFunction):
                i_state_vars_read, i_state_vars_written = track_var(i_call)
                l_state_vars_read = l_state_vars_read.union(i_state_vars_read)
                l_state_vars_written = l_state_vars_written.union(i_state_vars_written)
        return l_state_vars_read, l_state_vars_written

    for ctrt_sli in ctrt_slis:
        for f in ctrt_sli.functions:
            if f.is_constructor or f.is_constructor_variables:
                continue
            if f.pure or f.view or f.visibility in ("internal", "private"):
                continue

            all_state_vars_read, all_state_vars_written = track_var(f)
            for r in all_state_vars_read:
                if r in static_graph:
                    source_node = static_graph[r]
                else:
                    source_node = static_graph.add_node(r)
                for w in all_state_vars_written:
                    if w in static_graph:
                        dest_node = static_graph[w]
                    else:
                        dest_node = static_graph.add_node(w)
                    static_graph.add_edge(source_node, dest_node, f)
            if len(all_state_vars_read) == 0:
                for w in all_state_vars_written:
                    if w in static_graph:
                        dest_node = static_graph[w]
                    else:
                        dest_node = static_graph.add_node(w)
                    static_graph.add_edge(
                        static_graph.entry_node, dest_node, f)
    for n in static_graph.nodes:
        if n.contract == ctrt_global:
            func = SolFunction("Global", "transfer", "(address,uint256)")
            static_graph.add_edge(static_graph.entry_node, n, func)

    return static_graph
