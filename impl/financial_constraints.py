from typing import Callable, Dict, Any, Tuple, List

# lambda VarGetter => constraint
LAMBDA_CONSTR = Callable[[Any], Any]
ACTION_SUMMARY = Tuple[List[str], List[LAMBDA_CONSTR]]

DECIMAL = 18
# DECIMAL = 0
SCALE = 10**DECIMAL

def merge_summary(*summs: ACTION_SUMMARY) -> ACTION_SUMMARY:
    write_vars = []
    constraints = []
    for s in summs:
        w, c = s
        write_vars.extend(w)
        constraints.extend(c)
    return write_vars, constraints


TransferSignature = Callable[[str, str, str, str, float], ACTION_SUMMARY]


def gen_summary_transfer(
    _from: str,
    _to: str,
    token: str,
    amt: str,
    percent: float = None,
) -> ACTION_SUMMARY:
    bal_from = f"{token}.balanceOf({_from})"
    bal_to = f"{token}.balanceOf({_to})"
    write_vars = [
        bal_from,
        bal_to,
    ]
    # Return nothing
    # fmt: off
    if percent:
        constraints = [
            # Transfer token
            lambda s: s.get(f"new_{bal_from}") == s.get(f"old_{bal_from}") - s.get(f"{amt}"),
            lambda s: s.get(f"new_{bal_to}") == s.get(f"old_{bal_to}") + s.get(f"{amt}") * percent,
        ]
    else:
        constraints = [
            # Transfer token
            lambda s: s.get(f"new_{bal_from}") == s.get(f"old_{bal_from}") - s.get(f"{amt}"),
            lambda s: s.get(f"new_{bal_to}") == s.get(f"old_{bal_to}") + s.get(f"{amt}"),
        ]
    # fmt: on
    return write_vars, constraints


def gen_summary_payback(
    _from: str,
    _to: str,
    asset: str,
    borrow_amt: str,
    payback_amt: str,
    scale: int = 1000,
    fee: int = 3,
):
    # fmt: off
    interest_rate = lambda s: s.get(payback_amt) == s.get(borrow_amt) * (scale + fee) / (scale)
    write_vars, constraints = gen_summary_transfer(_from, _to, asset, payback_amt)
    # fmt: on
    return write_vars, [*constraints, interest_rate]


def gen_summary_burn(
    victim: str,
    asset: str,
    amt: str,
    min: int = 2000
):
    burn_summary = gen_summary_transfer(victim, "dead", asset, amt)
    bal_victim = f"new_{asset}.balanceOf({victim})"
    extra_constraints = [lambda s: s.get(bal_victim) > min / SCALE]
    return merge_summary(burn_summary, ([], extra_constraints))


def gen_summary_getAmountsOut(
    amountIn: str,
    amountOut: str,
    reserveIn: str,
    reserveOut: str,
    scale: int = 1000,
    fee: int = 3,
    suffix: str = "",
):
    # Return amountOut
    # Source code
    # require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    # require(
    #     reserveIn > 0 && reserveOut > 0,
    #     "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    # );
    # uint256 amountInWithFee = amountIn * 997;
    # uint256 numerator = amountInWithFee * reserveOut;
    # uint256 denominator = reserveIn * 1000 + amountInWithFee;
    # amountOut = numerator / denominator;
    amountInWithFeeSuf = f"amountInWithFee{suffix}"
    numeratorSuf = f"numeratorSuf{suffix}"
    denominatorSuf = f"denominator{suffix}"
    return [
        # fmt: off
        lambda s: s.get(amountInWithFeeSuf) == s.get(amountIn) * (scale - fee),
        lambda s: s.get(numeratorSuf) == s.get(amountInWithFeeSuf) * s.get(reserveOut),
        lambda s: s.get(denominatorSuf) == s.get(reserveIn) * scale + s.get(amountInWithFeeSuf),
        lambda s: s.get(amountOut) * s.get(denominatorSuf) == s.get(numeratorSuf),
        # fmt: on
    ]


def gen_summary_uniswap(
    pair: str,
    user: str,
    asset0: str,
    asset1: str,
    amtIn: str,
    suffix: str = "",
    transfer0: TransferSignature = None,
    transfer1: TransferSignature = None,
) -> ACTION_SUMMARY:
    if transfer0 is None:
        transfer0 = gen_summary_transfer
    if transfer1 is None:
        transfer1 = gen_summary_transfer
    amtOutSuf = f"amtOut{suffix}"
    s_in = transfer0(user, pair, asset0, amtIn)
    s_out = transfer1(pair, user, asset1, amtOutSuf, percent=997 / 1000)
    bal_pair_asset0 = f"old_{asset0}.balanceOf({pair})"
    bal_pair_asset1 = f"old_{asset1}.balanceOf({pair})"
    extra_constraints = gen_summary_getAmountsOut(
        amtIn, amtOutSuf, bal_pair_asset0, bal_pair_asset1
    )
    return merge_summary(s_in, s_out, ([], extra_constraints))


def gen_summary_ratioswap(
    pair: str,
    oracle: str,
    user: str,
    asset0: str,
    asset1: str,
    amtIn: str,
    percent: float = None,
    suffix: str = "",
    transfer0: TransferSignature = None,
    transfer1: TransferSignature = None,
) -> ACTION_SUMMARY:
    if transfer0 is None:
        transfer0 = gen_summary_transfer
    if transfer1 is None:
        transfer1 = gen_summary_transfer
    s_in = gen_summary_transfer(user, pair, asset0, amtIn)
    amtOutSuf = f"amtOut{suffix}"
    s_out = gen_summary_transfer(pair, user, asset1, amtOutSuf, percent=percent)
    bal_pair_asset0 = f"{asset0}.balanceOf({oracle})"
    bal_pair_asset1 = f"{asset1}.balanceOf({oracle})"
    invariant = [
        # fmt: off
        lambda s: s.get(amtOutSuf) * s.get(f"old_{bal_pair_asset0}") == s.get(amtIn) * s.get(f"old_{bal_pair_asset1}"),
        # fmt: on
    ]
    return merge_summary(s_in, s_out, ([], invariant))


def gen_attack_goal(token: str, amount: str, scale: int) -> LAMBDA_CONSTR:
    attack_goal_varstr = f"{token}.balanceOf(attacker)"
    # fmt: off
    attack_goal = lambda s: s.get(f"old_{attack_goal_varstr}") >= s.get(f"init_{attack_goal_varstr}") + int(float(amount)) / scale
    # fmt: on
    return attack_goal


def gen_NMB_transaction_gnimbstaking_gnimb():
    balances_nbu_pair = f"old_nbu.balanceOf(pairnbunimb)"
    balances_nimb_pair = f"old_nimb.balanceOf(pairnbunimb)"
    amount_base = "amtIn"
    amount_out = "amtOut"

    uint256_zero = "uint256(0)"
    # Compute reward base amount
    reward_base_amount = [
        # fmt: off
        lambda s: s.get(f"new_gnimbstaking.stakeNonceInfos[attacker][{uint256_zero}].stakeTime") == s.get("old_block.timestamp"),
        lambda s: s.get(amount_base) == s.get(f"old_gnimbstaking.stakeNonceInfos[attacker][{uint256_zero}].rewardsTokenAmount")
        * (s.get("old_block.timestamp") - s.get(f"old_gnimbstaking.stakeNonceInfos[attacker][{uint256_zero}].stakeTime"))
        * s.get(f"old_gnimbstaking.stakeNonceInfos[attacker][{uint256_zero}].rewardRate")
        # rewardDuration = 365 * 24 * 60 * 60
        / (100 * 365 * 24 * 60 * 60),
    ]

    # Compute reward amount
    reward_amount = gen_summary_getAmountsOut(
        amount_base,
        amount_out,
        balances_nbu_pair,
        balances_nimb_pair,
    )

    extra_constraints = [*reward_base_amount, *reward_amount]

    extra_write_vars = [
        f"gnimbstaking.stakeNonceInfos[attacker][{uint256_zero}].stakeTime"
    ]

    # The reward constraint system
    reward_summary = (extra_write_vars, extra_constraints)
    transfer_summary = gen_summary_transfer(
        "gnimbstaking", "attacker", "gnimb", amount_out
    )
    return merge_summary(reward_summary, transfer_summary)


def gen_BXH_transaction_bxhstaking_bxh():
    balances_bxh_pair = f"bxh.balanceOf(pair)"
    balances_usdt_pair = f"usdt.balanceOf(pair)"
    amount_base = "amtIn"
    amount_out = "amtOut"

    reward_base_amount = [lambda s: s.get("arg_0") == s.get(amount_base)]

    #
    reward_amount = gen_summary_getAmountsOut(
        amount_base, amount_out, balances_bxh_pair, balances_usdt_pair
    )

    extra_constraints = [*reward_base_amount, *reward_amount]

    reward_summary = ([], extra_constraints)
    transfer_summary = gen_summary_transfer(
        "bxhstaking", "attacker", "usdt", amount_out
    )
    return merge_summary(reward_summary, transfer_summary)


hacking_constraints: Dict[str, Dict[str, ACTION_SUMMARY]] = {
    "NMB": {
        "transaction_gnimbstaking_gnimb": gen_NMB_transaction_gnimbstaking_gnimb(),
    },
    "BXH": {
        "transaction_bxhstaking_bxh": gen_BXH_transaction_bxhstaking_bxh(),
    },
    "BGLD": {

    },
    "MUMUG": {
        "swap_mubank_usdce_mu": (
            [],
            [],
        )
    },
}

refine_constraints: Dict[str, Dict[int, List[LAMBDA_CONSTR]]] = {
    "ShadowFi": {

    },
    "BXH": {

    },

}
