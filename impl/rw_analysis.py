from typing import Iterable, List, Set, Union, Tuple, Dict

import graphviz

from .utils import CornerCase
from .utils_slither import *
from .defi import Defi

RW_SET = Tuple[Set[SliVariable], Set[SliVariable]]


class RWNode:
    """
    Represents a state variable.
    """

    def __init__(self, var: SliVariable, index: int) -> None:
        self.var = var
        self._index = index

    @property
    def index(self):
        return self._index

    def __hash__(self) -> int:
        return hash(self.canonical_name)

    def __eq__(self, __o: "RWNode") -> bool:
        return __o.canonical_name == self.canonical_name

    @property
    def contract(self) -> SliContract:
        return self.var.contract

    @property
    def canonical_name(self):
        return f"{self.contract.name}.{self.var.name}"


# class RWNodeNone(RWNode):
#     """
#     Represents None state variable dependency.
#     """

#     def __init__(self, index: int) -> None:
#         super().__init__(None, index)

#     @property
#     def contract(self):
#         return None

#     @property
#     def canonical_name(self):
#         return "Entry"


class RWEdge:
    def __init__(self, source: Set[RWNode], dest: Set[RWNode], func: SliFunction) -> None:
        self.source = source
        self.dest = dest
        self.func = func

    @property
    def canonical_name(self):
        return self.func.canonical_name

    def __hash__(self) -> int:
        return hash(self.canonical_name)


class RWGraph:
    def __init__(self) -> None:
        self._freeze = False
        self.nodes: List[RWNode] = []
        self.edges: List[RWEdge] = []
        self._edge_labels: List[str] = None

    def freeze(self):
        self._freeze = True

    def unfreeze(self):
        self._freeze = False

    @property
    def edge_labels(self):
        if self._edge_labels is None:
            self._edge_labels = []
            for e in self.edges:
                if e.canonical_name in self._edge_labels:
                    continue
                self._edge_labels.append(e.canonical_name)
        return self._edge_labels

    # @property
    # def none_node(self):
    #     return self.nodes[0]

    def add_or_get_nodes(self, svs: Iterable[SliVariable]) -> Set[RWNode]:
        nodes = set()
        for v in svs:
            if v in self:
                node = self[v]
            else:
                node = self.add_node(v)
            nodes.add(node)
        return nodes

    def add_node(self, var: SliVariable) -> RWNode:
        if self._freeze:
            raise RuntimeError("Don't add item to a forzen graph.")
        node = RWNode(var, len(self.nodes))
        self.nodes.append(node)
        return node

    def add_edge(self, source: Set[RWNode], dest: Set[RWNode], func: SliFunction) -> RWEdge:
        if self._freeze:
            raise RuntimeError("Don't add item to a forzen graph.")
        edge = RWEdge(source, dest, func)
        self.edges.append(edge)
        return edge

    def __contains__(self, item: Union[SliVariable, RWNode]):
        for n in self.nodes:
            if n == item or n.var == item:
                return True
        return False

    def __getitem__(self, key: Union[SliVariable, RWNode]):
        for n in self.nodes:
            if n == key or n.var == key:
                return n
        raise KeyError(key)

    def get_node_by_name(self, name: str):
        for n in self.nodes:
            if n.canonical_name == name:
                return n
        raise KeyError(name)

    def draw_graphviz(self, output_path: str):
        graph = graphviz.Digraph(name="RWGraph")
        graph.graph_attr["root"] = "root"
        edge_labels = self.edge_labels
        graph.node(name="root", style="invis", shape="point", root="true")
        for n in self.nodes:
            graph.node("v" + str(n.index), label=n.canonical_name)
        for e in self.edges:
            mid_name = "e" + str(edge_labels.index(e.canonical_name))
            ctrt_name, func_name = e.canonical_name.split(".")
            label = (
                f'<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">\n'
                + f'<TR><TD ALIGN="CENTER">{ctrt_name}</TD></TR>\n'
                + f'<TR><TD ALIGN="CENTER">{func_name}</TD></TR>\n</TABLE>>'
            )
            graph.node(mid_name, label=label, penwidth="0")
            for s in e.source:
                graph.edge("v" + str(s.index), mid_name, dir="none", headclip="false")
            for d in e.dest:
                graph.edge(mid_name, "v" + str(d.index), tailclip="false")
        graph.save(output_path)


class RWResult:
    def __init__(self, defi: Defi) -> None:
        self.defi = defi
        self._rw_set: Dict[str, RW_SET] = {}
        self._rw_graph: RWGraph = self._init_rw_graph()
        self._ext_calls: Dict[str, List[SliFunction]] = {}

    def _init_rw_graph(self) -> RWGraph:
        static_graph = RWGraph()
        for f in self.pub_actions:
            sv_read, sv_written = self.get_func_rw_set(f)
            source_nodes = static_graph.add_or_get_nodes(sv_read)
            dest_nodes = static_graph.add_or_get_nodes(sv_written)
            if len(source_nodes) == 0 and len(dest_nodes) == 0:
                continue
            static_graph.add_edge(source_nodes, dest_nodes, f)
        return static_graph

    def track_var_without_addr(self, func: SliFunction) -> RW_SET:
        """
        This track algorithm is imprecise, because it doesn't inline the address information.
        """
        # Analyze normal storage variables usage.
        sv_read = set(func.state_variables_read)
        sv_written = set(func.state_variables_written)

        # Analyze external calls.
        for e_call_expr in func.external_calls_as_expressions:
            possible_e_calls = self.get_external_call_funcs(e_call_expr)
            if possible_e_calls is None:
                continue
            if func.name not in self._ext_calls:
                self._ext_calls[func.canonical_name] = []
            self._ext_calls[func.canonical_name].extend(possible_e_calls)
            for e_call in possible_e_calls:
                e_sv_read, e_sv_written = self.get_func_rw_set(e_call)
                sv_read = sv_read.union(e_sv_read)
                sv_written = sv_written.union(e_sv_written)

        # Analyze internal calls
        for i_call in func.internal_calls:
            if isinstance(i_call, SliFunction):
                i_sv_read, i_sv_written = self.get_func_rw_set(i_call)
                sv_read = sv_read.union(i_sv_read)
                sv_written = sv_written.union(i_sv_written)

        sv_read_n = set()
        for sv in sv_read:
            # Remove constant, immutable variables
            if sv.is_constant or sv.is_immutable:
                continue
            # Remove contract variable
            if sv.type == SliUserDefinedType:
                continue
            sv_read_n.add(sv)
        return sv_read_n, sv_written

    def print_rw_graph(self, output_path: str):
        self.rw_graph.draw_graphviz(output_path)

    def get_func_rw_set(self, func: SliFunction) -> RW_SET:
        if func.canonical_name not in self._rw_set:
            s = self.track_var_without_addr(func)
            self._rw_set[func.canonical_name] = s
        return self._rw_set[func.canonical_name]

    def get_external_call_funcs(self, e_call_expr: SliExpression) -> Optional[List[SliFunction]]:
        if not isinstance(e_call_expr.called, SliMemberAccess):
            return None
        called: SliMemberAccess = e_call_expr.called
        if isinstance(called.expression, SliTypeConversion):
            ctrt_interface = called.expression.type.type
            return self.get_function_by_interface(ctrt_interface, called.member_name)
        if isinstance(called.expression, SliIdentifier):
            called_expression: SliIdentifier = called.expression
            called_value: SliVariable = called_expression.value
            # Call a library: Math.min(a, b);
            if isinstance(called_value, SliContract):
                if called_value.is_library:
                    return None
                else:
                    raise CornerCase("TODO")
            # Call a contract initialized by variable: token.transferFrom(a, b, amt);
            # token is a state variable or local variable
            elif isinstance(called_value, SliStateVariable) or isinstance(called_value, SliLocalVariable):
                if not isinstance(called_value.type, SliUserDefinedType):
                    return None
                precise_func = self.get_function_by_canonical_name(called_value.canonical_name, called.member_name)
                if precise_func is not None:
                    return [precise_func]
                imprecise_func = self.get_function_by_method_name(called.member_name)
                return imprecise_func
            elif isinstance(called_value, SolidityVariable):
                return None
            else:
                raise CornerCase("TODO")
        type_str = getattr(called.expression, "type", None)
        if type_str is not None:
            # Inline library call: A.add(B), A.type == uint256.
            return None
        else:
            return None

    @property
    def rw_graph(self) -> RWGraph:
        return self._rw_graph
