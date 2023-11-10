from typing import List, Set, Dict

import networkx as nx

from .synthesizer import AFLAction
from .utils import *
from .utils_slither import *


class TFGNode:
    """
    Represents a token or VOID.
    """

    VOID = "VOID"

    def __init__(self, token: str, account: str) -> None:
        self.token = token
        self.account = account

    @property
    def name(self):
        return f"{self.account}.{self.token}"

    @property
    def is_void(self):
        return self.token == self.VOID

    def __hash__(self) -> int:
        return hash(self.name)

    def __eq__(self, __o: "TFGNode") -> bool:
        return __o.name == self.name


class TFGEdge:
    def __init__(self, func: AFLAction) -> None:
        self.func = func

    @property
    def name(self):
        return self.func.func_sig

    def __hash__(self) -> int:
        return hash(self.name)


class TFG:
    def __init__(self, tokens: List[str], accounts: List[str], func_summarys: List[AFLAction]) -> None:
        self.sub_graphs: Dict[str, nx.Graph] = {}
        self.tokens = tokens
        self.accounts = accounts
        self.func_summarys = func_summarys
        for a in accounts:
            sub_graph = nx.Graph(name=a)
            for t in tokens:
                sub_graph.add_node(TFGNode(t, a))
            self.sub_graphs[a] = sub_graph

        for f in func_summarys:
            if f.action_name in ("swap", "deposit", "withdraw"):
                e0 = TFGEdge(f)
                u0 = f.token0
                v0 = f.token1
                sub_graph0 = self.sub_graphs[f.account]

                sub_graph0.add_edge(u0, v0, e0)

                e1 = TFGEdge(f)
                u1 = f.token1
                v1 = f.token0
                sub_graph1 = self.sub_graphs[f.swap_pair]
                sub_graph1.add_edge(u1, v1, e1)
            else:
                for flow in f.token_flows:
                    e0 = TFGEdge(f)
                    u0 = flow.token
                    v0 = TFGNode.VOID
                    sub_graph0 = self.sub_graphs[flow.sender]
                    sub_graph0.add_edge(u0, v0, e0)

                    e1 = TFGEdge(f)
                    u1 = TFGNode.VOID
                    v1 = flow.token
                    sub_graph1 = self.sub_graphs[flow.receiver]
                    sub_graph1.add_edge(u1, v1, e1)

    def gen_candidates(self):
        pass
