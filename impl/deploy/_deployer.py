import re
from os import environ, path
from time import perf_counter
from typing import Any, Dict, List, Tuple

from impl.init_slither import gen_slither_contracts
from impl.static_analysis import analysis_read_and_write
from impl.utils import (SKETCH, EVMAccount, EVMContract, FunctionSummary,
                        ManticoreEVM, MTState, NoAliveStates, ether, gwei,
                        init_config, print_sketch)

ctrt_name_regex = re.compile(r"\ncontract (\w+)\s+{")


class ContractDeployer:

    owner_init_balance = 1000 * ether
    # For gas-cost of transactions
    init_balance = 10 * gwei
    attacker_init_balance = init_balance

    init_token_supply = 100 * ether

    transfer_limitation = 1 * ether
    each_timeout = 10 * 60
    total_timeout = 60 * 60

    root_dir = path.abspath(path.join(__file__, "../../.."))
    bmk_dir = path.abspath(path.join(root_dir, "benchmarks"))

    def __init__(self, project_name: str) -> None:
        self.project_name = project_name
        self.ctrt_dir = path.join(self.bmk_dir, "examples", self.project_name)
        self.config = init_config(self.ctrt_dir)
        self.main_ctrt = None
        self.__functiom_summaries = None
        self._transfer_func_sum = FunctionSummary("Global", "transfer", "(address,uint256)")
        self._static_graph = None
        self._all_sketches = None
        self.sketch_steps = 4
        self.max_uint256 = 2 ** 256 - 1

    def _compile(self, ctrt_path: str, ctrt_name: str,
        args: Any = (), balance: int = 0, name: str = "", owner: EVMAccount = None):
        if owner is None:
            owner = self.owner
        solc_args = [
            f"--base-path {self.bmk_dir}",
            f"--include-path ./examples/{self.project_name}",
            f"--include-path ./contracts",
        ]
        compile_args = {
            "solc_args": " ".join(solc_args),
            "solc_working_dir": self.bmk_dir,
        }
        with open(ctrt_path, "r") as f:
            source_code = f.read()
        ctrt_addr: EVMContract = self.m.solidity_create_contract(source_code,
            owner=owner,
            args=args,
            contract_name=ctrt_name,
            balance=balance,
            compile_args=compile_args,
        )
        if name:
            self.ctrt_name2addr[name] = ctrt_addr
        else:
            self.ctrt_name2addr[ctrt_name] = ctrt_addr
        return ctrt_addr

    def _solve(self, sketches: List["SKETCH"], analysis_name: str = "Baseline"):
        print(f"Benchmark: {self.project_name}, Analysis: {analysis_name}")
        print(f"All search space: {len(sketches)}")
        debug_idxs = [int(i) for i in environ.get("DEBUGIDX", "").split(",") if i != ""]
        time_cost = 0
        for idx, sk in enumerate(sketches):
            if len(debug_idxs) > 0 and idx not in debug_idxs:
                print(f"Ignore: {idx}")
                continue
            succeed = True
            func_name_args = []
            print(f"Searching: {print_sketch(sk)}")
            start_time = perf_counter()
            try:
                for f in sk:
                    s = self._exec_hook(f)
                    func_name_args.append((f.func_name, s))
                self._check()
            except NoAliveStates:
                succeed = False
            try:
                state = next(self.m.all_sound_states)
            except StopIteration:
                succeed = False
            if succeed:
                print(f"Solved at: {idx + 1}")
                print(f"Solution: ")
                for func_name, args in func_name_args:
                    if args is None:
                        results = ""
                    else:
                        results = state.solve_one_n(*args)
                    self._print_solution(f"{func_name}({results})")
                time_cost += perf_counter() - start_time
                print(f"Solving timecost: {time_cost}")
                print(f"Attacker balance: {self.check_balance(self.attacker, state)}")
                return

            # Because currently, we can't set the timeout for each sketch solving,
            # so we simulate it and assume there isn't a satisfying solving costing more time than each_timeout.
            time_cost_step = min(perf_counter() - start_time, self.each_timeout)
            time_cost += time_cost_step
            if time_cost > self.total_timeout:
                print("Timeout")
                print(f"Stop at: {idx + 1}")
                return

            # Dont' count the time of deploy because it is just due to the lack of snapshot.
            self._deploy(analysis_name)
        print("Cannot find a solution!")

    @property
    def static_graph(self):
        if self._static_graph is None:
            ctrt_slis, _ = gen_slither_contracts(self.ctrt_dir)
            self._static_graph = analysis_read_and_write(ctrt_slis, self.config)
        return self._static_graph

    # def _analyze_usedef(self) -> List["SKETCH"]:
    #     print("Use-Def Analysis")
    #     start_time = perf_counter()
    #     static_graph = self.static_graph
    #     sketches = self.all_sketches
    #     attack_var = self.config.attack_var
    #     vars_deps = static_graph.get_vars_written_dependencies(static_graph.get_node_by_name(attack_var))
    #     sketches_left = []
    #     sketches_no_perf = []
    #     for sk in sketches:
    #         final_vars_written = static_graph.get_vars_written(sk[-1:])
    #         if attack_var not in final_vars_written:
    #             continue
    #         vars_written = static_graph.get_vars_written(sk)
    #         intersection = vars_written.intersection(vars_deps)
    #         if intersection == vars_deps:
    #             sketches_left.append(sk)
    #             continue
    #         rank = len(intersection) / len(vars_deps)
    #         sketches_no_perf.append((sk, rank))
    #     sketches_no_perf = sorted(sketches_no_perf, key=lambda a: a[1])
    #     sketches_no_perf = [a for a, _ in sketches_no_perf]
    #     sketches_left.extend(sketches_no_perf)
    #     end_time = perf_counter()
    #     time_diff = end_time - start_time
    #     print(f"Analysis timecost: {time_diff}")
    #     return sketches_left

    def _analyze_usedef(self) -> List["SKETCH"]:
        print(f"Benchmark: {self.project_name}, Analysis: Use-Def")
        start_time = perf_counter()
        static_graph = self.static_graph
        sketches = self.all_sketches
        attack_var = self.config.attack_var
        sketches_left = []
        for sk in sketches:
            final_vars_written = static_graph.get_vars_written(sk[-1:])
            if attack_var not in final_vars_written:
                continue
            sketches_left.append(sk)
        end_time = perf_counter()
        time_diff = end_time - start_time
        print(f"Analysis timecost: {time_diff}")
        return sketches_left

    def _print_solution(self, s: str):
        all_replacement = {
            str(self.attacker.address): "Attacker",
            **{str(v.address): k for k, v in self.ctrt_name2addr.items()}
        }
        for k, v in all_replacement.items():
            s = s.replace(k, v)
        print(s)

    def _deploy(self, analysis_name: str = "Baseline"):
        self.manticore_work_dir = path.join(self.root_dir, f"output/manticore_workspace/{self.project_name}_{analysis_name}")
        self.m = ManticoreEVM(workspace_url=self.manticore_work_dir)
        self.ctrt_name2addr: Dict[str, EVMContract] = {}
        self.owner: EVMAccount = self.m.create_account(balance=1000 * ether, name="owner")
        self.attacker: EVMAccount = self.m.create_account(balance=self.attacker_init_balance, name="attacker")
        self._deploy_hook()

    @property
    def _all_addresses(self):
        return [self.attacker, *self.ctrt_name2addr.values()]

    @property
    def _functiom_summaries(self):
        if self.__functiom_summaries is None:
            self.__functiom_summaries = self._gen_functiom_summaries()
        return self.__functiom_summaries

    def _transfer(self, receiver: "EVMAccount", value: Any, sender: "EVMAccount" = None):
        if sender is None:
            sender = self.attacker
        for s in self.m.all_states:
            world = s.platform
            if type(value) != int:
                self.m.constrain(value <= self.transfer_limitation)
                self.m.constrain(value >= 1 * gwei)
            world.send_funds(sender, receiver, value)

    def _deploy_hook(self):
        raise NotImplementedError

    def _check(self):
        raise NotImplementedError

    # Return tuple of symbolic values
    def _exec_hook(self, func_sum: FunctionSummary) -> Tuple[Any]:
        raise NotImplementedError

    def _gen_functiom_summaries(self) -> List[FunctionSummary]:
        raise NotImplementedError

    @property
    def _ground_truth_sketch(self):
        raise NotImplementedError

    def run_ground_truth(self):
        self._deploy(analysis_name="GroundTruth")
        self._solve([self._ground_truth_sketch], analysis_name="GroundTruth")

    def run_mock_usedef(self):
        # Although there are perhaps other potential right answers,
        # we still use the ground truth as the first solving one.
        self._deploy(analysis_name="Fake-Use-Def")
        sketches = self._analyze_usedef()
        gt_sk = self._ground_truth_sketch
        for idx, sk in enumerate(sketches):
            equal = True
            if len(sk) != len(gt_sk):
                equal = False
            if not all((a == b for a,b in zip(gt_sk, sk))):
                equal = False
            if equal:
                print(f"Ground truth at: {idx + 1}, {print_sketch(sk)}")
                break
            print(f"Unpruned at: {idx + 1}, {print_sketch(sk)}")

    def syn_baseline(self):
        self._deploy(analysis_name="Baseline")
        self._solve(self.all_sketches, analysis_name="Baseline")

    def syn_usedef(self):
        self._deploy(analysis_name="Use-Def")
        sketches = self._analyze_usedef()
        self._solve(sketches, analysis_name="Use-Def")

    @property
    def all_sketches(self) -> List["SKETCH"]:
        if self._all_sketches is None:
            self._all_sketches = []
            last_plans = [[]]
            func_sums = self._functiom_summaries
            for i in range(self.sketch_steps):
                temp = []
                for p in last_plans:
                    temp.extend([[*p, func_s] for func_s in func_sums])
                self._all_sketches.extend(temp)
                last_plans = temp
        return self._all_sketches

    def check_balance(self, address: "EVMAccount", s: "MTState") -> int:
        return s.solve_one(s.platform.get_balance(address))
