from typing import Dict, Type

from ._deployer import ContractDeployer
from .PuppetPool import PuppetPool
from .TokenBurn import TokenBurn

bmk_selector: Dict[str, Type[ContractDeployer]] = {
    "PuppetPool": PuppetPool,
    "TokenBurner": TokenBurn,
}
