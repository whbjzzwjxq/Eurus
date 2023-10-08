import time

from z3 import *

from impl.solidity_builder import BenchmarkBuilder, get_sketch_by_func_name
from impl.synthesizer import Synthesizer
from impl.verifier import verify_model

token0 = "usdt"
token1 = "disc"
# reserve0pair = 19811
# reserve1pair = 12147
scale = 1e18
reserve0pair = 19811554285664651588959 / scale
reserve1pair = 12147765912566297044558 / scale
profit = 1e18 / scale

balanceOfusdtethpledge = 17359200000000000000000 / scale
balanceOfdiscethpledge = 603644007472699128296549 / scale

LB = 0
UB = 2 ** 64 - 1

def _main():
    solver = Solver()

    # step 1
    amt0 = Real("amt0")
    solver.add(amt0 >= LB, amt0 <= UB)
    # amt0 = 24000

    # step 2
    amt1 = Real("amt1")
    solver.add(amt1 >= LB, amt1 <= UB)
    # amt1 = 24000
    # discIn
    amtIn1 = Real("amtIn1")
    solver.add(amtIn1 >= LB, amtIn1 <= UB)
    # usdtOut
    amtOut1 = Real("amtOut1")
    solver.add(amtOut1 >= LB, amtOut1 <= UB)

    reserve0pair1 = Real("reserve0pair1")
    solver.add(reserve0pair1 >= LB, reserve0pair1 <= UB)

    reserve1pair1 = Real("reserve1pair1")
    solver.add(reserve1pair1 >= LB, reserve1pair1 <= UB)

    # step 3
    amt2 = Real("amt2")
    solver.add(amt2 >= LB, amt2 <= UB)
    # amt2 = 5000
    # usdtIn
    amtIn2 = Real("amtIn2")
    solver.add(amtIn2 >= LB, amtIn2 <= UB)
    # discOut
    amtOut2 = Real("amtOut2")
    solver.add(amtOut2 >= LB, amtOut2 <= UB)

    # step 4
    amt3 = Real("amt3")
    solver.add(amt3 >= LB, amt3 <= UB)
    # amt3 = 24000 * 1.003

    remainDisc = Real("remainDisc")
    solver.add(remainDisc >= LB, remainDisc <= UB)

    remainUSDT = Real("remainUSDT")
    solver.add(remainUSDT >= LB, remainUSDT <= UB)

    def native_borrow():
        # borrow_disc(amt0);
        solver.add(amt1 <= amt0)

    def native_uniswap():
        # swap_pair_disc_usdt(amt1);
        solver.add(amtIn1 == amt1)
        solver.add(
            reserve0pair * reserve1pair == reserve0pair1 * reserve1pair1
        )
        solver.add(reserve0pair1 == reserve0pair - amtOut1 * 1.003)
        solver.add(reserve1pair1 == reserve1pair + amtIn1)

    def transfer_limit_uniswap():
        solver.add(amtOut1 <= reserve0pair)

    def native_ethpswap():
        # swap_ethpledge_usdt_disc(amt2);
        solver.add(amtIn2 == amt2)
        solver.add(amtOut2 * reserve0pair1 == reserve1pair1 * amtIn2)

    def transfer_limit_ethpswap():
        solver.add(amtOut2 <= balanceOfdiscethpledge)

    def native_payback():
        # payback_disc(amt3);
        solver.add(amt3 == amt0 * 1.003)
        # solver.add(amt3 == amt0)
        solver.add(remainDisc == amt0 - amtIn1 + amtOut2 - amt3)
        solver.add(remainUSDT == amtOut1 - amtIn2)
        solver.add(remainDisc >= 0)
        solver.add(remainUSDT >= profit)

    native_borrow()
    native_uniswap()
    transfer_limit_uniswap()
    native_ethpswap()
    transfer_limit_ethpswap()
    native_payback()
    start_time = time.perf_counter()
    res = solver.check()
    print(f"Timecost: {time.perf_counter() - start_time}")

    if res == sat:
        model = solver.model()
        print(f"Solution found:")
        params = [amt0, amt1, amt2, amt3]
        param_ints = []
        for idx, a in enumerate(params):
            v = int(float(model[a].as_decimal(18).removesuffix('?')) * scale)
            print(f"amt{idx}: {v}")
            param_ints.append(v)
        bmk_dir = "./benchmarks/Discover"
        builder = BenchmarkBuilder(bmk_dir)
        synthesizer = Synthesizer(builder.config)
        func_name = "check_gt"
        sketch = get_sketch_by_func_name(builder, synthesizer, func_name)
        model = [param_ints]
        if verify_model(bmk_dir, [(func_name, sketch, model)]):
            print("Result is feasible in realworld!")
        else:
            print("Result is NOT feasible in realworld!")

    else:
        print(f"Solution is NOT found.")


if __name__ == "__main__":
    _main()
