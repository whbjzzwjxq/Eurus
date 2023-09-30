from z3 import *

from typing import Callable

def slide_window_udiv(a, b):
    hi = 160
    lo = 85
    width = 64
    ap = Extract(hi - 1, hi - width, a)
    bp = Extract(lo - 1, lo - width, b)
    r = ZeroExt(256 - width, UDiv(ap, bp)) << (hi - lo)
    return r

def hack_interpret_div_discover(node: Ast) -> Ast:
    if is_const(node):
        return node
    args = [hack_interpret_div_discover(arg) for arg in node.children()]
    node = node.decl()(*args)
    if node.decl().name() == "evm_bvudiv":
        # (let ((?x60661 (evm_bvudiv ?x60644 ?x60444)))
        a = node.children()[0]
        b = node.children()[1]
        # if a.decl().name() == "bvadd" and b.decl().name() == "bvadd":
        #     node = slide_window_udiv(a, b)
        # else:
        #     node = UDiv(a, b)
        node = UDiv(a, b)
    return node


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
