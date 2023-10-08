from typing import Dict
from .dsl import ACTION_SUMMARY 

hacking_constraints: Dict[str, Dict[str, ACTION_SUMMARY]] = {
    "NMB": {
        "transaction_Gnimbstaking_Gnimb": (
            [
                "balanceOfGnimbattacker", 
                "balanceOfGnimbGnimbstaking"
            ],
            [
                
            ]
        )
    },
    "BXH": {
        "transaction_bxhstaking_bxh": (
            [
                "balanceOfusdtattacker",
                "balanceOfusdtbxhstaking"
            ],
            [
                lambda s: s.amtIn == s.arg_0,
                lambda s: s.amtIn >= 0,
                lambda s: s.amtIn <= 10,
                lambda s: s.amountInWithFee == s.amtIn * 10000,
                lambda s: s.numerator == s.amountInWithFee * s.old_balanceOfusdtpair,
                lambda s: s.denominator == s.old_balanceOfbxhpair * 10000 + s.amountInWithFee,
                lambda s: s.amtOut * s.denominator == s.numerator,
                
                lambda s: s.new_balanceOfusdtbxhstaking == s.old_balanceOfusdtbxhstaking - s.amtOut,
                lambda s: s.new_balanceOfusdtattacker == s.old_balanceOfusdtattacker + s.amtOut,
            ]
        )
    }
}
