from typing import List, Tuple, Set
from os import path

from .utils import SliVariable, SliFunction, SliContract, SKETCH


class FakeContract:

    def __init__(self, name: str) -> None:
        self.name = name

ctrt_global = FakeContract("Global")

class StaticNode:

    def __init__(self, var: "SliVariable", index: int) -> None:
        self.var = var
        self._index = index

    @property
    def index(self):
        return self._index

    def __hash__(self) -> int:
        return hash(self.canonical_name)

    def __eq__(self, __o: "StaticNode") -> bool:
        return __o.canonical_name == self.canonical_name

    @property
    def contract(self) -> "SliContract":
        return self.var.contract

    @property
    def canonical_name(self):
        return f"{self.contract.name}.{self.var.name}"

class StaticEntryNode(StaticNode):

    def __init__(self, index: int) -> None:
        super().__init__(None, index)

    @property
    def contract(self):
        return None

    @property
    def canonical_name(self):
        return "Entry"

class StaticEdge:
    def __init__(self, source: "StaticNode", dest: "StaticNode", func: "SliFunction") -> None:
        self.source = source
        self.dest = dest
        self.func = func

    @property
    def canonical_name(self):
        return self.func.canonical_name

    def __hash__(self) -> int:
        return hash(self.canonical_name)


class StaticGraph:
    def __init__(self) -> None:
        self._freeze = False
        self.nodes: List["StaticNode"] = [StaticEntryNode(index=0)]
        self.edges: List["StaticEdge"] = []

    def freeze(self):
        self._freeze = True

    def unfreeze(self):
        self._freeze = False

    @property
    def entry_node(self):
        return self.nodes[0]

    def add_node(self, var: "SliVariable"):
        if self._freeze:
            raise RuntimeError("Don't add item in a freeze graph.")
        node = StaticNode(var, len(self.nodes))
        self.nodes.append(node)
        return node

    def add_edge(self, source: "StaticNode", dest: "StaticNode", func: "SliFunction"):
        if self._freeze:
            raise RuntimeError("Don't add item in a freeze graph.")
        edge = StaticEdge(source, dest, func)
        self.edges.append(edge)
        return edge

    def __contains__(self, item: "SliVariable"):
        for n in self.nodes:
            if n.var == item:
                return True
        return False

    def __getitem__(self, key: "SliVariable"):
        for n in self.nodes:
            if n.var == key:
                return n
        raise KeyError(key)

    def draw_graphviz(self, name: str):
        import graphviz
        dot = graphviz.Digraph(comment=name)
        for n in self.nodes:
            written_something = False
            for e in self.edges:
                if e.source == n or e.dest == n:
                    written_something = True
                    break
            if not written_something:
                continue
            dot.node(str(n.index), label=n.canonical_name)
        for e in self.edges:
            dot.edge(str(e.source.index), str(e.dest.index), label=e.func.name)
        save_path = path.abspath(path.join(path.dirname(__file__), "../output/static_graph", name))
        dot.render(save_path, engine="circo", format="dot", cleanup=True)

    def track_dependencies(self, dest: "StaticNode") -> Tuple[List["StaticEdge"], List["StaticNode"]]:
        tracked_nodes = set()
        tracked_edges = set()
        current_track_nodes = [dest]
        while current_track_nodes:
            temp = []
            for n in current_track_nodes:
                for e in self.edges:
                    if e.dest != n or e.source in tracked_nodes:
                        continue
                    tracked_edges.add(e)
                    temp.append(e.source)
                tracked_nodes.add(n)
            current_track_nodes = temp
        return tracked_edges, tracked_nodes

    def get_vars_written_dependencies(self, dest: "StaticNode") -> Set[str]:
        tracked_edges, _ = self.track_dependencies(dest)
        return set([e.dest.canonical_name for e in tracked_edges])

    def get_vars_written(self, sketch: "SKETCH") -> Set[str]:
        results = set()
        func_canomical_names = [f.canonical_name for f in sketch]
        for e in self.edges:
            if e.canonical_name in func_canomical_names:
                results.add(e.dest.canonical_name)
        return results

    def get_node_by_name(self, name: str):
        for n in self.nodes:
            if n.canonical_name == name:
                return n
        raise KeyError(name)
