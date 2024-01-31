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

## Setup by Docker
First, build the image. 
```bash
docker build -t eurus .
```
Then, execute a container based on this image.
```bash
docker run -it eurus
```

## Setup by commandline (If you are using a Macbook)
Install python 3.11.
```bash
brew install python@3.11
```

Install depdencies.
```bash
pip3 install -q --upgrade pip && pip3 install -q -r ./requirements.txt && \
solc-select install 0.8.15 && solc-select use 0.8.15 && npm install --quiet --save-dev
```

Install foundry
```bash
curl -L https://foundry.paradigm.xyz | bash
```
Then:
```bash
source /Users/hongbo/.zshenv
```
Then:
```bash
foundryup
```

## Evaluation

### Halmos test
This test is for testing how Halmos works on the groundtruth sketch of a benchmark.
The output is `output.json`.
(Add `caffeinate` on Macbook to avoid sleep.)
```bash
halmos -vvvvv --function check_gt --contract DiscoverTest --forge-build-out .cache \
--print-potential-counterexample --solver-timeout-branching 100000 \
--solver-timeout-assertion 100000 --json-output output.json
```

### Halmos eval
This command will evaluate all sketches of a candidate.
```bash
python3 ./main.py -ha -i ./benchmarks/Discover
```
(It works with cached results, if you don't want to cache, run `rm ./benchmarks/Discover/result/*.json`)

### Forge test
This test is for testing whether the ground truth works or not.
```bash
forge test -vvv --match-path ./benchmarks/Discover/Discover.t.sol
```

### Use anvil
```bash
anvil --no-mining --timestamp 0 --base-fee 0 --gas-price 0
```

## Tips
Halmos will use the same cache directory as foundry.toml.

Supported cheating codes: [Check this file](https://github.com/a16z/halmos/blob/6be83f77b9b4775c4c27fd262fc4b7faaf8a1a22/src/halmos/sevm.py#L1828)

## Overall Algorithm

## For developer

### Prepare code
```bash
python3 ./main.py -p -i ./benchmarks/Discover
python3 ./main.py -p -i all
```
