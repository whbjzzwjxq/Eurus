from typing import Dict, Any, Tuple, List

LAMBDA_CONSTR = Any
ACTION_SUMMARY = Tuple[List[str], List[LAMBDA_CONSTR]]


def merge_summary(*summs: ACTION_SUMMARY) -> ACTION_SUMMARY:
    write_vars = []
    constraints = []
    for s in summs:
        w, c = s
        write_vars.extend(w)
        constraints.extend(c)
    return write_vars, constraints


def gen_summary_transfer(
    _from: str, _to: str, token: str, amt: str, percent: float = None
) -> ACTION_SUMMARY:
    bal_from = f"balanceOf{token}{_from}"
    bal_to = f"balanceOf{token}{_to}"
    write_vars = [
        bal_from,
        bal_to,
    ]
    if percent:
        constraints = [
            # Transfer token
            lambda s: s.__getattr__(f"new_{bal_from}")
            == s.__getattr__(f"old_{bal_from}") - s.__getattr__(f"{amt}"),
            lambda s: s.__getattr__(f"new_{bal_to}")
            == s.__getattr__(f"old_{bal_to}") + s.__getattr__(f"{amt}") * percent,
        ]
    else:
        constraints = [
            # Transfer token
            lambda s: s.__getattr__(f"new_{bal_from}")
            == s.__getattr__(f"old_{bal_from}") - s.__getattr__(f"{amt}"),
            lambda s: s.__getattr__(f"new_{bal_to}")
            == s.__getattr__(f"old_{bal_to}") + s.__getattr__(f"{amt}"),
        ]
    return write_vars, constraints


def gen_summary_uniswap(
    pair: str, user: str, asset0: str, asset1: str, amt: str
) -> ACTION_SUMMARY:
    s_in = gen_summary_transfer(user, pair, asset0, amt)
    s_out = gen_summary_transfer(pair, user, asset1, "amtOut", percent=997 / 1000)
    bal_pair_asset0 = f"balanceOf{asset0}{pair}"
    bal_pair_asset1 = f"balanceOf{asset1}{pair}"
    invariant = [
        lambda s: s.__getattr__(f"new_{bal_pair_asset0}")
        * s.__getattr__(f"new_{bal_pair_asset1}")
        == s.__getattr__(f"old_{bal_pair_asset0}")
        * s.__getattr__(f"old_{bal_pair_asset1}"),
    ]
    return merge_summary(s_in, s_out, ([], invariant))


def gen_summary_ratioswap(
    pair: str, oracle: str, user: str, asset0: str, asset1: str, amt: str
) -> ACTION_SUMMARY:
    s_in = gen_summary_transfer(user, pair, asset0, amt)
    s_out = gen_summary_transfer(pair, user, asset1, "amtOut")
    bal_pair_asset0 = f"balanceOf{asset0}{oracle}"
    bal_pair_asset1 = f"balanceOf{asset1}{oracle}"
    invariant = [
        lambda s: s.__getattr__("amtOut") * s.__getattr__(f"old_{bal_pair_asset0}")
        == s.__getattr__(f"{amt}") * s.__getattr__(f"old_{bal_pair_asset1}"),
    ]
    return merge_summary(s_in, s_out, ([], invariant))


hacking_constraints: Dict[str, Dict[str, ACTION_SUMMARY]] = {
    "NMB": {
        "transaction_gnimbstaking_gnimb": (
            ["balanceOfgnimbattacker", "balanceOfgnimbgnimbstaking"],
            [],
        )
    },
    "BXH": {
        "transaction_bxhstaking_bxh": (
            ["balanceOfusdtattacker", "balanceOfusdtbxhstaking"],
            [
                lambda s: s.amtIn == s.arg_0,
                lambda s: s.amtIn >= 0,
                lambda s: s.amtIn <= 10,
                lambda s: s.amountInWithFee == s.amtIn * 10000,
                lambda s: s.numerator == s.amountInWithFee * s.old_balanceOfusdtpair,
                lambda s: s.denominator
                == s.old_balanceOfbxhpair * 10000 + s.amountInWithFee,
                lambda s: s.amtOut * s.denominator == s.numerator,
                lambda s: s.new_balanceOfusdtbxhstaking
                == s.old_balanceOfusdtbxhstaking - s.amtOut,
                lambda s: s.new_balanceOfusdtattacker
                == s.old_balanceOfusdtattacker + s.amtOut,
            ],
        )
    },
    "MUMUG": {
        "swap_mubank_usdce_mu": (
            [
                "balanceOfusdtattacker",
                "balanceOfusdtbxhstaking",
            ],
            [

            ]
        )
    }
}
