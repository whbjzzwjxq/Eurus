import yaml
from dataclasses import dataclass, field
from os import path
from typing import Dict, List, Tuple


@dataclass
class DefiRoles:
    is_asset: bool = False
    is_erc20: bool = False
    is_stablecoin: bool = False
    is_burnable: bool = False

    is_defientry: bool = False
    is_swappair: bool = False
    is_oracle: bool = False
    is_lendpool: bool = False

    oracle: str = ""

    support_swaps: Dict[str, List[str]] = field(default_factory=dict)
    uniswap_order: List[str] = field(default_factory=list)

    hacked_assets: List[str] = field(default_factory=list)
    hacked_oracles: List[str] = field(default_factory=list)

    @property
    def is_uniswap(self) -> bool:
        return len(self.uniswap_order) != 0


AttackCtrtName = "attackContract"


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
    roles: Dict[str, DefiRoles] = field(default_factory=dict)
    pattern: str = "None"

    def __post_init__(self):
        keys = list(self.roles.keys())
        for k in keys:
            r = DefiRoles(**self.roles[k])
            self.roles[k] = r
        self.roles[AttackCtrtName] = DefiRoles()
        keys = [k for k, _ in self.ctrt_name2cls]
        if AttackCtrtName not in keys:
            self.ctrt_name2cls.append((AttackCtrtName, "AttackContract"))

        keys = [k for k, _ in self.ctrt_name2deploy]
        if AttackCtrtName not in keys:
            self.ctrt_name2deploy.append((AttackCtrtName, ""))
        if ";" in self.attack_goal_str:
            self.attack_goal = tuple(self.attack_goal_str.split(";"))
        else:
            self.attack_goal = (self.attack_goal_str, "1e18")


def init_config(bmk_dir: str) -> Config:
    config_path = path.join(bmk_dir, "_config.yaml")
    config_json = {}
    if path.exists(config_path):
        with open(config_path, "r") as f:
            config_json = yaml.safe_load(f)
    config = Config(**config_json)
    return config
