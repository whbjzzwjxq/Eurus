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
    percent_in: float = 1,
    percent_out: float = 1,
) -> ACTION_SUMMARY:
    bal_from = f"{token}.balanceOf({_from})"
    bal_to = f"{token}.balanceOf({_to})"
    write_vars = [
        bal_from,
        bal_to,
    ]
    # Return nothing
    # fmt: off
    constraints = [
        # Transfer token
        lambda s: s.get(f"new_{bal_from}") == s.get(f"old_{bal_from}") - s.get(f"{amt}") * percent_out,
        lambda s: s.get(f"new_{bal_to}") == s.get(f"old_{bal_to}") + s.get(f"{amt}") * percent_in,
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


def gen_summary_burn(victim: str, asset: str, amt: str, min: int = 2):
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


def gen_summary_getAmountsIn(
    amountIn: str,
    amountOut: str,
    reserveIn: str,
    reserveOut: str,
    scale: int = 1000,
    fee: int = 3,
    suffix: str = "",
):
    # Return amountIn
    # require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    # require(
    #     reserveIn > 0 && reserveOut > 0,
    #     "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    # );
    # uint256 numerator = reserveIn * amountOut * 1000;
    # uint256 denominator = (reserveOut - amountOut) * 997;
    # amountIn = numerator / denominator + 1;
    numeratorSuf = f"numeratorSuf{suffix}"
    denominatorSuf = f"denominator{suffix}"
    return [
        # fmt: off
        lambda s: s.get(numeratorSuf) == s.get(reserveIn) * s.get(amountOut) * scale,
        lambda s: s.get(denominatorSuf) == (s.get(reserveOut) - s.get(amountOut)) * (scale - fee),
        lambda s: (s.get(amountIn) - 1) * s.get(denominatorSuf) == s.get(numeratorSuf),
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
    percent_in0: float = 1,
    percent_out0: float = 1,
    percent_in1: float = 997 / 1000,
    percent_out1: float = 1,
) -> ACTION_SUMMARY:
    if transfer0 is None:
        transfer0 = gen_summary_transfer
    if transfer1 is None:
        transfer1 = gen_summary_transfer
    amtOutSuf = f"amtOut{suffix}"
    s_in = transfer0(
        user, pair, asset0, amtIn, percent_in=percent_in0, percent_out=percent_out0
    )
    s_out = transfer1(
        pair, user, asset1, amtOutSuf, percent_in=percent_in1, percent_out=percent_out1
    )
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
    suffix: str = "",
    transfer0: TransferSignature = None,
    transfer1: TransferSignature = None,
    percent_in0: float = 1,
    percent_out0: float = 1,
    percent_in1: float = 1,
    percent_out1: float = 1,
) -> ACTION_SUMMARY:
    if transfer0 is None:
        transfer0 = gen_summary_transfer
    if transfer1 is None:
        transfer1 = gen_summary_transfer
    s_in = gen_summary_transfer(
        user, pair, asset0, amtIn, percent_in=percent_in0, percent_out=percent_out0
    )
    amtOutSuf = f"amtOut{suffix}"
    s_out = gen_summary_transfer(
        pair, user, asset1, amtOutSuf, percent_in=percent_in1, percent_out=percent_out1
    )
    bal_pair_asset0 = f"{asset0}.balanceOf({oracle})"
    bal_pair_asset1 = f"{asset1}.balanceOf({oracle})"
    invariant = [
        # fmt: off
        lambda s: s.get(amtOutSuf) * s.get(f"old_{bal_pair_asset0}") == s.get(amtIn) * s.get(f"old_{bal_pair_asset1}"),
        # fmt: on
    ]
    return merge_summary(s_in, s_out, ([], invariant))

def gen_uniswap_inv(pair: str, asset0: str, asset1: str, swap_for_1: bool, suffix: str = ""):
    # uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
    # uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
    # require(
    #     balance0Adjusted * balance1Adjusted >=
    #         uint256(_reserve0) * _reserve1 * 1e6,
    #     "UniswapV2: K"
    # );
    new_balance0 = f"new_{asset0}.balanceOf({pair})"
    new_balance1 = f"new_{asset1}.balanceOf({pair})"
    old_balance0 = f"old_{asset0}.balanceOf({pair})"
    old_balance1 = f"old_{asset1}.balanceOf({pair})"
    amount0In = f"amount0In{suffix}"
    amount1In = f"amount1In{suffix}"
    balance0Adjusted = f"balance0Adjusted{suffix}"
    balance1Adjusted = f"balance1Adjusted{suffix}"

    if swap_for_1:
        constraints = [
            lambda s: s.get(amount0In) == s.get(new_balance0) - s.get(old_balance0),
            lambda s: s.get(amount1In) == 0,
        ]
    else:
        constraints = [
            lambda s: s.get(amount1In) == s.get(new_balance1) - s.get(old_balance1),
            lambda s: s.get(amount0In) == 0,
        ]
    constraints.extend(
        [
            lambda s: s.get(balance0Adjusted) == s.get(new_balance0) * 1000 - s.get(amount0In) * 3,
            lambda s: s.get(balance1Adjusted) == s.get(new_balance1) * 1000 - s.get(amount1In) * 3,
            lambda s: s.get(balance0Adjusted) * s.get(balance1Adjusted) >= s.get(old_balance0) * s.get(old_balance1) * 1e6
        ]
    )
    return constraints


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


def gen_BGLD_burn_pair_bgld():
    burn_summary = gen_summary_transfer("pair", "dead", "bgld", "arg_0", percent_out=1)
    burn_summary2 = gen_summary_transfer(
        "attacker", "dead", "bgld", "arg_0", percent_out=1.1
    )
    bal_victim = f"new_bgld.balanceOf(pair)"
    bal_attacker = f"old_bgld.balanceOf(attacker)"
    extra_constraints = [
        lambda s: s.get(bal_victim) > 2 / SCALE,
        lambda s: s.get("arg_0") * 11 <= s.get(bal_attacker),
    ]
    return merge_summary(burn_summary, burn_summary2, ([], extra_constraints))


def gen_MUMUG_swap_mubank_usdce_mu():
    _adjusted_amount = "_adjusted_amount"
    mu_coin_amount = "mu_coin_amount"

    reserve0 = "old_usdce.balanceOf(pair)"
    reserve0p = "reserve0"
    reserve1 = "old_mu.balanceOf(pair)"

    amount = "amount"
    amountIN = "amountIN"
    amountOUT = "amountOUT"

    s_in = gen_summary_transfer("attacker", "pair", "usdce", _adjusted_amount)
    s_out = gen_summary_transfer("pair", "attacker", "mu", mu_coin_amount)

    extra_constraints = [
        # _adjusted_amount = (amount / (10 ** (18 - _decimals)));
        lambda s: s.get(_adjusted_amount) == s.get("arg_0") / (10**12),
        lambda s: s.get(amount) == s.get("arg_0"),
        # (uint112 reserve0, uint112 reserve1) = Pair(pair_).getReserves(); //MU/USDC.e TJ LP
        # reserve0 = reserve0 * (10 ** 12);
        lambda s: s.get(reserve0p) == s.get(reserve0) * (10**12),
        # uint256 amountIN = router.getAmountIn(amount, reserve1, reserve0);
        *gen_summary_getAmountsIn(amountIN, amount, reserve1, reserve0p),
        # uint256 amountOUT = router.getAmountOut(amount, reserve0, reserve1);
        *gen_summary_getAmountsOut(amount, amountOUT, reserve0p, reserve1, suffix="out"),
        # uint256 mu_coin_bond_amount = (((((amountIN + amountOUT) * 10)) / 2) / 10);
        # (uint256 mu_coin_swap_amount, uint256 mu_coin_amount) = _mu_bond_quote(amount);
        lambda s: s.get(mu_coin_amount) == (s.get(amountIN) + s.get(amountOUT)) / 2,
    ]
    return merge_summary(s_in, s_out, ([], extra_constraints))


def gen_AES_transfer(_from: str, _to: str, token: str, amt: str):
    write_vars = ["aes.swapFeeTotal"]
    c = [
        lambda s: s.get("new_aes.swapFeeTotal") == s.get("old_aes.swapFeeTotal") + s.get(amt) * 0.01
    ]
    if _from == "pair":
        r = gen_summary_transfer(_from, _to, token, amt, percent_in=0.9, percent_out=0.93)
    else:
        r = gen_summary_transfer(_from, _to, token, amt, percent_in=0.97, percent_out=1)
    return merge_summary(r, (write_vars, c))

def gen_AES_swap_pair_usdt_aes():
    user = "attacker"
    pair = "pair"
    asset0 = "usdt"
    asset1 = "aes"
    amtIn = "arg_0"
    amtOutSuf = f"amtOut"
    s_in = gen_summary_transfer(user, pair, asset0, amtIn)
    s_out = gen_AES_transfer(pair, user, asset1, amtOutSuf)
    bal_pair_asset0 = f"old_{asset0}.balanceOf({pair})"
    bal_pair_asset1 = f"old_{asset1}.balanceOf({pair})"
    extra_constraints = [
        *gen_summary_getAmountsOut(amtIn, amtOutSuf, bal_pair_asset0, bal_pair_asset1),
        # *gen_uniswap_inv("pair", "usdt", "aes", True, "_inv")
    ]
    return merge_summary(s_in, s_out, ([], extra_constraints))

def gen_AES_swap_pair_aes_usdt():
    user = "attacker"
    pair = "pair"
    asset0 = "aes"
    asset1 = "usdt"
    amtIn = "arg_0"
    amtOutSuf = f"amtOut"
    s_in = gen_AES_transfer(user, pair, asset0, amtIn)
    s_out = gen_summary_transfer(pair, user, asset1, amtOutSuf)
    bal_pair_asset0 = f"old_{asset0}.balanceOf({pair})"
    bal_pair_asset1 = f"old_{asset1}.balanceOf({pair})"
    extra_constraints = gen_summary_getAmountsOut(
        amtIn, amtOutSuf, bal_pair_asset0, bal_pair_asset1
    )
    return merge_summary(s_in, s_out, ([], extra_constraints))


def gen_AES_burn_pair_aes():
    arg_0 = "arg_0"
    burn_amount = "burn_amount"
    burn_summary = gen_summary_transfer("pair", "dead", "aes", burn_amount)
    burn_summary2 = gen_summary_transfer("attacker", "dead", "aes", arg_0, percent_out=0.5)
    bal_victim = f"new_aes.balanceOf(pair)"
    bal_attacker = f"old_aes.balanceOf(attacker)"
    extra_writevars = [
        "aes.swapFeeTotal"
    ]
    extra_constraints = [
        lambda s: s.get(bal_victim) > 2 / SCALE,
        lambda s: s.get(arg_0) <= s.get(bal_attacker),
        lambda s: s.get(burn_amount) == s.get(arg_0) * 0.7 + s.get("old_aes.swapFeeTotal") * 6,
        lambda s: s.get("new_aes.swapFeeTotal") == 0,
    ]
    return merge_summary(burn_summary, burn_summary2, (extra_writevars, extra_constraints))


hacking_constraints: Dict[str, Dict[str, ACTION_SUMMARY]] = {
    "NMB": {
        "transaction_gnimbstaking_gnimb": gen_NMB_transaction_gnimbstaking_gnimb(),
    },
    "BXH": {
        "transaction_bxhstaking_bxh": gen_BXH_transaction_bxhstaking_bxh(),
    },
    "BGLD": {
        "swap_pair_wbnb_bgld": gen_summary_uniswap(
            "pair", "attacker", "wbnb", "bgld", "arg_0", percent_in1=0.9
        ),
        "swap_pair_bgld_wbnb": gen_summary_uniswap(
            "pair", "attacker", "bgld", "wbnb", "arg_0", percent_out0=1.1
        ),
        "burn_pair_bgld": gen_BGLD_burn_pair_bgld(),
    },
    "MUMUG": {
        "swap_mubank_usdce_mu": gen_MUMUG_swap_mubank_usdce_mu(),
    },
    "AES": {
        "swap_pair_usdt_aes": gen_AES_swap_pair_usdt_aes(),
        "swap_pair_aes_usdt": gen_AES_swap_pair_aes_usdt(),
        "burn_pair_aes": gen_AES_burn_pair_aes(),
    }
}

refine_constraints: Dict[str, Dict[int, List[LAMBDA_CONSTR]]] = {
    "ShadowFi": {},
    "BXH": {},
}
