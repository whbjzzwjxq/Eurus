from typing import Dict, List, Optional, Set, Tuple

from .rw_analysis import RWGraph
from .utils import Config, CornerCase, init_config
from .utils_slither import *

RW_SET = Tuple[Set[SliVariable], Set[SliVariable]]


class Defi:
    def __init__(self, bmk_dir: str) -> None:
        self.config: Config = init_config(bmk_dir)
        self.ctrt_names = self.config.contract_names
        self.sli = gen_slither(bmk_dir)
        self.ctrts = self._init_ctrts()
        self.test_ctrt = self.sli.get_contract_from_name(f"{self.config.project_name}Test")[0]

        
        self.pub_actions = self._init_pub_actions()
        self.roles = self._init_roles()

        self._rw_set: Dict[str, RW_SET] = self._init_rw_set()
        self._rw_graph = None
        self.ext_calls: Dict[str, List[SliFunction]] = {}

    def _init_ctrts(self) -> List[SliContract]:
        actual_ctrts = []
        for ctrt_name in self.ctrt_names:
            for ctrt in self.sli.contracts:
                if ctrt.name == ctrt_name:
                    actual_ctrts.append(ctrt)
        if len(self.ctrt_names) != len(actual_ctrts):
            raise ValueError("Unmatched contract_names and contracts!")
        return actual_ctrts

    def _init_pub_actions(self) -> List[SliFunction]:
        pub_actions = []
        for ctrt in self.ctrts:
            for f in ctrt.functions:
                if f.is_constructor or f.is_constructor_variables or not f.is_implemented:
                    continue
                if f.pure or f.view or f.visibility in ("internal", "private"):
                    continue
                pub_actions.append(f)
        return pub_actions

    def _init_roles(self) -> List[str]:
        # TODO
        # We have to decide the range of roles.
        roles = [
            "attacker",
            "owner",
        ]
        return roles

    def _init_rw_set(self) -> Dict[str, RW_SET]:
        return {}

    @property
    def rw_graph(self) -> RWGraph:
        if self._rw_graph is None:
            self._rw_graph = self._init_rw_graph()
        return self._rw_graph

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

    def get_contract_by_name(self, name: str):
        for ctrt in self.ctrts:
            if ctrt.name == name:
                return ctrt
        return None

    def get_function_by_name(self, ctrt_name: str, func_name: str):
        ctrt = self.get_contract_by_name(ctrt_name)
        if ctrt is None:
            raise ValueError(f"Unknown contract name: {ctrt_name}")
        return get_function_by_name(ctrt, func_name)

    def get_variable_by_name(self, ctrt_name: str, var_name: str):
        ctrt = self.get_contract_by_name(ctrt_name)
        if ctrt is None:
            raise ValueError(f"Unknown contract name: {ctrt_name}")
        for sv in ctrt.state_variables:
            if sv.name == var_name:
                return sv
        return None

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

    def get_function_by_canonical_name(self, canonical_name: str, method_name: str):
        # Precise finding.
        tgt_ctrt_name = self.config.contract_names_mapping.get(canonical_name, None)
        tgt_ctrt = self.get_contract_by_name(tgt_ctrt_name)
        if tgt_ctrt is None:
            return None
        return get_function_by_name(tgt_ctrt, method_name)

    def get_function_by_interface(self, interface: SliContract, method_name: str):
        possible_funcs = []
        for ctrt in self.ctrts:
            for inter in ctrt.inheritance:
                if interface.name == inter.name:
                    res = self.get_function_by_name(ctrt, method_name)
                    if res is None:
                        continue
                    possible_funcs.append(res)
        return possible_funcs

    def get_function_by_method_name(self, method_name: str):
        # Imprecise finding.
        possible_funcs = []
        for ctrt in self.ctrts:
            res = self.get_function_by_name(ctrt, method_name)
            if res is None:
                continue
            possible_funcs.append(res)
        return possible_funcs

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
            if func.name not in self.ext_calls:
                self.ext_calls[func.canonical_name] = []
            self.ext_calls[func.canonical_name].extend(possible_e_calls)
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

    def is_groundtruth(self, candidate: List[SliFunction]) -> bool:
        if len(candidate) != len(self.config.groundtruth):
            return False
        else:
            for f1, f2 in zip(candidate, self.config.groundtruth):
                f1_ctrt_name = f1.contract.name
                f1_func_name = f1.name
                f2_ctrt_name, f2_func_name = f2.split(".")
                if f1_ctrt_name != f2_ctrt_name or f1_func_name != f2_func_name:
                    return False
            return True
