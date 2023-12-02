from typing import List, Set, Dict

from .financial_constraints import extract_rw_vars

from .synthesizer import AFLAction, Sketch
from .utils import *
from .utils_slither import *

VOID = "VOID"
TRACE = List["TFGEdge"]


class TFGNode:
    def __init__(self, account: str, token: str) -> None:
        self.account = account
        self.token = token
        self.name = f"{account}-{token}"
        self.income_edges: List["TFGEdge"] = []
        self.outcome_edges: List["TFGEdge"] = []

    def add_edge(self, edge: "TFGEdge"):
        if edge.start == self:
            self.outcome_edges.append(edge)
        if edge.end == self:
            self.income_edges.append(edge)

    def __eq__(self, __value: "TFGNode") -> bool:
        return self.name == __value.name

    def __hash__(self) -> int:
        return hash(self.name)


class TFGEdge:
    def __init__(self, account: str, start: "TFGNode", end: "TFGNode", label: AFLAction) -> None:
        self.account = account
        self.start = start
        self.end = end
        self.label = label
        self.name = label.func_sig
        self.start.add_edge(self)
        self.end.add_edge(self)

    def __eq__(self, __value: "TFGEdge") -> bool:
        return self.name == __value.name

    def __hash__(self) -> int:
        return hash(self.name)


class TFG:
    def __init__(self, account: str) -> None:
        self.account = account
        self.nodes: Dict[str, "TFGNode"] = {}
        self.edges: Dict[str, "TFGEdge"] = {}
        self._freeze = False

    def add_node(self, token: str) -> "TFGNode":
        if self._freeze:
            raise RuntimeError("Don't add item to a forzen graph.")
        node = TFGNode(self.account, token)
        self.nodes[node.name] = node
        return node

    def add_edge(self, start: str, end: str, f: AFLAction) -> "TFGEdge":
        if self._freeze:
            raise RuntimeError("Don't add item to a forzen graph.")
        start_n = self.get_node(start)
        end_n = self.get_node(end)
        edge = TFGEdge(self.account, start_n, end_n, f)
        self.edges[edge.name] = edge
        return edge

    def get_node(self, token: str):
        return self.nodes[f"{self.account}-{token}"]


class TFGManager:
    MAX_STEP = 7

    def __init__(
        self, tokens: List[str], accounts: List[str], func_summarys: List[AFLAction], attack_goal: str
    ) -> None:
        self.sub_graphs: Dict[str, TFG] = {}
        self.tokens = tokens
        self.accounts = accounts
        self.func_summarys = func_summarys
        self.func_sigs = {f.func_sig for f in self.func_summarys}
        self.attack_goal = attack_goal
        for a in accounts:
            sub_graph = TFG(a)
            for t in tokens:
                sub_graph.add_node(t)
            self.sub_graphs[a] = sub_graph

        self.main_graph = self.sub_graphs["attacker"]
        self.start_node: TFGNode = sub_graph.get_node(VOID)

        for f in func_summarys:
            if f.action_name in ("swap", "deposit", "withdraw"):
                a0 = f.account
                sub_graph0 = self.sub_graphs[a0]
                e0 = sub_graph0.add_edge(f.token0, f.token1, f)

                a1 = f.swap_pair
                sub_graph1 = self.sub_graphs[a1]
                e1 = sub_graph1.add_edge(f.token1, f.token0, f)
            else:
                for flow in f.token_flows:
                    a0 = flow.sender
                    sub_graph0 = self.sub_graphs[a0]
                    e0 = sub_graph0.add_edge(flow.token, VOID, f)

                    a1 = flow.receiver
                    sub_graph1 = self.sub_graphs[a1]
                    e1 = sub_graph1.add_edge(VOID, flow.token, f)

    def prune(self, trace: TRACE) -> bool:
        if trace[-1].end.token != VOID:
            return True
        if trace[0].end.token != trace[-1].start.token:
            return True
        if trace[0].label.lender != trace[-1].label.lender:
            return True
        for idx, e in enumerate(trace):
            action = e.label
            if idx >= 1:
                last_e = trace[idx - 1]
                last_action = last_e.label
                if action.action_name == "borrow" and last_action.action_name == "payback":
                    return True
                if action.action_name == "payback" and last_action.action_name == "borrow":
                    return True
            # Avoid do swap inside flashloan
            if action.action_name == "swap":
                for jdx, e1 in enumerate(trace[:idx]):
                    e1_action = e1.label
                    if e1_action.action_name == "borrow":
                        if e1_action.lender == action.swap_pair:
                            return True

    def mutation(self, sketch: Sketch):
        # Heuristics
        new_sketches = []
        actions = sketch.pure_actions
        attacker_got_tokens = set()
        for i, cur_a in enumerate(actions):
            if i == 0:
                continue
            # Price manipulation
            if cur_a.action_name == "swap":
                if cur_a.account == "attacker":
                    attacker_got_tokens.add(cur_a.token1)
                read_vars, _ = extract_rw_vars(cur_a.constraints)
                # The balance of acction doesn't influence the price.
                n_read_vars = set(v for v in read_vars if not cur_a.account in v)
                for f in self.func_summarys:
                    if f.action_name == "swap":
                        if f.account == cur_a.account:
                            continue
                    if f.action_name == "borrow" or f.action_name == "payback":
                        continue
                    # Perhaps manipulate the price
                    _, write_vars = extract_rw_vars(f.constraints)
                    if write_vars.intersection(n_read_vars) != set():
                        new_sketch = [*actions]
                        new_sketch.insert(i, f)
                        new_sketches.append(Sketch(new_sketch).symbolic_copy())

            # Price manipulation
            if cur_a.action_name == "withdraw":
                last_a = actions[i - 1]
                if cur_a.account == "attacker":
                    attacker_got_tokens.add(cur_a.token1)
                if last_a.action_name == "deposit" and last_a.defi == cur_a.defi:
                    read_vars, _ = extract_rw_vars(cur_a.constraints)
                    # The balance of acction doesn't influence the price.
                    n_read_vars = set(v for v in read_vars if not cur_a.account in v)
                    for f in self.func_summarys:
                        if f == cur_a or f == last_a or f.action_name == "payback":
                            continue
                        # Perhaps manipulate the price
                        if f.action_name == "borrow":
                            _, write_vars = extract_rw_vars(f.constraints)
                            if write_vars.intersection(n_read_vars) != set():
                                new_sketch = [*actions]
                                new_sketch.insert(i, f)
                                matched_payback = AFLAction("payback", f.args_in_name, f.args)
                                new_sketch.insert(i + 2, matched_payback)
                                new_sketches.append(Sketch(new_sketch).symbolic_copy())
                        else:
                            _, write_vars = extract_rw_vars(f.constraints)
                            if write_vars.intersection(n_read_vars) != set():
                                new_sketch = [*actions]
                                new_sketch.insert(i, f)
                                new_sketches.append(Sketch(new_sketch).symbolic_copy())

            if cur_a.action_name == "deposit":
                if cur_a.account == "attacker":
                    attacker_got_tokens.add(cur_a.token1)

            # Token distribution
            if cur_a.action_name == "payback":
                payback_token = cur_a.token0
                attacker_got_tokens.remove(payback_token)
                for t in attacker_got_tokens:
                    for f in self.func_summarys:
                        if not f.action_name == "swap":
                            continue
                        if not (f.token0 == t and f.token1 == payback_token):
                            continue
                        if f.func_sig in sketch.func_sigs:
                            continue
                        new_sketch = [*actions]
                        new_sketch.insert(i, f)
                        new_sketches.append(Sketch(new_sketch).symbolic_copy())
        return new_sketches

    def after_prune(self, sketch: Sketch) -> bool:
        has_attack_goal_token = False
        for idx, action in enumerate(sketch.pure_actions):
            if e.end.token == self.attack_goal and action.action_name != "borrow":
                has_attack_goal_token = True
        if not has_attack_goal_token:
            return True

    def gen_candidates(self):
        i = 0
        candidates: List[Sketch] = []
        while i <= self.MAX_STEP:
            potential_candidates: List[Sketch] = []
            if i == 0:
                old_traces = []
                new_traces: List[TRACE] = [[e] for e in self.start_node.outcome_edges]
            else:
                old_traces = new_traces
                new_traces: List[TRACE] = []
                for t in old_traces:
                    end_node = t[-1].end
                    for e in end_node.outcome_edges:
                        new_traces.append([*t, e])
            for t in new_traces:
                if self.prune(t):
                    continue
                actions = [a.label for a in t]
                sketch = Sketch(actions).symbolic_copy()
                potential_candidates.append(sketch)
            k = 0
            while k <= len(potential_candidates) - 1:
                cur_sketch = potential_candidates[k]
                if len(cur_sketch) == self.MAX_STEP:
                    # No longer need to mutate.
                    break
                new_candidates = self.mutation(cur_sketch)
                for nc in new_candidates:
                    potential_candidates.insert(k + 1, nc)
                    k += 1
                k += 1
            for cand in potential_candidates:
                if self.after_prune(cand.pure_actions):
                    continue
                candidates.append(cand)

            i += 1
        return candidates
