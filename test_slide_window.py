import time

from z3 import (ULE, BitVec, BitVecVal, Concat, Extract, Solver, UDiv, ZeroExt,
                sat, If)


def exec(slide_window_udiv_on: bool):
    p_amt1_uint256 = BitVec('p_amt1_uint256', 256)
    # p_amt1_uint256 = BitVecVal(24000e18, 256)

    s = Solver()


    def range_limit(a, min, max):
        s.add(a >= min)
        s.add(a < max)

    def slide_window_udiv(a, b):
        hi = 160
        lo = 80
        width = 16
        ap = Extract(hi - 1, hi - width, a)
        bp = Extract(lo - 1, lo - width, b)
        range_limit(a, 2**(hi - width), 2**(hi - 1))
        range_limit(b, 2**(lo - width), 2**(lo - 1))
        res = UDiv(ap, bp) | If(ULE(ap, bp), BitVecVal(1, width), BitVecVal(0, width))
        r = ZeroExt(256 - width, res) << (hi - lo)
        return r

    x44153 = Extract(7, 0, p_amt1_uint256)
    x60416 = BitVecVal(78, 8) + x44153
    x58552 = BitVecVal(12147765912566297044558, 256) + p_amt1_uint256
    x60451 = Extract(255, 8, x58552)
    x60452 = Concat(x60451, x60416)

    x60640 = BitVecVal(19752119622807657634192123, 256) * x60452
    x60644 = BitVecVal(115792089237316195423570985008447963727815109937533206347770939126370266023302, 256) + x60640
    x60543 = BitVecVal(997, 256) * x60452
    x60444 = BitVecVal(36443297737698891133674, 256) + x60543
    if slide_window_udiv_on:
        x60661 = slide_window_udiv(x60644, x60444)
    else:
        x60661 = UDiv(x60644, x60444)

    # Check if the final condition holds
    s.add(ULE(x60661, x60644))

    x60644_s = BitVec('x60644_s', 256)
    x60444_s = BitVec('x60444_s', 256)
    x60661_s = BitVec('x60661_s', 256)
    s.add(x60644_s == x60644)
    s.add(x60444_s == x60444)
    s.add(x60661_s == x60661)

    # Check satisfiability
    time0 = time.perf_counter()
    res = s.check()
    time1 = time.perf_counter()

    if res == sat:
        model = s.model()
        print("model is", model)
        print(f"timecost: {time1-time0} seconds with slide_window_udiv={slide_window_udiv_on}")
    else:
        print("The condition is unsatisfiable.")

if __name__ == "__main__":
    exec(True)
    exec(False)
