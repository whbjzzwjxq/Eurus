import yaml
from dataclasses import dataclass, field
from os import path
from typing import Dict, List, Tuple

from .utils import ATTACKER, ATTACK_CONTRACT_CLS


@dataclass
class DefiRole:
    is_asset: bool = False
    is_erc20: bool = False
    is_lendpool: bool = False
    is_swappair: bool = False
    is_uniswap: bool = False
    token_pair: List[str] = field(default_factory=list)

    # Useless
    is_stablecoin: bool = False
    is_burnable: bool = False
    is_defientry: bool = False
    is_oracle: bool = False
    oracle: str = ""
    support_swaps: Dict[str, List[str]] = field(default_factory=dict)
    hacked_assets: List[str] = field(default_factory=list)
    hacked_oracles: List[str] = field(default_factory=list)


@dataclass
class Config:
    project_name: str = "None"
    ctrt_name2cls: List[Tuple[str, str]] = field(default_factory=list)
    ctrt_name2deploy: List[Tuple[str, str]] = field(default_factory=list)

    # Manually encoded implementations for actions
    extra_actions: List[str] = field(default_factory=list)

    # Manually encoded deployments for contracts, before the transferring of tokens
    extra_deployments_before: List[str] = field(default_factory=list)

    # Manually encoded deployments for contracts
    extra_deployments: List[str] = field(default_factory=list)

    # Manually encoded deployments for contracts
    extra_statements: List[str] = field(default_factory=list)

    attack_goal_str: str = ""
    groundtruth: List[List[str]] = field(default_factory=list)

    # Used for synthesizer
    roles: Dict[str, DefiRole] = field(default_factory=dict)
    pattern: str = "None"

    def __post_init__(self):
        keys = list(self.roles.keys())
        for k in keys:
            r = DefiRole(**self.roles[k])
            self.roles[k] = r
        self.roles[ATTACKER] = DefiRole()
        keys = [k for k, _ in self.ctrt_name2cls]
        if ATTACKER not in keys:
            self.ctrt_name2cls.append((ATTACKER, ATTACK_CONTRACT_CLS))

        keys = [k for k, _ in self.ctrt_name2deploy]
        if ATTACKER not in keys:
            self.ctrt_name2deploy.append((ATTACKER, ""))
        if ";" in self.attack_goal_str:
            self.attack_goal: Tuple[str, str] = tuple(self.attack_goal_str.split(";"))
        else:
            self.attack_goal: Tuple[str, str] = (self.attack_goal_str, "1e18")

    @property
    def tokens(self):
        return [name for name, role in self.roles.items() if role.is_asset]

    @property
    def erc20_tokens(self):
        return [name for name, role in self.roles.items() if role.is_erc20]

    @property
    def uniswap_pairs(self):
        return [name for name, role in self.roles.items() if role.is_uniswap]

    @property
    def swappair2tokens(self) -> Dict[str, Tuple[str, str]]:
        return {n: tuple(r.token_pair) for n, r in self.roles.items() if r.is_swappair}

    @property
    def lend_pools(self):
        return ["owner"] + [name for name, role in self.roles.items() if role.is_lendpool]


def init_config(bmk_dir: str) -> Config:
    config_path = path.join(bmk_dir, "_config.yaml")
    config_json = {}
    if path.exists(config_path):
        with open(config_path, "r") as f:
            config_json = yaml.safe_load(f)
    config = Config(**config_json)
    return config
