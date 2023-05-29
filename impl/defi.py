from typing import List, Set, Tuple

from .utils import init_config, SolCallType
from .utils_slither import gen_slither_contracts, SliFunction, SliFunction, SliVariable, MemberAccess, get_call_type
from .rw_analysis import RWGraph


class Defi:

    def __init__(self, bmk_dir: str) -> None:
        self.config = init_config(bmk_dir)
        self.ctrt_slis = gen_slither_contracts(bmk_dir)
        self._rw_graph = None
        self.pub_actions = self._init_pub_actions()
        self.roles = self._init_roles()

    def _init_pub_actions(self) -> List[SliFunction]:
        pub_actions = []
        for ctrt_sli in self.ctrt_slis:
            for f in ctrt_sli.functions:
                if f.is_constructor or f.is_constructor_variables:
                    continue
                if f.pure or f.view or f.visibility in ("internal", "private"):
                    continue
                pub_actions.append(f)
        return pub_actions
    
    def _init_roles(self) -> List[str]:
        # TODO, Not confirmed.
        roles = [
            "attacker",
            "owner",
        ]
        return roles

    @property
    def rw_graph(self) -> RWGraph:
        if self._rw_graph is None:
            self._rw_graph = self._analyze_rw()
        return self._rw_graph

    def _analyze_rw(self) -> RWGraph:
        static_graph = RWGraph()
        for f in self.pub_actions:
            all_state_vars_read, all_state_vars_written = self.track_var(f, "attacker")
            if len(all_state_vars_read) == 0:
                all_state_vars_read = set(None)
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
        return static_graph

    def track_var(self, func: SliFunction, sender: str) -> Tuple[Set[SliVariable], Set[SliVariable]]:
        # Analyze normal storage variables usage.
        sv_read = set(
            [r for r in func.state_variables_read if not r.is_immutable])
        sv_written = set(func.state_variables_written)

        # Analyze external calls.
        for e_call_expr in func.external_calls_as_expressions:
            called: MemberAccess = e_call_expr.called
            called_type = get_call_type(called)
            if called_type == SolCallType.INTRINSIC:
                # TODO
                pass
            else:
                # TODO
                pass

        # Analyze internal calls
        for i_call in func.internal_calls:
            if isinstance(i_call, SliFunction):
                i_state_vars_read, i_state_vars_written = self.track_var(i_call)
                sv_read = sv_read.union(i_state_vars_read)
                sv_written = sv_written.union(
                    i_state_vars_written)
        return sv_read, sv_written

    def print_rw_graph(self, output_path: str):
        self.rw_graph.draw_graphviz(output_path)
