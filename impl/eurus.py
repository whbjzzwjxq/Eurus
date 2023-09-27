from z3 import *

from typing import Callable


def interpret_div(node: Ast) -> Ast:
    return replace_nodes_dfs(
        node, lambda n: n.decl().name() == "evm_bvudiv", lambda n: UDiv(*n.children())
    )


def replace_nodes_dfs(
    node: Ast, filter: Callable[[Ast], bool], action: Callable[[Ast], Ast]
) -> Ast:
    if is_const(node):
        return node
    elif is_ast(node):
        args = [replace_nodes_dfs(arg, filter, action) for arg in node.children()]
        if filter(node):
            node = action(node)
        return node.decl()(*args)
