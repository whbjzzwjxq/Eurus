from typing import Callable, Dict, Any, Tuple, List

# lambda VarGetter => constraint
LAMBDA_CONSTR = Callable[[Any], Any]
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
    bal_from = f"{token}._balances[{_from}]"
    bal_to = f"{token}._balances[{_to}]"
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
    bal_pair_asset0 = f"{asset0}._balances[{pair}]"
    bal_pair_asset1 = f"{asset1}._balances[{pair}]"
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
    bal_pair_asset0 = f"{asset0}._balances[{oracle}]"
    bal_pair_asset1 = f"{asset1}._balances[{oracle}]"
    invariant = [
        lambda s: s.__getattr__("amtOut") * s.__getattr__(f"old_{bal_pair_asset0}")
        == s.__getattr__(f"{amt}") * s.__getattr__(f"old_{bal_pair_asset1}"),
    ]
    return merge_summary(s_in, s_out, ([], invariant))


def gen_attack_goal(token: str, amount: str, scale: int) -> LAMBDA_CONSTR:
    attack_goal_varstr = f"{token}._balances[attacker]"
    # fmt: off
    attack_goal = lambda s: s.__getattr__(f"old_{attack_goal_varstr}") >= s.__getattr__(f"init_{attack_goal_varstr}") + int(float(amount)) / scale
    # fmt: on
    return attack_goal


hacking_constraints: Dict[str, Dict[str, ACTION_SUMMARY]] = {
    "NMB": {
        "transaction_gnimbstaking_gnimb": (
            ["balanceOfgnimbattacker", "balanceOfgnimbgnimbstaking"],
            [],
        )
    },
    "BXH": {
        "transaction_bxhstaking_bxh": (
            ["usdt._balances[attacker]", "usdt.balances[bxhstaking]"],
            [
                lambda s: s.amtIn == s.arg_0,
                lambda s: s.amtIn >= 0,
                lambda s: s.amtIn <= 10,
                lambda s: s.amountInWithFee == s.amtIn * 10000,
                lambda s: s.numerator == s.amountInWithFee * s.__getattr__("old_usdt._balances[pair]"),
                lambda s: s.denominator
                == s.__getattr__("old_bxh._balances[pair]") * 10000 + s.amountInWithFee,
                lambda s: s.amtOut * s.denominator == s.numerator,
                lambda s: s.__getattr__("new_usdt._balances[bxhstaking]")
                == s.__getattr__("old_usdt._balances[bxhstaking]") - s.amtOut,
                lambda s: s.__getattr__("new_usdt._balances[attacker]")
                == s.__getattr__("old_usdt._balances[attacker]") + s.amtOut,
            ],
        )
    },
    "MUMUG": {
        "swap_mubank_usdce_mu": (
            [
                "usdt._balances[attacker]",
                "balanceOfusdtbxhstaking",
            ],
            [],
        )
    },
}
