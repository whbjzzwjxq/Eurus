from typing import Callable, Dict, Any, Tuple, List, Set

# lambda VarGetter => constraint
LAMBDA_CONSTR = Callable[[Any], Any]
ACTION_CONSTR = List[LAMBDA_CONSTR]
TRANSFER_SIGNATURE = Callable[[str, str, str, str, float, float], ACTION_CONSTR]
DEAD = "dead"

class ConstraintsExtracter:
    def __init__(self) -> None:
        self.read_vars = set()
        self.write_vars = set()

    def get(self, __name: str):
        if __name.startswith("old_"):
            key = __name.removeprefix("old_")
            self.read_vars.add(key)
        elif __name.startswith("new_"):
            key = __name.removeprefix("new_")
            self.write_vars.add(key)


def extract_rw_vars(constraints: List[LAMBDA_CONSTR]) -> Tuple[Set[str], Set[str]]:
    # Init storage variables
    creator = ConstraintsExtracter()
    for lambd in constraints:
        try:
            _ = lambd(creator)
        except Exception:
            pass
    return creator.read_vars, creator.write_vars


def gen_summary_transfer(
    sender: str,
    receiver: str,
    token: str,
    amt: str,
    percent_in: float = 1,
    percent_out: float = 1,
) -> ACTION_CONSTR:
    bal_from = f"{token}.balanceOf({sender})"
    bal_to = f"{token}.balanceOf({receiver})"
    # fmt: off
    constraints = [
        # Transfer token
        lambda s: s.get(f"new_{bal_from}") == s.get(f"old_{bal_from}") - s.get(amt) * percent_out,
        lambda s: s.get(f"new_{bal_to}") == s.get(f"old_{bal_to}") + s.get(amt) * percent_in,
    ]
    # fmt: on
    return constraints


def gen_summary_payback(
    sender: str,
    receiver: str,
    token: str,
    amt_borrow: str,
    amt_payback: str,
    percent_in: float = 1,
    percent_out: float = 1,
    scale: int = 1000,
    fee: int = 3,
) -> ACTION_CONSTR:
    # fmt: off
    interest_rate = lambda s: s.get(amt_payback) == s.get(amt_borrow) * (scale + fee) / (scale)
    constraints = gen_summary_transfer(sender, receiver, token, amt_payback, percent_in, percent_out)
    # fmt: on
    return [*constraints, interest_rate]


def gen_summary_getAmountsOut(
    amountIn: str,
    amountOut: str,
    reserveIn: str,
    reserveOut: str,
    scale: int = 1000,
    fee: int = 3,
    suffix: str = "",
) -> ACTION_CONSTR:
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
) -> ACTION_CONSTR:
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
    sender: str,
    receiver: str,
    token0: str,
    token1: str,
    amtIn: str,
    amtOut: str,
    percent_in0: float = 1,
    percent_out0: float = 1,
    percent_in1: float = 1,
    percent_out1: float = 1,
    scale: int = 1000,
    fee: int = 3,
    suffix: str = "",
) -> ACTION_CONSTR:
    s_in = gen_summary_transfer(sender, pair, token0, amtIn, percent_in0, percent_out0)
    s_out = gen_summary_transfer(pair, receiver, token1, amtOut, percent_in=percent_in1, percent_out=percent_out1)

    # Generate Invariants
    new_bal0_pair = f"new_{token0}.balanceOf({pair})"
    new_bal1_pair = f"new_{token1}.balanceOf({pair})"
    old_bal0_pair = f"old_{token0}.balanceOf({pair})"
    old_bal1_pair = f"old_{token1}.balanceOf({pair})"
    invariants = [
        lambda s: s.get(new_bal0_pair) * s.get(new_bal1_pair) * (scale - fee) / scale
        >= s.get(old_bal0_pair) * s.get(old_bal1_pair),
    ]
    return [*s_in, *s_out, *invariants]


def gen_summary_ratioswap(
    pair: str,
    sender: str,
    receiver: str,
    token0: str,
    token1: str,
    amtIn: str,
    amtOut: str,
    oracle: str,
    percent_in0: float = 1,
    percent_out0: float = 1,
    percent_in1: float = 1,
    percent_out1: float = 1,
    suffix: str = "",
) -> ACTION_CONSTR:
    s_in = gen_summary_transfer(sender, pair, token0, amtIn, percent_in=percent_in0, percent_out=percent_out0)
    s_out = gen_summary_transfer(pair, receiver, token1, amtOut, percent_in=percent_in1, percent_out=percent_out1)

    old_bal0_oracle = f"old_{token0}.balanceOf({oracle})"
    old_bal1_oracle = f"old_{token1}.balanceOf({oracle})"
    invariants = [
        # fmt: off
        lambda s: s.get(amtOut) * s.get(old_bal0_oracle) == s.get(amtIn) * s.get(old_bal1_oracle),
        # fmt: on
    ]
    return [*s_in, *s_out, *invariants]


def gen_attack_goal(token: str, amount: str, scale: int) -> LAMBDA_CONSTR:
    attack_goal_varstr = f"{token}.balanceOf(attacker)"
    # fmt: off
    attack_goal = lambda s: s.get(f"old_{attack_goal_varstr}") >= s.get(f"init_{attack_goal_varstr}") + int(float(amount)) / scale
    # fmt: on
    return attack_goal


# TODO


def gen_NMB_transaction_gnimbstaking_gnimb():
    pair_bal_nbu = f"old_nbu.balanceOf(pairnbunimb)"
    pair_bal_nimb = f"old_nimb.balanceOf(pairnbunimb)"
    amount_base = "amtIn"
    amount_out = "amtOut"

    stake_info = f"gnimbstaking.stakeNonceInfos[attacker][uint256(0)]"
    # Compute reward base amount
    reward_base_amount = [
        # fmt: off
        lambda s: s.get(f"new_{stake_info}.stakeTime") == s.get("old_block.timestamp"),
        lambda s: s.get(amount_base) == s.get(f"old_{stake_info}.rewardsTokenAmount")
        * (s.get("old_block.timestamp") - s.get(f"old_{stake_info}.stakeTime"))
        * s.get(f"old_{stake_info}.rewardRate")
        # rewardDuration = 365 * 24 * 60 * 60
        / (100 * 365 * 24 * 60 * 60),
    ]

    # Compute reward amount
    reward_amount = gen_summary_getAmountsOut(
        amount_base,
        amount_out,
        pair_bal_nbu,
        pair_bal_nimb,
    )

    reward_summary = [*reward_base_amount, *reward_amount]

    # The reward constraint system
    transfer_summary = gen_summary_transfer("gnimbstaking", "attacker", "gnimb", amount_out)
    return [*reward_summary, *transfer_summary]


def gen_BXH_transaction_bxhstaking_bxh():
    balances_bxh_pair = f"old_bxh.balanceOf(pair)"
    balances_usdt_pair = f"old_usdt.balanceOf(pair)"
    amount_in = "amtIn"
    amount_out = "amtOut"

    reward_base_amount = [lambda s: 15.24 == s.get(amount_in)]

    #
    reward_amount = gen_summary_getAmountsOut(amount_in, amount_out, balances_bxh_pair, balances_usdt_pair)

    reward_summary = [*reward_base_amount, *reward_amount]

    transfer_summary0 = gen_summary_transfer("bxhstaking", "attacker", "usdt", amount_out)
    transfer_summary1 = gen_summary_transfer("attacker", "bxhstaking", "bxh", amount_in)
    return [*reward_summary, *transfer_summary0, *transfer_summary1]


def gen_BGLD_burn_pair_bgld():
    burn_summary = gen_summary_transfer("pair", DEAD, "bgld", "arg_0", percent_out=1)
    burn_summary2 = gen_summary_transfer("attacker", DEAD, "bgld", "arg_0", percent_out=1.1)
    bal_victim = f"new_bgld.balanceOf(pair)"
    bal_attacker = f"old_bgld.balanceOf(attacker)"
    extra_constraints = [lambda s: s.get("arg_0") * 11 <= s.get(bal_attacker)]
    return [*burn_summary, *burn_summary2, *extra_constraints]


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
    return [*s_in, *s_out, *extra_constraints]


def gen_AES_transfer(_from: str, _to: str, token: str, amt: str):
    c = [lambda s: s.get("new_aes.swapFeeTotal") == s.get("old_aes.swapFeeTotal") + s.get(amt) * 0.01]
    if _from == "pair":
        r = gen_summary_transfer(_from, _to, token, amt, percent_in=0.9, percent_out=0.93)
    else:
        r = gen_summary_transfer(_from, _to, token, amt, percent_in=0.97, percent_out=1)
    return [*r, *c]


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
    return [*s_in, *s_out, *extra_constraints]


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
    extra_constraints = gen_summary_getAmountsOut(amtIn, amtOutSuf, bal_pair_asset0, bal_pair_asset1)
    return [*s_in, *s_out, *extra_constraints]


def gen_AES_burn_pair_aes():
    arg_0 = "arg_0"
    burn_amount = "burn_amount"
    burn_summary = gen_summary_transfer("pair", DEAD, "aes", burn_amount)
    burn_summary2 = gen_summary_transfer("attacker", DEAD, "aes", arg_0, percent_out=0.5)
    bal_victim = f"new_aes.balanceOf(pair)"
    bal_attacker = f"old_aes.balanceOf(attacker)"
    extra_constraints = [
        lambda s: s.get(arg_0) <= s.get(bal_attacker),
        lambda s: s.get(burn_amount) == s.get(arg_0) * 0.7 + s.get("old_aes.swapFeeTotal") * 6,
        lambda s: s.get("new_aes.swapFeeTotal") == 0,
    ]
    return [*burn_summary, *burn_summary2, *extra_constraints]


def gen_SGZ_addliquidity_pair_sgz():
    transfer_summary0 = gen_summary_transfer("sgz", "pair", "sgz", "old_sgz.balanceOf(sgz)")
    transfer_summary1 = gen_summary_transfer("sgz", "pair", "usdt", "old_usdt.balanceOf(sgz)")
    return [*transfer_summary0, *transfer_summary1]


def gen_RADTDAO_burn_pair_radt():
    # uint256 backAmount = amount / 100;
    # uint256 keepAmount = amount / 2000;
    # uint256 burnAmount = token.balanceOf(to) - backAmount - keepAmount;
    # token.transferFrom(to, from, backAmount);
    # token.transferFrom(to, address(0xdead), burnAmount);
    amt = "arg_0"
    backAmount = "backAmount"
    keepAmount = "keepAmount"
    burnAmount = "burnAmount"
    extra_constraints = [
        lambda s: s.get(backAmount) == s.get(amt) / 100,
        lambda s: s.get(keepAmount) == s.get(amt) / 2000,
        lambda s: s.get(burnAmount) == s.get("old_radt.balanceOf(pair)") - s.get(backAmount) - s.get(keepAmount),
    ]
    transfer_summary0 = gen_summary_transfer("pair", "owner", "radt", backAmount)
    transfer_summary1 = gen_summary_transfer("pair", DEAD, "radt", burnAmount)
    return [*transfer_summary0, *transfer_summary1, *extra_constraints]


def gen_Zoompro_addliquidity_pair_controller():
    return gen_summary_transfer("controller", "pair", "fusdt", "old_fusdt.balanceOf(controller)")


def gen_Zoompro_swap_trader_usdt_zoom():
    return [
        *gen_summary_transfer("attacker", "trader", "usdt", "arg_0"),
        *gen_summary_uniswap("pair", "trader", "fusdt", "zoom", "arg_0", receiver="attacker"),
    ]


def gen_Zoompro_swap_trader_zoom_usdt():
    usdtOut = "amountOut"
    return [
        *gen_summary_uniswap("pair", "attacker", "zoom", "fusdt", "arg_0", receiver="trader"),
        *gen_summary_transfer("trader", "attacker", "usdt", usdtOut),
        *gen_summary_getAmountsOut("arg_0", usdtOut, "old_zoom.balanceOf(pair)", "old_fusdt.balanceOf(pair)"),
    ]


def gen_ShadowFi_refinement():
    trans_limit = 1e-4
    return [
        {
            "burn_pair_sdf": [
                lambda s: s.get("old_sdf.balanceOf(pair)") - s.get("new_sdf.balanceOf(pair)") <= trans_limit,
            ]
        },
        {
            "swap_pair_sdf_wbnb": [
                lambda s: s.get("old_sdf.balanceOf(attacker)") - s.get("new_sdf.balanceOf(attacker)") <= trans_limit,
            ]
        },
    ]


def gen_BXH_refinement():
    return [
        {
            "transaction_bxhstaking_bxh": [
                lambda s: s.get("amtIn") == 0,
            ]
        }
    ]


hack_constraints: Dict[str, Dict[str, ACTION_CONSTR]] = {
    "NMB": {
        "transaction_gnimbstaking_gnimb": gen_NMB_transaction_gnimbstaking_gnimb(),
    },
    "BXH": {
        "transaction_bxhstaking_bxh": gen_BXH_transaction_bxhstaking_bxh(),
    },
    "BGLD": {
        "swap_pair_wbnb_bgld": gen_summary_uniswap("pair", "attacker", "wbnb", "bgld", "arg_0", percent_in1=0.9),
        "swap_pair_bgld_wbnb": gen_summary_uniswap("pair", "attacker", "bgld", "wbnb", "arg_0", percent_out0=1.1),
        "burn_pair_bgld": gen_BGLD_burn_pair_bgld(),
    },
    "MUMUG": {
        "swap_mubank_usdce_mu": gen_MUMUG_swap_mubank_usdce_mu(),
    },
    "AES": {
        "swap_pair_usdt_aes": gen_AES_swap_pair_usdt_aes(),
        "swap_pair_aes_usdt": gen_AES_swap_pair_aes_usdt(),
        "burn_pair_aes": gen_AES_burn_pair_aes(),
    },
    "SGZ": {
        "addliquidity_pair_sgz": gen_SGZ_addliquidity_pair_sgz(),
    },
    "RADTDAO": {
        "burn_pair_radt": gen_RADTDAO_burn_pair_radt(),
    },
    "Zoompro": {
        "addliquidity_pair_controller": gen_Zoompro_addliquidity_pair_controller(),
        "swap_trader_usdt_zoom": gen_Zoompro_swap_trader_usdt_zoom(),
        "swap_trader_zoom_usdt": gen_Zoompro_swap_trader_zoom_usdt(),
    },
}

refine_constraints: Dict[str, List[Dict[str, List[LAMBDA_CONSTR]]]] = {
    "ShadowFi": gen_ShadowFi_refinement(),
    "BXH": gen_BXH_refinement(),
}
