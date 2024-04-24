# Eurus
Attack Synthesis for DeFi Apps

## Initial Benchmark Collection
We use [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs/tree/main) as the benchmark records. 
We search a few keywords actually targeting to price oracle manipulation attack:
    - "Price Oracle Manipulation"
    - "Price Manipulation"
    - "Pair Manipulate"

[Initial Benchmark](https://docs.google.com/spreadsheets/d/1Lv_MobKl0fHEsKa3oUU9-YnTsg_f9afePEtP_zSXU1c/edit?usp=sharing)
[Initial Study](https://docs.google.com/document/d/1GLrh-LDtsVapd0acO_sXS0HsohMXxJ6p2bjj6VbaNSw/edit?usp=sharing)

## Setup by commandline (If you are using a Macbook)
Install python 3.11.
```bash
brew install python@3.11
```

Install depdencies.
```bash
pip3 install -q --upgrade pip && pip3 install -q -r ./requirements.txt && \
solc-select install 0.8.21 && solc-select use 0.8.21 && npm install --quiet --save-dev
```

Add foundry 0.2.0 to $PATH
```bash
export PATH=$(pwd)/.foundry:$PATH
```

## Evaluation

### Foray eval
This command will evaluate all sketches of a benchmark.
```bash
python3 ./main.py -e -i ./benchmarks/Discover
```

### Halmos eval
This command will evaluate all sketches of a benchmark.
```bash
python3 ./main.py -ha -i ./benchmarks/Discover
```
(It works with cached results, if you don't want to cache, run `rm ./benchmarks/Discover/result/*.json`)

### Forge eval
This test is for testing whether the ground truth works or not.
```bash
forge test -vvv --match-path ./benchmarks/Discover/Discover.t.sol
```

### Use anvil
```bash
anvil --no-mining --timestamp 0 --base-fee 0 --gas-price 0
```

## Tips

### Halmos cache
Halmos will use the same cache directory as foundry.toml.

Supported cheating codes: [Check this file](https://github.com/a16z/halmos/blob/6be83f77b9b4775c4c27fd262fc4b7faaf8a1a22/src/halmos/sevm.py#L1828)

### Prepare code (We have already prepared for you, not need to re-run it)
```bash
python3 ./main.py -p -i ./benchmarks/Discover
python3 ./main.py -p -i all
```
