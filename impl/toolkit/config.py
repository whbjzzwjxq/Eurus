from dataclasses import dataclass, field
from os import path
from typing import Dict, List, Tuple

import yaml

from .const import ATTACKER


@dataclass
class DefiRole:
    is_asset: bool = False
    is_erc20: bool = False
    is_lendpool: bool = False
    lend_tokens: List[str] = field(default_factory=list)
    is_swappair: bool = False
    is_uniswap: bool = False
    token_pair: List[str] = field(default_factory=list)

    # Useless
    # is_stablecoin: bool = False
    # is_burnable: bool = False
    # is_defientry: bool = False
    # is_oracle: bool = False
    # oracle: str = ""
    # support_swaps: Dict[str, List[str]] = field(default_factory=dict)
    # hacked_assets: List[str] = field(default_factory=list)
    # hacked_oracles: List[str] = field(default_factory=list)


@dataclass
class ContractInfo:
    name: str
    cls_name: str
    interface_name: str
    address: str


@dataclass
class Config:
    project_name: str = "None"
    blockchain: str = "mainnet"
    blocknumber: int = 0
    attacker_addr: str = "0xdead"
    attack_goal_str: str = "usdt"

    # Used for setup project
    # Private
    contracts: List[List[str]] = field(default_factory=list)

    # Used for public access
    contract_infos: Dict[str, ContractInfo] = field(default_factory=dict)

    # Used for synthesizer
    roles: Dict[str, DefiRole] = field(default_factory=dict)

    # Used for confirmation of ground truth sketch
    groundtruth: List[List[str]] = field(default_factory=list)

    # Manually encoded implementations for actions
    extra_actions: List[str] = field(default_factory=list)

    # Manually encoded deployments for contracts
    extra_deployments: List[str] = field(default_factory=list)

    # Manually encoded statements before the actions
    extra_statements: List[str] = field(default_factory=list)

    # pattern: str = "None"

    def __post_init__(self):
        # Add Contracts
        for c in self.contracts:
            ci = ContractInfo(*c)
            self.contract_infos[ci.name] = ci

        # Add Roles
        keys = list(self.roles.keys())
        for k in keys:
            r = DefiRole(**self.roles[k])
            self.roles[k] = r
        self.roles[ATTACKER] = DefiRole()

        # Parse Attack Goal
        if ";" in self.attack_goal_str:
            self.attack_goal: Tuple[str, str] = tuple(self.attack_goal_str.split(";"))
        else:
            self.attack_goal: Tuple[str, str] = (self.attack_goal_str, "1e18")

    @property
    def assets(self):
        return [name for name, role in self.roles.items() if role.is_asset]

    @property
    def erc20_tokens(self):
        return [name for name, role in self.roles.items() if role.is_erc20]

    @property
    def lendpools(self):
        return [name for name, role in self.roles.items() if role.is_lendpool]

    @property
    def swappairs(self):
        return [name for name, role in self.roles.items() if role.is_swappair]

    @property
    def uniswap_pairs(self):
        return [name for name, role in self.roles.items() if role.is_uniswap]

    @property
    def swappair2tokens(self) -> Dict[str, Tuple[str, str]]:
        return {n: tuple(r.token_pair) for n, r in self.roles.items() if r.is_swappair}
    
    @property
    def uniswap2tokens(self) -> Dict[str, Tuple[str, str]]:
        return {n: tuple(r.token_pair) for n, r in self.roles.items() if r.is_uniswap}

    @property
    def lendpool2tokens(self) -> Dict[str, List[str]]:
        return {n: r.lend_tokens for n, r in self.roles.items() if r.is_lendpool}


def init_config(bmk_dir: str) -> Config:
    config_path = path.join(bmk_dir, "_config.yaml")
    config_json = {}
    if path.exists(config_path):
        with open(config_path, "r") as f:
            config_json = yaml.safe_load(f)
    config = Config(**config_json)
    return config
