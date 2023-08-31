import yaml
from dataclasses import dataclass, field
from os import path
from typing import Dict, List, Tuple


@dataclass
class DefiRoles:
    is_asset: bool = False
    is_stablecoin: bool = False
    is_defientry: bool = False
    is_swappair: bool = False
    support_swaps: Dict[str, List[str]] = field(default_factory=dict)
    hacked_assets: List[str] = field(default_factory=list)


@dataclass
class Config:
    project_name: str = "None"
    ctrt_name_mapping: Dict[str, str] = field(default_factory=dict)
    tokens: List[str] = field(default_factory=list)
    token_users: List[str] = field(default_factory=list)
    uniswap_mapping: Dict[str, Tuple[str, str]] = field(default_factory=dict)
    actions: List[str] = field(default_factory=list)
    deployments: List[Tuple[str, str]] = field(default_factory=list)
    extra_deployments: List[str] = field(default_factory=list)
    attack_goal: str = ""
    groundtruth: List[Tuple[str, str]] = field(default_factory=list)
    gt_constraints: List[str] = field(default_factory=list)
    

    roles: Dict[str, DefiRoles] = field(default_factory=dict)

    # Not used
    contract_names_mapping: Dict[str, str] = field(default_factory=dict)
    attack_state_variables: List[str] = field(default_factory=list)

    def __post_init__(self):
        keys = list(self.roles.keys())
        for k in keys:
            r = DefiRoles(**self.roles[k])
            self.roles[k] = r


def init_config(bmk_dir: str) -> Config:
    config_path = path.join(bmk_dir, "_config.yaml")
    config_json = {}
    if path.exists(config_path):
        with open(config_path, "r") as f:
            config_json = yaml.safe_load(f)
    config = Config(**config_json)
    return config
