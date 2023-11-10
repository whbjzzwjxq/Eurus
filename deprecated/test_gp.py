# import argparse
# import json
# import os
# import shutil
# import time
# from os import path
# from subprocess import CalledProcessError, TimeoutExpired, run
# from typing import List, Tuple

# import gurobipy as gp

# from impl.halmos import exec_halmos
# from impl.benchmark_builder import BenchmarkBuilder, get_sketch_by_func_name
# from impl.synthesizer import Synthesizer
# from impl.utils import (
#     gen_result_paths,
#     get_bmk_dirs,
#     load_smt_model,
#     prepare_subfolder,
#     resolve_project_name,
# )
# from impl.verifier import verify_model

# token0 = "usdt"
# token1 = "disc"
# # reserve0pair = 19811
# # reserve1pair = 12147
# scale = 1e18
# reserve0pair = 19811554285664651588959 / scale
# reserve1pair = 12147765912566297044558 / scale
# profit = 1e18 / scale

# balanceOfusdtethpledge = 17359200000000000000000 / scale
# balanceOfdiscethpledge = 603644007472699128296549 / scale


# LB = 0
# UB = 2**64 - 1
# VTYPE = gp.GRB.CONTINUOUS


# def _main(use_mock_uniswap: bool, use_mock_ethpswap: bool, use_transfer_limit: bool):
#     solver = gp.Model()
#     solver.params.NumericFocus = 3
#     solver.params.TimeLimit = 100

#     # step 1
#     amt0 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amt0")
#     # amt0 = 24000

#     # step 2
#     amt1 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amt1")
#     # amt1 = 24000
#     # discIn
#     amtIn1 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amtIn1")
#     # usdtOut
#     amtOut1 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amtOut1")
#     reserve0pair1 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="reserve0pair1")
#     reserve1pair1 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="reserve1pair1")

#     # step 3
#     amt2 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amt2")
#     # amt2 = 5000
#     # usdtIn
#     amtIn2 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amtIn2")
#     # discOut
#     amtOut2 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amtOut2")

#     # step 4
#     amt3 = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="amt3")
#     # amt3 = 24000 * 1.003

#     remainDisc = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="remainDisc")
#     remainUSDT = solver.addVar(lb=LB, ub=UB, vtype=VTYPE, name="remainUSDT")

#     def native_borrow():
#         # borrow_disc(amt0);
#         solver.addConstr(amt1 <= amt0, "c0")

#     def native_uniswap():
#         # swap_pair_disc_usdt(amt1);
#         solver.params.NonConvex = 2
#         solver.addConstr(amtIn1 == amt1, "c1")
#         solver.addConstr(
#             reserve0pair * reserve1pair == reserve0pair1 * reserve1pair1, "c2"
#         )
#         solver.addConstr(reserve0pair1 == reserve0pair - amtOut1 * 1.003, "c3")
#         solver.addConstr(reserve1pair1 == reserve1pair + amtIn1, "c4")

#     def mock_uniswap():
#         # swap_pair_disc_usdt(amt1);
#         solver.addConstr(amtIn1 == amt1)
#         solver.addConstr(amtOut1 * 1.003 * reserve1pair == reserve0pair * amtIn1)
#         solver.addConstr(reserve0pair1 == reserve0pair - amtOut1)
#         solver.addConstr(reserve1pair1 == reserve1pair + amtIn1)

#     def transfer_limit_uniswap():
#         if use_transfer_limit:
#             solver.addConstr(amtOut1 <= reserve0pair)

#     def native_ethpswap():
#         solver.params.NonConvex = 2
#         # swap_ethpledge_usdt_disc(amt2);
#         solver.addConstr(amtIn2 == amt2, "c5")
#         solver.addConstr(amtOut2 * reserve0pair1 == reserve1pair1 * amtIn2, "c6")

#     def mock_ethpswap():
#         # swap_ethpledge_usdt_disc(amt2);
#         solver.addConstr(amtIn2 == amt2)
#         solver.addConstr(amtOut2 * reserve0pair == reserve1pair * amtIn2)

#     def transfer_limit_ethpswap():
#         if use_transfer_limit:
#             solver.addConstr(amtOut2 <= balanceOfdiscethpledge)

#     def native_payback():
#         # payback_disc(amt3);
#         solver.addConstr(amt3 == amt0 * 1.003, "c7")
#         # solver.addConstr(amt3 == amt0)
#         solver.addConstr(remainDisc == amt0 - amtIn1 + amtOut2 - amt3, "c8")
#         solver.addConstr(remainUSDT == amtOut1 - amtIn2, "c9")
#         solver.addConstr(remainDisc >= 0, "c10")
#         solver.addConstr(remainUSDT >= profit, "c11")

#     native_borrow()
#     if use_mock_uniswap:
#         mock_uniswap()
#     else:
#         native_uniswap()
#     if use_transfer_limit:
#         transfer_limit_uniswap()

#     if use_mock_ethpswap:
#         mock_ethpswap()
#     else:
#         native_ethpswap()

#     if use_transfer_limit:
#         transfer_limit_ethpswap()

#     native_payback()
#     start_time = time.perf_counter()
#     solver.optimize()
#     print(f"Timecost: {time.perf_counter() - start_time}")
#     print(
#         f"Setup: use_mock_uniswap={use_mock_uniswap}, use_mock_ethpswap={use_mock_ethpswap}, use_transfer_limit={use_transfer_limit}"
#     )
#     if solver.status == gp.GRB.OPTIMAL:
#         print(f"Solution found:")
#         params = [amt0, amt1, amt2, amt3]
#         param_ints = []
#         for idx, a in enumerate(params):
#             print(f"amt{idx}: {a.x}")
#             param_ints.append(int(a.x * scale))
#         bmk_dir = "./benchmarks/Discover"
#         builder = BenchmarkBuilder(bmk_dir)
#         synthesizer = SynthesizerByPattern(builder.config)
#         func_name = "check_gt"
#         sketch = get_sketch_by_func_name(builder, synthesizer, func_name)
#         model = [param_ints]
#         if verify_model(bmk_dir, [(func_name, sketch, model)]):
#             print("Result is feasible in realworld!")
#         else:
#             print("Result is NOT feasible in realworld!")

#     else:
#         solver.computeIIS()
#         for c in solver.getConstrs():
#             if c.IISConstr:
#                 print(str(c))


# if __name__ == "__main__":
#     # _main(False, False, False)
#     _main(False, False, True)
#     # _main(True, False, False)
#     # _main(True, False, True)
#     # _main(True, True, False)
#     # _main(True, True, True)
