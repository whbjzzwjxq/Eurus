# Eurus
Attack Synthesis for DeFi Apps

## Initial Benchmark Collection
We use [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main) as the benchmark records. We search three keywords actually targeting to price oracle manipulation attack: "Price Oracle Manipulation", "Price Manipulation", "Pair Manipulate", "Reflection token" and "Swap Metapool Attack".

[Initial Benchmark](https://docs.google.com/spreadsheets/d/1Lv_MobKl0fHEsKa3oUU9-YnTsg_f9afePEtP_zSXU1c/edit?usp=sharing)
[Initial Study](https://docs.google.com/document/d/1GLrh-LDtsVapd0acO_sXS0HsohMXxJ6p2bjj6VbaNSw/edit?usp=sharing)

## Setup
```bash
pip install -r ./requirements.txt
solc-select install 0.8.15
solc-select use 0.8.15
git submodule update --init --recursive
npm install --save-dev
```

## Evaluation
### Forge test (attack ground truth)`
```bash
forge test --match-path ./benchmarks/MUMUG/MUMUG.t.sol -vvvv
```

### Halmos (Example)
```bash
halmos -vvvvv --function check_cand --contract MUMUGTest --forge-build-out .cache --print-potential-counterexample --solver-timeout-branching 10000
```

## Tips
Halomos will use the same cache directory as foundry.toml.

## Overall Algorithm
