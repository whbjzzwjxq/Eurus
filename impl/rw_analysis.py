from typing import Iterable, List, Set, Union

import graphviz

from .utils_slither import SliContract, SliFunction, SliVariable


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
