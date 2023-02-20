from typing import Dict, Type

from ._deployer import ContractDeployer
from .BZXiToken import BZXiToken
from .Duplicator import Duplicator
from .FreeRider import FreeRider
from .Killme import Killme
from .NaiveReceiver import NaiveReceiver
from .PuppetPool import PuppetPool
from .Rewarder import Rewarder
from .TokenBurner import TokenBurner
from .Unstoppable import Unstoppable
from .Whosyourowner import Whosyourowner

bmk_selector: Dict[str, Type["ContractDeployer"]] = {
    "BZXiToken": BZXiToken,
    "FreeRider": FreeRider,
    "Killme": Killme,
    "NaiveReceiver": NaiveReceiver,
    "PuppetPool": PuppetPool,
    "Rewarder": Rewarder,
    "TokenBurner": TokenBurner,
    "Unstoppable": Unstoppable,
    "Duplicator": Duplicator,
    "Whosyourowner": Whosyourowner,
}
