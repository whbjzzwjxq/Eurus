# fp = "benchmarks/MUMUG/result/smt_gt_smtdiv_none/26.smt2"
fp = "benchmarks/Discover/result/smt_gt_smtdiv_none/13.smt2"

def replace(declare: str, key: str, lines: list[str]):
    lines_before, lines_after = [], []
    for idx, l in enumerate(lines):
        if declare == l:
            lines_before = lines[:idx]
            lines_after = lines[idx+1:]
            break
    num = 0
    lines_after_new = []
    for l in lines_after:
        if key in l:
            num += 1
            new_key = key + str(num)
            l = l.replace(key, new_key)
            lines_before.append(declare.replace(key, new_key))
        lines_after_new.append(l)
    return lines_before + lines_after_new

with open(fp, "r") as f:
    lines = f.readlines()

lines = replace("(declare-fun sha3_512 ((_ BitVec 512)) (_ BitVec 256))\n", "sha3_512", lines)
lines = replace("(declare-fun evm_bvudiv ((_ BitVec 256) (_ BitVec 256)) (_ BitVec 256))\n", "evm_bvudiv", lines)

with open(fp.replace(".smt2", "mod.smt2"), "w") as f:
    f.writelines(lines)
