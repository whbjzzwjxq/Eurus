from os import environ, path
from time import perf_counter
from typing import Any, Dict, List, Tuple

from impl.utils import (SKETCH, FunctionInstance,
                        ether, get_solc_json, gwei,
                        init_config, print_sketch)

from mythril.solidity.soliditycontract import SolidityContract
from mythril.laser.ethereum.svm import LaserEVM
from mythril.laser.ethereum.state.account import Account
from mythril.laser.ethereum.state.world_state import WorldState
from mythril.laser.ethereum.transaction.symbolic import Actors
from mythril.laser.ethereum.transaction import tx_id_manager, ContractCreationTransaction, symbol_factory


class ContractDeployer:

    def __init__(self, project_name: str) -> None:
        self.project_name = project_name
        self.project_dir = path.abspath(
            path.join(self.root_dir, "benchmarks", self.project_name))
        self.config = init_config(self.project_dir)
        self.each_timeout = 10 * 60
        self.total_timeout = 60 * 60
        # For gas-cost of transactions
        self.init_balance = 10 * gwei

        self.init_token_supply = 1000 * ether

        self.root_dir = path.abspath(path.join(__file__, "../../.."))

        self.contract_paths = None
        self._function_instances = None
        self._all_sketches = None
        self.sketch_steps = 10
        self._deployed = False

    def _deploy(self):
        if not self._deployed:
            self.name2ctrt_addr: Dict[str, Account] = {}
            self.world = WorldState()
            self.actor = Actors()
            self.actor["someguy"] = None
            self.actor["dead"] = "0xdead"
            self.owner: Account = self.world.create_account(
                balance=self.init_balance, address=self.actor.creator)
            self.attacker: Account = self.world.create_account(
                balance=self.init_balance, address=self.actor.attacker)
            self.dead: Account = self.world.create_account(
                balance=self.init_balance, address=self.actor["dead"])

            self.vm = LaserEVM(
                dynamic_loader=False,
                max_depth=self.sketch_steps,
                transaction_count=10e8,
                execution_timeout=self.each_timeout,
                create_timeout=self.each_timeout)
            self.vm.add_world_state(self.world)
            
            self._deploy_hook()
        else:
            pass

    def _create_contract(self, owner: Account) -> Account:
        world_state = self.world
        open_states = [world_state]
        del self.v.open_states[:]
        new_account = None
        for open_world_state in open_states:
            next_transaction_id = tx_id_manager.get_next_tx_id()
            # call_data "should" be '[]', but it is easier to model the calldata symbolically
            # and add logic in codecopy/codesize/calldatacopy/calldatasize than to model code "correctly"
            transaction = ContractCreationTransaction(
                world_state=open_world_state,
                identifier=next_transaction_id,
                gas_price=symbol_factory.BitVecVal(0, 256),
                # block gas limit
                gas_limit=8000000,
                origin=owner.address,
                code=Disassembly(contract_initialization_code),
                caller=caller,
                contract_name=contract_name,
                call_data=None,
                call_value=symbol_factory.BitVecVal(0, 256),
            )
            _setup_global_state_for_execution(laser_evm, transaction)
            new_account = new_account or transaction.callee_account

        self.vm.exec(True)

        return new_account

    def _compile(self, ctrt_path: str, ctrt_name: str, *args, balance: int = None, owner: Account = None) -> Account:
        if balance is None:
            balance = self.init_balance
        if owner is None:
            owner = self.owner
        solc_args = [
            f"--base-path {self.root_dir}",
            f"--include-path ./benchmarks/{self.project_name}",
            f"--include-path ./lib",
        ]
        solc_data = get_solc_json(ctrt_path, solc_args=solc_args)
        ctrt = SolidityContract(ctrt_path, name=ctrt_name, solc_data=solc_data)
        deployed_ctrt = execute_contract_creation(
            self.vm, ctrt.creation_code, ctrt_name, self.world, caller=owner.address)
        self.name2ctrt_addr[ctrt_name] = deployed_ctrt
        return deployed_ctrt

    def _solve(self, sketches: List["SKETCH"], analysis_name: str = "Baseline"):
        print(f"Benchmark: {self.project_name}, Analysis: {analysis_name}")
        print(f"All search space: {len(sketches)}")
        debug_idxs = [int(i) for i in environ.get(
            "DEBUGIDX", "").split(",") if i != ""]
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
                self._check_hook()
            except Exception:
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
                print(
                    f"Attacker balance: {self.check_balance(self.attacker, state)}")
                return

            # Because currently, we can't set the timeout for each sketch solving,
            # so we simulate it and assume there isn't a satisfying solving costing more time than each_timeout.
            time_cost_step = min(
                perf_counter() - start_time, self.each_timeout)
            time_cost += time_cost_step
            if time_cost > self.total_timeout:
                print("Timeout")
                print(f"Stop at: {idx + 1}")
                return

            # Don't count the time of recovering to the snapshot.
            self._deploy()
        print("Cannot find a solution!")

    def _print_solution(self, s: str):
        all_replacement = {
            str(self.attacker.address): "Attacker",
            **{str(v.address): k for k, v in self.name2ctrt_addr.items()}
        }
        for k, v in all_replacement.items():
            s = s.replace(k, v)
        print(s)

    @property
    def all_addresses(self):
        return [self.owner, self.attacker, self.dead, *self.name2ctrt_addr.values()]

    @property
    def function_instances(self):
        if self._function_instances is None:
            self._function_instances = self._gen_function_instances()
        return self._function_instances

    @property
    def ground_truth_sketch(self):
        raise NotImplementedError

    @property
    def all_sketches(self) -> List["SKETCH"]:
        if self._all_sketches is None:
            self._all_sketches = []
            last_plans = [[]]
            func_insts = self._function_instances
            for _ in range(self.sketch_steps):
                temp = []
                for p in last_plans:
                    temp.extend([[*p, func_s] for func_s in func_insts])
                self._all_sketches.extend(temp)
                last_plans = temp
        return self._all_sketches

    def _deploy_hook(self):
        raise NotImplementedError

    # Return tuple of symbolic values
    def _exec_hook(self, func_sum: FunctionInstance) -> Tuple[Any]:
        raise NotImplementedError

    def _check_hook(self):
        raise NotImplementedError

    def _gen_function_instances(self) -> List[FunctionInstance]:
        raise NotImplementedError

    def run_ground_truth(self):
        self._deploy()
        self._solve([self._ground_truth_sketch], analysis_name="GroundTruth")

    # def syn_baseline(self):
    #     self._deploy(analysis_name="Baseline")
    #     self._solve(self.all_sketches, analysis_name="Baseline")

    # def syn_usedef(self):
    #     self._deploy(analysis_name="Use-Def")
    #     sketches = self._analyze_usedef()
    #     self._solve(sketches, analysis_name="Use-Def")
