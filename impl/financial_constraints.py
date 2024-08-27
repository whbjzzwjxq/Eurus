from typing import Callable, Dict, Any, Tuple, List, Set

from z3 import If


def z3abs(x):
    return If(x >= 0, x, -x)


DECIMAL = 18
SCALE = 10**DECIMAL

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
        return 1


def extract_rw_vars(constraints: List[LAMBDA_CONSTR]) -> Tuple[Set[str], Set[str]]:
    # Init storage variables
    creator = ConstraintsExtracter()
    for lambd in constraints:
        lambd(creator)
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
    interest_rate = lambda s: s.get(amt_payback) >= s.get(amt_borrow) * (scale + fee) / (scale)
    constraints = gen_summary_transfer(sender, receiver, token, amt_payback, percent_in, percent_out)
    # fmt: on
    return [*constraints, interest_rate]


def gen_summary_burn(
    sender: str,
    token: str,
    amt: str,
    percent_out: float = 1,
) -> ACTION_CONSTR:
    bal_from = f"{token}.balanceOf({sender})"
    # fmt: off
    constraints = [
        # Transfer token
        lambda s: s.get(f"new_{bal_from}") == s.get(f"old_{bal_from}") - s.get(amt) * percent_out,
    ]
    underflow = [
        lambda s: s.get(f"new_{token}.balanceOf({sender})") >= 1 / SCALE,
    ]
    # fmt: on
    return [*constraints, *underflow]


def gen_summary_mint(
    receiver: str,
    token: str,
    amt: str,
    percent_in: float = 1,
) -> ACTION_CONSTR:
    bal_to = f"{token}.balanceOf({receiver})"
    # fmt: off
    constraints = [
        # Transfer token
        lambda s: s.get(f"new_{bal_to}") == s.get(f"old_{bal_to}") + s.get(amt) * percent_in,
    ]
    # fmt: on
    return constraints


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
        # lambda s: z3abs(s.get(amountOut) * s.get(denominatorSuf) - s.get(numeratorSuf)) <= 1e-3,
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
    tokenIn: str,
    tokenOut: str,
    amtIn: str,
    amtOut: str,
    amtOutRatio: float = 1,
    percent_in_tokenIn: float = 1,
    percent_out_tokenIn: float = 1,
    percent_in_tokenOut: float = 1,
    percent_out_tokenOut: float = 1,
    scale: int = 1000,
    fee: int = 3,
    suffix: str = "",
    outMax = False,
) -> ACTION_CONSTR:
    amtOutMax = "amtOutMax"
    s_in = gen_summary_transfer(sender, pair, tokenIn, amtIn, percent_in=percent_in_tokenIn, percent_out=percent_out_tokenIn)
    s_out = gen_summary_transfer(
        pair, receiver, tokenOut, amtOut, percent_in=percent_in_tokenOut, percent_out=percent_out_tokenOut
    )

    # Generate Invariants
    old_balIn_pair = f"old_{tokenIn}.balanceOf({pair})"
    old_balOut_pair = f"old_{tokenOut}.balanceOf({pair})"
    if outMax:
        invariants = [
            lambda s: s.get(amtOut) == s.get(amtOutMax) * amtOutRatio,
            *gen_summary_getAmountsOut(amtIn, amtOutMax, old_balIn_pair, old_balOut_pair, scale, fee, suffix),
        ]
    else:
        invariants = [
            lambda s: s.get(amtOut) < s.get(amtOutMax) * amtOutRatio,
            *gen_summary_getAmountsOut(amtIn, amtOutMax, old_balIn_pair, old_balOut_pair, scale, fee, suffix),
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
def gen_NMB_deposit_gslp_gnimb_gslp():
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

# TODO
def gen_NMB_withdraw_gslp_gslp_gnimb():
    pass


def gen_BXH_deposit_bxhstaking_bxh_bxhslp():
    attacker = "attacker"
    bxhstaking = "bxhstaking"
    bxh = "bxh"

    user_amount = "bxhstaking.user_amount"
    user_rewardDebt = "bxhstaking.user_rewardDebt"
    pool_accITokenPerShare = "bxhstaking.pool_accITokenPerShare"

    amtIn = "arg_0"

    constraints = [
        *gen_summary_transfer(attacker, bxhstaking, bxh, amtIn),
        lambda s: s.get(f"new_{user_amount}") == s.get(f"old_{user_amount}") + s.get(amtIn),
        lambda s: s.get(f"new_{user_rewardDebt}")
        == s.get(f"new_{user_amount}") * s.get(f"old_{pool_accITokenPerShare}") / 1e12,

        # Utils to read storage variables.
        lambda s: s.get(f"old_{pool_accITokenPerShare}") == 302134620363430811000011,
    ]

    return constraints


def gen_BXH_withdraw_bxhstaking_bxhslp_usdt():
    attacker = "attacker"
    bxhstaking = "bxhstaking"
    usdt = "usdt"
    reserveIn = f"old_bxh.balanceOf(pair)"
    reserveOut = f"old_usdt.balanceOf(pair)"

    pendingAmount = "pendingAmount"
    pendingAmount1 = "pendingAmount1"

    user_amount = "bxhstaking.user_amount"
    user_rewardDebt = "bxhstaking.user_rewardDebt"
    pool_accITokenPerShare = "bxhstaking.pool_accITokenPerShare"

    constraints = [
        lambda s: s.get(f"new_{pool_accITokenPerShare}") == s.get(f"old_{pool_accITokenPerShare}") + 1e12 * 5 / 1000,
        lambda s: s.get(pendingAmount)
        == s.get(f"old_{user_amount}") * s.get(f"new_{pool_accITokenPerShare}") / 1e12
        - s.get(f"old_{user_rewardDebt}"),
        *gen_summary_getAmountsOut(pendingAmount, pendingAmount1, reserveIn, reserveOut),
        *gen_summary_transfer(bxhstaking, attacker, usdt, pendingAmount1),
        # Others are ignored.
    ]
    return constraints


def gen_BGLD_burn_bgld_pair():
    burn_amount = "burnAmount"
    burn_summary = gen_summary_transfer("pair", DEAD, "bgld", burn_amount, percent_out=1)
    burn_summary2 = gen_summary_transfer("attacker", DEAD, "bgld", burn_amount, percent_out=1.1)
    old_bal_attacker = f"old_bgld.balanceOf(attacker)"
    old_bal_pair = f"old_bgld.balanceOf(pair)"
    new_bal_pair = f"new_bgld.balanceOf(pair)"
    extra_constraints = [
        lambda s: s.get("arg_0") == s.get(burn_amount) * 10,
        lambda s: s.get("arg_0") < s.get(old_bal_attacker),
        lambda s: s.get(new_bal_pair) >= 1 / SCALE,
    ]
    return [*burn_summary, *burn_summary2, *extra_constraints]


def gen_BGLD_swap_pair_attacker_bgld_wbnb():
    return gen_summary_uniswap("pair", "attacker", "attacker", "bgld", "wbnb", "arg_0", "arg_1", percent_out_tokenIn=1.1)


def gen_BGLD_swap_pair_attacker_wbnb_bgld():
    return gen_summary_uniswap(
        "pair", "attacker", "attacker", "wbnb", "bgld", "arg_0", "arg_1", amtOutRatio=0.9, percent_out_tokenOut=1.1
    )


def gen_MUMUG_swap_mubank_attacker_usdce_mu():
    _adjusted_amount = "_adjusted_amount"
    mu_coin_amount = "mu_coin_amount"

    reserve0 = "reserve0"
    reserve0p = "reserve0p"
    reserve1 = "reserve1"

    amount = "amount"
    amountIN = "amountIN"
    amountOUT = "amountOUT"

    s_in = gen_summary_transfer("attacker", "mubank", "usdce", _adjusted_amount)
    s_out = gen_summary_transfer("mubank", "attacker", "mu", mu_coin_amount)

    extra_constraints = [
        lambda s: s.get(amount) == s.get("arg_0"),
        # _adjusted_amount = (amount / (10 ** (18 - _decimals)));
        lambda s: s.get(_adjusted_amount) == s.get("arg_0") / (10**12),
        # (uint112 reserve0, uint112 reserve1) = Pair(pair_).getReserves(); //MU/USDC.e TJ LP
        lambda s: s.get(reserve0) == s.get("old_usdce.balanceOf(pair)"),
        lambda s: s.get(reserve1) == s.get("old_mu.balanceOf(pair)"),
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


def gen_Discover_swap_ethpledge_attacker_usdt_disc():
    # require(usdt.balanceOf(msg.sender)>=amount,"USDT balance is low");
    # usdt.transferFrom(msg.sender, address(this), amount);
    # uint256 __swapprice = getprice();
    # uint256 curTAmount22 = (amount * 10 ** 18) / __swapprice;
    # bool y2 = other.balanceOf(address(this)) >= curTAmount22;
    # require(y2, "Token balance is low.");
    # other.transfer(msg.sender, curTAmount22);
    old_bal_ethpledge = "old_disc.balanceOf(ethpledge)"
    old_usdt_bal_pair = "old_usdt.balanceOf(pair)"
    old_disc_bal_pair = "old_disc.balanceOf(pair)"
    
    extra_constraints = [
        lambda s: s.get(old_bal_ethpledge) > s.get("curTAmount22"),
        lambda s: s.get("curTAmount22") == s.get("arg_0") * s.get(old_disc_bal_pair) / s.get(old_usdt_bal_pair)
    ]
    return gen_summary_ratioswap("ethpledge", "attacker", "attacker", "usdt", "disc", "arg_0", "arg_1", "pair") + \
        extra_constraints


def gen_AES_swap_pair_attacker_usdt_aes():
    uniswap_constraints = gen_summary_uniswap(
        "pair", "attacker", "attacker", "usdt", "aes", "arg_0", "arg_1", percent_in_tokenOut=0.9, percent_out_tokenOut=0.93
    )
    extra_constraints = [
        lambda s: s.get("new_aes.swapFeeTotal") == s.get("old_aes.swapFeeTotal") + s.get("arg_1") * 0.01
    ]
    return [*uniswap_constraints, *extra_constraints]


def gen_AES_swap_pair_attacker_aes_usdt():
    uniswap_constraints = gen_summary_uniswap(
        "pair",
        "attacker",
        "attacker",
        "aes",
        "usdt",
        "arg_0",
        "arg_1",
        amtOutRatio=0.9,
        percent_in_tokenIn=0.97,
        percent_out_tokenIn=1,
    )
    extra_constraints = [
        lambda s: s.get("new_aes.swapFeeTotal") == s.get("old_aes.swapFeeTotal") + s.get("arg_0") * 0.01
    ]
    return [*uniswap_constraints, *extra_constraints]


def gen_AES_burn_aes_pair():
    burn_amount = "burn_amount"
    burn_summary = gen_summary_transfer("pair", DEAD, "aes", burn_amount)
    extra_constraints = [
        lambda s: s.get(burn_amount) == s.get("old_aes.swapFeeTotal") * 6,
        lambda s: s.get("new_aes.swapFeeTotal") == 0,
        lambda s: s.get("new_aes.balanceOf(pair)") >= 1 / SCALE,
    ]
    return [*burn_summary, *extra_constraints]


def gen_SGZ_addliquidity_sgz_pair_sgz_usdt():
    transfer_summary0 = gen_summary_transfer("sgz", "pair", "sgz", "old_sgz.balanceOf(sgz)")
    transfer_summary1 = gen_summary_transfer("sgz", "pair", "usdt", "old_usdt.balanceOf(sgz)")
    return [*transfer_summary0, *transfer_summary1]


def gen_SGZ_swap_pair_sgz_sgz_usdt():
    # uint256 allAmount = balanceOf(address(this));
    # uint256 canswap = allAmount.div(6).mul(5);
    # uint256 otherAmount = allAmount.sub(canswap);
    # swapTokensForOther(canswap);
    # uint256 ethBalance = usdt.balanceOf(address(this));
    # Never trigged.
    # if (ethBalance.mul(otherAmount) > 10 ** 34) {
    #     addLiquidityUsdt(ethBalance, otherAmount);
    # }
    old_balIn_pair = "old_sgz.balanceOf(pair)"
    old_balOut_pair = "old_usdt.balanceOf(pair)"
    old_bal_sgz = "old_sgz.balanceOf(sgz)"
    allAmount = "allAmount"
    canswap = "canswap"
    amtOut = "amtOut"
    constraints = [
        lambda s: s.get(allAmount) == s.get(old_bal_sgz),
        lambda s: s.get(canswap) == s.get(old_bal_sgz) / 6 * 5,
        *gen_summary_uniswap("pair", "sgz", "sgz", "sgz", "usdt", canswap, amtOut),
        *gen_summary_getAmountsOut(canswap, amtOut, old_balIn_pair, old_balOut_pair),
    ]
    return constraints


def gen_RADTDAO_burn_radt_pair():
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


def gen_Zoompro_addliquidity_controller_pair_fusdt_fusdt():
    return gen_summary_transfer("controller", "pair", "fusdt", "old_fusdt.balanceOf(controller)")


def gen_Zoompro_swap_trader_attacker_usdt_zoom():
    return [
        *gen_summary_transfer("attacker", "trader", "usdt", "arg_0"),
        *gen_summary_uniswap("pair", "trader", "attacker", "fusdt", "zoom", "arg_0", "arg_1"),
    ]


def gen_Zoompro_swap_trader_attacker_zoom_usdt():
    usdtOut = "amountOut"
    return [
        *gen_summary_uniswap("pair", "attacker", "trader", "zoom", "fusdt", "arg_0", "arg_1"),
        *gen_summary_transfer("trader", "attacker", "usdt", usdtOut),
        *gen_summary_getAmountsOut("arg_0", usdtOut, "old_zoom.balanceOf(pair)", "old_fusdt.balanceOf(pair)"),
    ]


def gen_RES_addliquidity_resA_pair_resA_usdt():
    # if (_balances[address(this)] > _minAToB) {
    #     uint256 burnNumber = _balances[address(this)];
    #     _approve(address(this), router, _balances[address(this)]);
    #     UniswapV2Router(payable(router))
    #         .swapExactTokensForTokensSupportingFeeOnTransferTokens(
    #             _balances[address(this)],
    #             0,
    #             _pathAToB,
    #             owner(),
    #             block.timestamp
    #         );
    #     _burn(pair, burnNumber);
    #     UniswapV2Pair(pair).sync();
    # }
    pair = "pair"
    sender = "resA"
    receiver = "resA"
    tokenIn = "resA"
    tokenOut = "usdt"
    amtIn = "burnNumber"
    amtOut = "amtOut"

    old_bal_resA_resA = "old_resA.balanceOf(resA)"
    old_bal_pair_resA = "old_resA.balanceOf(pair)"
    old_bal_pair_usdt = "old_usdt.balanceOf(pair)"
    amtOutMax = "amtOutMax"

    s_out = gen_summary_transfer(pair, receiver, tokenOut, amtOut)

    invariants = [
        lambda s: s.get(amtIn) == s.get(old_bal_resA_resA),
        lambda s: s.get(amtOut) == s.get(amtOutMax),
        *gen_summary_getAmountsOut(amtIn, amtOutMax, old_bal_pair_resA, old_bal_pair_usdt),
    ]

    constraints = [
        *s_out,
        *invariants,
    ]
    return constraints


def gen_OneRing_getSharePrice(price: str):
    totalSupply = "vault._totalSupply"
    balanceWithInvested = "strategy._investedBalanceInUSD"
    underlyingUnit = 1e18
    return [
        lambda s: s.get(price) == underlyingUnit * s.get(f"old_{balanceWithInvested}") / s.get(f"old_{totalSupply}")
    ]


def gen_OneRing_deposit_vault_usdce_vault():
    attacker = "attacker"
    vault = "vault"
    strategy = "strategy"
    tokenIn = "usdce"
    tokenOut = "vault"
    amtIn = "arg_0"
    amtOut = "amtOut"

    totalSupply = "vault._totalSupply"
    balanceWithInvested = "strategy._investedBalanceInUSD"
    assetDelta = amtIn
    assetInUSD = "assetInUSD"

    sharePrice = "sharePrice"

    constraints = [
        *gen_summary_transfer(attacker, strategy, tokenIn, amtIn),
        lambda s: s.get(assetInUSD) == s.get(assetDelta) * 0.557 * 1e12,
        lambda s: s.get(f"new_{balanceWithInvested}")
        == s.get(f"old_{balanceWithInvested}") + s.get(assetInUSD) * 1.076,
        lambda s: s.get(amtOut) == s.get(assetInUSD) * 1e18 / s.get(sharePrice),
        *gen_OneRing_getSharePrice(sharePrice),
        *gen_summary_mint(attacker, tokenOut, amtOut),
        lambda s: s.get(f"new_{totalSupply}") == s.get(f"old_{totalSupply}") + s.get(amtOut),
    ]
    return constraints


def gen_OneRing_withdraw_vault_vault_usdce():
    attacker = "attacker"
    vault = "vault"
    strategy = "strategy"
    tokenIn = "vault"
    tokenOut = "usdce"
    amtIn = "arg_0"
    amtOut = "amtOut"

    totalSupply = "vault._totalSupply"
    balanceWithInvested = "strategy._investedBalanceInUSD"

    sharePrice = "sharePrice"
    _amountInUsd = "_amountInUsd"
    _minAmountInUsd = "_minAmountInUsd"
    _toWithdraw = "_toWithdraw"
    assetInUSD = "assetInUSD"

    constraints = [
        *gen_OneRing_getSharePrice(sharePrice),
        lambda s: s.get(_amountInUsd) == s.get(amtIn) * s.get(sharePrice) / 1e18,
        # 1e12 = 1e18 / usdce.decimals()
        lambda s: s.get(_minAmountInUsd) == s.get(_amountInUsd) * 98 / 100 / 1e12,
        # _withdraw body
        *gen_summary_burn(attacker, tokenIn, amtIn),
        lambda s: s.get(_toWithdraw)
        == s.get(f"old_{balanceWithInvested}") * s.get(amtIn) / s.get(f"old_{totalSupply}"),
        # withdrawToVault
        lambda s: s.get(assetInUSD) == s.get(_toWithdraw) / 0.557 / 1e12,
        lambda s: s.get(f"new_{balanceWithInvested}")
        == s.get(f"old_{balanceWithInvested}") - s.get(assetInUSD) * 1.076,
        lambda s: s.get(amtOut) == s.get(assetInUSD) * 0.99, # relaxation
        lambda s: s.get(amtOut) >= s.get(_minAmountInUsd),
        *gen_summary_transfer(strategy, attacker, tokenOut, amtOut),
    ]

    return constraints

# def gen_EGD_borrow_usdt_owner():
#     extra_constraints = [
#         lambda s: s.get
#     ]
#     return gen_summary_transfer("owner", "attacker", "usdt", "arg_0") + 

def gen_EGD_deposit_egdstaking_usdt_egdslp():
    pair = "pair"

    old_balIn_pair = "old_usdt.balanceOf(pair)"
    old_balOut_pair = "old_egd.balanceOf(pair)"

    attacker = "attacker"
    egdstaking = "egdstaking"
    usdt = "usdt"
    egd = "egd"

    amount = "arg_0"

    amountSub0 = "amountSub0"
    amountOut0 = "amountOut0"

    tempRate = "tempRate"
    old_rates = "old_egdstaking.user_rates"
    new_rates = "new_egdstaking.user_rates"

    old_claimTime = "old_egdstaking.user_claimTime"
    new_claimTime = "new_egdstaking.user_claimTime"

    constraints = [
        # Transfer
        *gen_summary_getAmountsOut(amountSub0, amountOut0, old_balIn_pair, old_balOut_pair),
        lambda s: s.get(amountSub0) == s.get(amount) * 70 / 100,
        # Give all amount USDT out.
        *gen_summary_burn(attacker, usdt, amount),
        # For pair
        *gen_summary_mint(pair, usdt, amountSub0),
        *gen_summary_burn(pair, egd, amountOut0),
        # For egdstaking
        *gen_summary_mint(egdstaking, egd, amountOut0),
        # Reward
        lambda s: s.get(tempRate) == 383,
        lambda s: s.get(new_rates) == s.get(amount) * s.get(tempRate) / 100000 / 86400,
        lambda s: s.get(new_claimTime) == s.get("old_block.timestamp"),
        lambda s: s.get("new_block.timestamp") == s.get("old_block.timestamp") + 54,

        # Utils to make those variables been initilized.
        lambda s: s.get(old_claimTime) >= 0,
        lambda s: s.get(old_rates) >= 0,
    ]

    return constraints


def gen_EGD_borrow_usdt_pair():
    extra_constraints = [
        lambda s: s.get("arg_0") < s.get("old_usdt.balanceOf(pair)")
    ]
    return gen_summary_transfer("pair", "attacker", "usdt", "arg_0") + extra_constraints


def gen_EGD_withdraw_egdstaking_egdslp_egd():
    old_balIn_pair = "old_usdt.balanceOf(pair)"
    old_balOut_pair = "old_egd.balanceOf(pair)"

    attacker = "attacker"
    egdstaking = "egdstaking"
    usdt = "usdt"
    egd = "egd"

    quota = "quota"
    rew = "rew"
    getEGDPrice = "getEGDPrice"

    rates = "old_egdstaking.user_rates"
    claimTime = "old_egdstaking.user_claimTime"

    constraints = [
        lambda s: s.get(quota) == (s.get("old_block.timestamp") - s.get(claimTime)) * s.get(rates),
        lambda s: s.get(old_balIn_pair) * 1e18 > s.get(old_balOut_pair),
        lambda s: s.get(rew) == s.get(quota) * 1e18 / s.get(getEGDPrice),
        lambda s: s.get(getEGDPrice) == s.get(old_balIn_pair) * 1e18 / s.get(old_balOut_pair),
        *gen_summary_transfer(egdstaking, attacker, egd, rew),
    ]

    return constraints

def gen_Haven_swap_pairhw_haven_haven_wbnb():
    amtIn = "old_haven.swapThreshold"
    amtOut = "amtOut"

    return gen_summary_uniswap("pairhw", "haven", "haven", "haven", "wbnb", amtIn, amtOut)

def gen_Haven_swap_pairbh_attacker_haven_busd():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pairbh", "attacker", "attacker", "haven", "busd", amtIn, amtOut, amtOutRatio=0.87 * 0.997, percent_in_tokenIn=0.87)

def gen_Haven_swap_pairbh_attacker_busd_haven():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pairbh", "attacker", "attacker", "busd", "haven", amtIn, amtOut, percent_in_tokenOut=0.87)

def gen_Haven_swap_pairhw_attacker_wbnb_haven():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pairhw", "attacker", "attacker", "wbnb", "haven", amtIn, amtOut, percent_in_tokenOut=0.87)

def gen_SwaposV2_swap_spair_attacker_weth_swapos():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("spair", "attacker", "attacker", "weth", "swapos", amtIn, amtOut, amtOutRatio=9.997)

def gen_SwaposV2_swap_spair_attacker_swapos_weth():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("spair", "attacker", "attacker", "swapos", "weth", amtIn, amtOut, amtOutRatio=9.997)

def gen_UN_swap_pair_attacker_busd_un():
    return gen_summary_uniswap("pair", "attacker", "attacker", "busd", "un", "arg_0", "arg_1",
                               percent_in_tokenOut=0.93) 

def gen_UN_swap_pair_attacker_un_busd():
    # super._transfer(from, to, amount - every * 95);
    return gen_summary_uniswap("pair", "attacker", "attacker", "un", "busd", "arg_0", "arg_1")
        # percent_in_tokenIn=0.905)

def gen_UN_burn_un_pair():
    burn_amount = "burnAmount"
    burn_amount1 = "burnAmount1"
    old_bal_attacker = f"old_un.balanceOf(attacker)"
    old_bal_pair = f"old_un.balanceOf(pair)"
    new_bal_pair = f"new_un.balanceOf(pair)"
    extra_constraints = [
        lambda s: s.get(f"new_un.balanceOf(pair)") == s.get(f"old_un.balanceOf(pair)") - s.get(burn_amount),
        lambda s: s.get(f"new_un.balanceOf(attacker)") == s.get(f"old_un.balanceOf(attacker)") - s.get(burn_amount1),
        lambda s: s.get("arg_0") == s.get(burn_amount) * 3,
        lambda s: s.get("arg_0") == s.get(burn_amount1) * 10,
        lambda s: s.get("arg_0") < s.get(old_bal_attacker),
        lambda s: s.get("arg_0") < s.get(old_bal_pair),
        lambda s: s.get(new_bal_pair) >= 1 / SCALE,
    ]
    return extra_constraints

def gen_Axioma_swap_axiomaPresale_attacker_wbnb_axt():
    amtIn = "arg_0"
    amtOut = "arg_1"
    tokenAmount = "tokenAmount"
    taxAmount = "taxAmount"
    transferAmount = "transferAmount"
    old_balOut_axiomaPresale = "old_axt.balanceOf(axiomaPresale)"
    new_balOut_axiomaPresale = "new_axt.balanceOf(axiomaPresale)"
    old_balOut_owner = "old_axt.balanceOf(owner)"
    new_balOut_owner = "new_axt.balanceOf(owner)"
    old_balOut_attacker = "old_axt.balanceOf(attacker)"
    new_balOut_attacker = "new_axt.balanceOf(attacker)"
    

    transfer_summary0 = gen_summary_transfer("attacker", "owner", "wbnb", amtIn)
    transfer_summary1 = [
        # Transfer token
        lambda s: s.get(new_balOut_axiomaPresale) == s.get(old_balOut_axiomaPresale) - 
            (s.get(taxAmount) + s.get(transferAmount)),
        lambda s: s.get(new_balOut_owner) == s.get(old_balOut_owner) + s.get(taxAmount),
        lambda s: s.get(new_balOut_attacker) == s.get(old_balOut_attacker) + s.get(transferAmount),
    ]
    
    extra_constraints = [
        # uint256 tokenAmount = bnbAmountToBuy.mul(rate).div(10**9);
        lambda s: s.get("arg_0") * 300 == s.get(tokenAmount),
        # uint256 taxAmount = tokenAmount.mul(buyTax).div(100);
        lambda s: s.get(taxAmount) == s.get(tokenAmount) * 3 / 100,
        # (bool sent) = token.transfer(msg.sender, tokenAmount.sub(taxAmount));
        lambda s: s.get(transferAmount) == s.get(tokenAmount) - s.get(taxAmount)
    ]
    
    return [*transfer_summary0, *transfer_summary1, *extra_constraints]

def gen_Axioma_swap_pair_attacker_axt_wbnb():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "axt", "wbnb", amtIn, amtOut, percent_in_tokenOut=0.9, amtOutRatio=0.9)

def gen_Safemoon_swap_pair_attacker_weth_safemoon():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "weth", "safemoon", amtIn, amtOut, outMax=True)

def gen_Safemoon_swap_pair_attacker_safemoon_weth():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "safemoon", "weth", amtIn, amtOut, outMax=True)

def gen_Safemoon_burn_safemoon_pair():
    burn_amount = "burnAmount"
    burn_summary = gen_summary_transfer("pair", DEAD, "safemoon", burn_amount, percent_out=1)
    old_bal_attacker = f"old_safemoon.balanceOf(attacker)"
    old_bal_pair = f"old_safemoon.balanceOf(pair)"
    new_bal_pair = f"new_safemoon.balanceOf(pair)"
    extra_constraints = [
        lambda s: s.get("arg_0") == s.get(burn_amount),
        lambda s: s.get("arg_0") < s.get(old_bal_pair),
        lambda s: s.get(new_bal_pair) >= 1 / SCALE,
    ]
    return [*burn_summary, *extra_constraints]


def gen_Bamboo_burn_bamboo_pair():
    burn_amount = "burnAmount"
    burn_summary = gen_summary_transfer("pair", DEAD, "bamboo", burn_amount, percent_out=1)
    old_bal_attacker = f"old_bamboo.balanceOf(attacker)"
    old_bal_pair = f"old_bamboo.balanceOf(pair)"
    new_bal_pair = f"new_bamboo.balanceOf(pair)"
    extra_constraints = [
        lambda s: s.get("arg_0") > 10000 / 1e18,
        lambda s: s.get(old_bal_pair) > s.get("arg_0") * 101 / 100,
        # if (!isMarketPair[sender]) updatePool(amount);
        #  ...  uint256 fA = amount / 100;
        lambda s: s.get("arg_0") == s.get(burn_amount) * 50,
        lambda s: s.get("arg_0") < s.get(old_bal_attacker) ,
        lambda s: s.get(new_bal_pair) >= 1 / SCALE,
    ]
    return [*burn_summary, *extra_constraints]

def gen_Bamboo_swap_pair_attacker_wbnb_bamboo():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "wbnb", "bamboo", amtIn, amtOut)


def gen_Bamboo_swap_pair_attacker_bamboo_wbnb():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "bamboo", "wbnb", amtIn, amtOut, 
                            fee=3)

def gen_LUSD_swap_loan_attacker_btcb_lusd():
    amtIn = "arg_0"
    # amtOut = "arg_1"
    usdtAmout = "usdtAmout"
    old_btcb_bal_attacker = f"old_btcb.balanceOf(attacker)"
    new_btcb_bal_attacker = f"new_btcb.balanceOf(attacker)"
    old_btcb_bal_loan = f"old_btcb.balanceOf(loan)"
    new_btcb_bal_loan = f"new_btcb.balanceOf(loan)"
    old_lusd_bal_attacker = f"old_lusd.balanceOf(attacker)"
    new_lusd_bal_attacker = f"new_lusd.balanceOf(attacker)"
    constraints = [
        lambda s: s.get(new_btcb_bal_attacker) == s.get(old_btcb_bal_attacker) - s.get(amtIn),
        lambda s: s.get(new_btcb_bal_loan) == s.get(old_btcb_bal_loan) + s.get(amtIn),
        lambda s: (s.get(amtIn) > 0),
        # uint256 usdtAmount = router.getAmountsOut(supplyAmount, path)[1];
        *gen_summary_getAmountsOut(amtIn, usdtAmout, "old_btcb.balanceOf(pairub)", "old_usdt.balanceOf(pairub)"), 
        # payoutAmount: (usdtAmount * info[supplyToken].supplyRatio) / 1e4,
        # LUSD.mint(msg.sender, order.payoutAmount);
        lambda s: s.get(new_lusd_bal_attacker) == s.get(old_lusd_bal_attacker) + s.get(usdtAmout) / 2,
    ]
    # fmt: on
    return constraints

def gen_LUSD_withdraw_lusdpool_lusd_usdt():
    amtIn = "arg_0"
    burn_amount = "burnAmount"
    burn_summary = gen_summary_transfer("attacker", DEAD, "lusd", amtIn, percent_out=1)
    burn_summary2 = gen_summary_transfer("lusdpool", "attacker", "usdt", burn_amount, percent_out=1)
    
    extra_constraints = [
        lambda s: s.get("arg_0") * 97 / 100 == s.get(burn_amount),
    ]

    return [*burn_summary, *burn_summary2, *extra_constraints]

def gen_LW_swap_pair_attacker_usdt_lw():
    amtIn = "arg_0"
    amtOut = "arg_1"
    #  uint256 fees = amount.mul(getBuyFee()).div(10000);
    return gen_summary_uniswap("pair", "attacker", "attacker", "usdt", "lw", amtIn, amtOut, percent_in_tokenOut=0.9)
    
def gen_LW_swap_pair_attacker_lw_usdt():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "lw", "usdt", amtIn, amtOut, amtOutRatio=0.9)

def gen_LW_burn_lw_pair():
    burn_amount = "burnAmount"
    per_burnOutMax = "perburnOutMax"
    swaptodead_amount = "swaptoDeadAmount"
    tokenprice = "tokenPrice"
    burn_summary = gen_summary_transfer("pair", DEAD, "lw", burn_amount, percent_out=1)
    old_usdt_bal_attacker = f"old_usdt.balanceOf(attacker)"
    old_lw_bal_attacker = f"old_lw.balanceOf(attacker)"
    old_usdt_bal_pair = f"old_usdt.balanceOf(pair)"
    old_lw_bal_pair = f"old_lw.balanceOf(pair)"
    new_lw_bal_pair = f"new_lw.balanceOf(pair)"
    new_usdt_bal_pair = f"new_usdt.balanceOf(pair)"
    
    extra_constraints = [
        lambda s: s.get(tokenprice) == s.get(old_usdt_bal_pair) / s.get(old_lw_bal_pair),
        # if(2500e18<price && _startTimeForSwap +72*60*60 <block.timestamp   ){
        #             thanPrice +=1; 
        lambda s: s.get("arg_0") > (2500) / s.get(tokenprice),
        ## remove this: lambda s: s.get("arg_0") < 1000,

        # IERC20(_token).transferFrom(_marketAddr,address(this),3000e18);
        lambda s: s.get(swaptodead_amount) == 3000, 
        lambda s: s.get(new_usdt_bal_pair) == s.get(old_usdt_bal_pair) + s.get(swaptodead_amount) * 40,
        # swapTokensForDead(3000e18);    
        # Note: Although burn for 40 times, the amount of burned tokens decreases as loop executes.
        # So we approximate the amount of total burn by 20 * "the amount of burned tokens for the first time"
        lambda s: s.get(burn_amount) == s.get(per_burnOutMax) * 20, 
        *gen_summary_getAmountsOut(swaptodead_amount, per_burnOutMax, old_usdt_bal_pair, old_lw_bal_pair),
        
        lambda s: s.get("arg_0") < s.get(old_lw_bal_attacker) / 2, # leave room for fees
        lambda s: s.get(new_lw_bal_pair) >= 1 / SCALE,
    ]
    return [*burn_summary, *extra_constraints]


def gen_GPU_swap_pair_attacker_busd_gpu():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "busd", "gpu", amtIn, amtOut)

def gen_GPU_mint_gpu_attacker():
    old_gpu_bal_attacker = f"old_gpu.balanceOf(attacker)"
    extra_constraints = [
        lambda s: s.get("arg_0") < s.get(old_gpu_bal_attacker)
    ]
    return gen_summary_mint("attacker", "gpu", "arg_0") + extra_constraints

def gen_NeverFall_deposit_neverFall_usdt_neverFall():
    # addLiquidity(initSupply, amountU * buyAddLiqFee / 100);
    old_usdt_bal_attacker = f"old_usdt.balanceOf(attacker)"
    old_usdt_bal_pair = f"old_usdt.balanceOf(pair)"
    old_neverFall_bal_pair = f"old_neverFall.balanceOf(pair)"
    transfer_summary = gen_summary_transfer("attacker", "pair", "usdt", "arg_0", percent_in=0.98)

    extra_constraints = [
        lambda s: s.get("initSupply") ==  99900000000e12,
        lambda s: s.get(f"new_neverFall.balanceOf(attacker)") == s.get(f"old_neverFall.balanceOf(attacker)") + s.get("neverFallAmount") * 0.823,
        lambda s: s.get(f"new_neverFall.balanceOf(pair)") == s.get(f"old_neverFall.balanceOf(pair)") + s.get("neverFallAmount") * 0.823,
        lambda s: s.get("arg_0") < s.get(old_usdt_bal_attacker),
        lambda s: s.get("neverFallAmount") == (s.get("arg_0") * s.get(old_neverFall_bal_pair)) / s.get(old_usdt_bal_pair),
    ]
    return [*transfer_summary, *extra_constraints]

def gen_NeverFall_withdraw_neverFall_neverFall_usdt():
    old_usdt_bal_pair = f"old_usdt.balanceOf(pair)"
    old_neverFall_bal_pair = f"old_neverFall.balanceOf(pair)"
    old_neverFall_bal_attacker = f"old_neverFall.balanceOf(attacker)"

    transfer_summary0 = gen_summary_transfer("attacker", "pair", "neverFall", "arg_0")
    transfer_summary1 = gen_summary_transfer("pair", "attacker", "usdt", "usdtAmount")

    extra_constraints = [
        lambda s: s.get("arg_0") < s.get(old_neverFall_bal_pair),
        lambda s: s.get("arg_0") < s.get(old_neverFall_bal_attacker),
        lambda s: s.get("usdtAmount") == (s.get("arg_0") * s.get(old_usdt_bal_pair) * 0.85) / s.get(old_neverFall_bal_pair)
    ]
    return [*transfer_summary0, *transfer_summary1, *extra_constraints]

def gen_NeverFall_swap_pair_attacker_usdt_neverFall():
    amtOutMax = "amtOutMax"
    s_in = gen_summary_transfer("attacker", "pair", "usdt", "arg_0")
    s_out = gen_summary_transfer("pair", "owner", "neverFall", "arg_1")

    # Generate Invariants
    old_balIn_pair = f"old_usdt.balanceOf(pair)"
    old_balOut_pair = f"old_neverFall.balanceOf(pair)"
    invariants = [
        lambda s: s.get("arg_1") < s.get(amtOutMax),
        *gen_summary_getAmountsOut("arg_0", amtOutMax, old_balIn_pair, old_balOut_pair),
    ]

    return [*s_in, *s_out, *invariants]

def gen_Hackathon_burn_hackathon_pair():
    burn_amount = "burnAmount"
    burn_summary = gen_summary_transfer(DEAD, "attacker", "hackathon", burn_amount, percent_out=1)
    old_bal_attacker = f"old_hackathon.balanceOf(attacker)"
    old_bal_pair = f"old_hackathon.balanceOf(pair)"
    new_bal_pair = f"new_hackathon.balanceOf(pair)"
    extra_constraints = [
        lambda s: s.get("arg_0") ==  s.get(burn_amount),
        lambda s: s.get("arg_0") <= s.get(old_bal_attacker),
        lambda s: s.get(new_bal_pair) >= 1 / SCALE,
    ]
    return [*burn_summary, *extra_constraints]

def gen_XAI_swap_pair_attacker_wbnb_xai():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "wbnb", "xai", amtIn, amtOut) + [lambda s: s.get("arg_0") == 3000]


def gen_XAI_swap_pair_attacker_xai_wbnb():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "xai", "wbnb", amtIn, amtOut, amtOutRatio=0.9999691263904297)

def gen_XAI_burn_xai_pair():
    old_bal_pair = f"old_xai.balanceOf(pair)"
    new_bal_pair = f"new_xai.balanceOf(pair)"
    old_bal_attacker = f"old_xai.balanceOf(attacker)"
    new_bal_attacker = f"new_xai.balanceOf(attacker)"
    extra_constraints = [
        lambda s: s.get(new_bal_pair) ==  s.get(old_bal_pair) * s.get("arg_0") * 30 / (37 * (s.get(old_bal_attacker) + s.get(old_bal_pair))), 
        lambda s: s.get(new_bal_attacker) ==  s.get(old_bal_attacker) * s.get("arg_0") / (s.get(old_bal_attacker) + s.get(old_bal_pair)), 
        lambda s: s.get("arg_0") > 0,
        lambda s: s.get("arg_0") == 10000 / SCALE,
    ]
    return [*extra_constraints]

def gen_XAI_payback_wbnb_owner():
    extra_constraints = [
        lambda s: s.get("alias_" + "payback_wbnb_owner") <= s.get("arg_0"),
    ]
    constraints = gen_summary_transfer("attacker", "owner", "wbnb", "arg_0")
    return [*constraints, *extra_constraints]

def gen_HCT_swap_pair_attacker_wbnb_hct():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "wbnb", "hct", amtIn, amtOut, amtOutRatio=0.9)

def gen_HCT_swap_pair_attacker_hct_wbnb():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "hct", "wbnb", amtIn, amtOut, amtOutRatio=0.9)

def gen_HCT_burn_hct_pair():
    old_bal_pair = f"old_hct.balanceOf(pair)"
    new_bal_pair = f"new_hct.balanceOf(pair)"
    old_bal_attacker = f"old_hct.balanceOf(attacker)"
    new_bal_attacker = f"new_hct.balanceOf(attacker)"
    extra_constraints = [
        lambda s: s.get(new_bal_pair) > s.get(old_bal_pair) * s.get("arg_0") / (s.get(old_bal_attacker) + s.get(old_bal_pair)) - 1,
        lambda s: s.get(new_bal_pair) <=  s.get(old_bal_pair) * s.get("arg_0") / (s.get(old_bal_attacker) + s.get(old_bal_pair)), 
        lambda s: s.get(new_bal_attacker) ==  s.get(old_bal_attacker) * s.get("arg_0") / (s.get(old_bal_attacker) + s.get(old_bal_pair)), 
        lambda s: s.get("arg_0") > 0,
        lambda s: s.get("arg_0") == 10000 / SCALE,
    ]
    return [*extra_constraints]

def gen_CFC_swap_pair_attacker_safe_cfc():
    amtIn = "arg_0"
    amtOut = "arg_1"
    return gen_summary_uniswap("pair", "attacker", "attacker", "safe", "cfc", amtIn, amtOut, percent_in_tokenOut=0.95)

def gen_CFC_burn_cfc_pair():
    burn_amount = "burnAmount"
    burn_summary = gen_summary_transfer("pair", DEAD, "cfc", burn_amount, percent_out=1)
    old_bal_attacker = f"old_cfc.balanceOf(attacker)"
    old_bal_pair = f"old_cfc.balanceOf(pair)"
    old_bal_usdt_pair = f"old_usdt.balanceOf(pair)"
    
    new_bal_pair = f"new_cfc.balanceOf(pair)"
    extra_constraints = [
        lambda s: s.get("arg_0") > 10000 / 1e18,
        lambda s: s.get("arg_0") * 1.5 <= s.get(old_bal_pair),
        # function sync() private  {
        # if( _tOwned[uniswapV2Pair]>sellAmount && _tOwned[address(0xdead)] < _tTotal - minSwap ){
        lambda s: s.get(old_bal_pair) - s.get("arg_0") * 0.9 >= s.get(old_bal_usdt_pair), 
        # if (!isMarketPair[sender]) updatePool(amount);
        #  ...  uint256 fA = amount / 100;
        lambda s: s.get("arg_0") * 1.3 == s.get(burn_amount),
        lambda s: s.get("arg_0") < s.get(old_bal_attacker) ,
        lambda s: s.get(new_bal_pair) >= 1 / SCALE,
    ]
    return [*burn_summary, *extra_constraints]


def gen_SellToken_borrow_wbnb_owner():
    extra_constraints = [
        lambda s: s.get("arg_0") == 428,
    ]
    return gen_summary_transfer("owner", "attacker", "wbnb", "arg_0") + extra_constraints

def gen_SellToken_deposit_srouter_wbnb_sellc():
    extra_constraints = [
        # uint tos=getToken2Price(coin,bnbOrUsdt,mkt.balanceOf(coin))/10;
        *gen_summary_getAmountsOut("mkt_balanceOf(coin)", "tos", "old_sellc.balanceOf(pair)","old_wbnb.balanceOf(pair)", suffix="1"),
        # mkt.balanceOf(coin) == 15917150.0
        lambda s: s.get("mkt_balanceOf(coin)") == 15917150.0,
        #  require(Short[addr][coin].bnb+bnb <= tos);
        lambda s: s.get("arg_0") <= s.get("tos") / 10,
        *gen_summary_getAmountsOut("usdtAmt", "new_tokenPrice", "old_wbnb.balanceOf(pair)", "old_sellc.balanceOf(pair)"),
        lambda s: s.get("usdtAmt") == 1,
        lambda s: s.get("arg_0") > 0,
    ]
    transfer_summary0 = gen_summary_transfer("attacker", "srouter", "wbnb", "arg_0")
    
    return [*transfer_summary0, *extra_constraints]

def gen_SellToken_withdraw_srouter_sellc_wbnb():
    extra_constraints = [
        *gen_summary_getAmountsOut("usdtAmt", "new_tokenPrice", "old_wbnb.balanceOf(pair)", "old_sellc.balanceOf(pair)"),
        lambda s: s.get("usdtAmt") == 1,
        # lambda s: s.get("withdraw_usdt") < 20,
        lambda s: s.get("withdraw_usdt") == s.get("new_tokenPrice") / s.get("old_tokenPrice") * s.get("old_wbnb.balanceOf(srouter)")
    ]
    transfer_summary0 = gen_summary_transfer("pair", "attacker", "wbnb", "withdraw_usdt")
    
    return [*transfer_summary0, *extra_constraints]

def gen_SellToken_payback_wbnb_owner():
    extra_constraints = [
        lambda s: s.get("old_wbnb.balanceOf(attacker)") >= s.get("alias_" + "payback_wbnb_owner") * 1001 / 1000,
        lambda s: s.get("alias_" + "payback_wbnb_owner") <= s.get("arg_0"),
    ]
    constraints = gen_summary_transfer("attacker", "owner", "wbnb", "arg_0")
    return [*constraints, *extra_constraints]
    # return gen_summary_payback("attacker", "owner", "wbnb", "alias_" + "payback_wbnb_owner", "arg_0")

hack_constraints: Dict[str, Dict[str, ACTION_CONSTR]] = {
    "NMB": {
        "deposit_gslp_gnimb_gslp": gen_NMB_deposit_gslp_gnimb_gslp(),
        "withdraw_gslp_gslp_gnimb": gen_NMB_withdraw_gslp_gslp_gnimb(),
    },
    "BXH": {
        "deposit_bxhstaking_bxh_bxhslp": gen_BXH_deposit_bxhstaking_bxh_bxhslp(),
        "withdraw_bxhstaking_bxhslp_usdt": gen_BXH_withdraw_bxhstaking_bxhslp_usdt(),
    },
    "BGLD": {
        "swap_pair_attacker_wbnb_bgld": gen_BGLD_swap_pair_attacker_wbnb_bgld(),
        "swap_pair_attacker_bgld_wbnb": gen_BGLD_swap_pair_attacker_bgld_wbnb(),
        "burn_bgld_pair": gen_BGLD_burn_bgld_pair(),
    },
    "MUMUG": {
        "swap_mubank_attacker_usdce_mu": gen_MUMUG_swap_mubank_attacker_usdce_mu(),
    },
    "Discover": {
        "swap_ethpledge_attacker_usdt_disc": gen_Discover_swap_ethpledge_attacker_usdt_disc(),
    },
    "AES": {
        "swap_pair_attacker_usdt_aes": gen_AES_swap_pair_attacker_usdt_aes(),
        "swap_pair_attacker_aes_usdt": gen_AES_swap_pair_attacker_aes_usdt(),
        "burn_aes_pair": gen_AES_burn_aes_pair(),
    },
    "SGZ": {
        "addliquidity_sgz_pair_sgz_usdt": gen_SGZ_addliquidity_sgz_pair_sgz_usdt(),
        "swap_pair_sgz_sgz_usdt": gen_SGZ_swap_pair_sgz_sgz_usdt(),
    },
    "RADTDAO": {
        "burn_radt_pair": gen_RADTDAO_burn_radt_pair(),
    },
    "Zoompro": {
        "addliquidity_controller_pair_fusdt_fusdt": gen_Zoompro_addliquidity_controller_pair_fusdt_fusdt(),
        "swap_trader_attacker_usdt_zoom": gen_Zoompro_swap_trader_attacker_usdt_zoom(),
        "swap_trader_attacker_zoom_usdt": gen_Zoompro_swap_trader_attacker_zoom_usdt(),
    },
    "RES": {
        "addliquidity_resA_pair_resA_usdt": gen_RES_addliquidity_resA_pair_resA_usdt(),
    },
    "OneRing": {
        "deposit_vault_usdce_vault": gen_OneRing_deposit_vault_usdce_vault(),
        "withdraw_vault_vault_usdce": gen_OneRing_withdraw_vault_vault_usdce(),
        # "payback_wbnb_owner": gen_summary_payback("attacker", "owner", "usdce", "arg_x0", "arg_0", fee=0),
    },
    "EGD": {
        # "borrow_usdt_owner": gen_EGD_borrow_usdt_owner(),
        "borrow_usdt_pair": gen_EGD_borrow_usdt_pair(),
        "deposit_egdstaking_usdt_egdslp": gen_EGD_deposit_egdstaking_usdt_egdslp(),
        "withdraw_egdstaking_egdslp_egd": gen_EGD_withdraw_egdstaking_egdslp_egd(),
    },
    "Haven": {
        "swap_pairhw_haven_haven_wbnb": gen_Haven_swap_pairhw_haven_haven_wbnb(),
        "swap_pairbh_attacker_haven_busd": gen_Haven_swap_pairbh_attacker_haven_busd(),
        "swap_pairbh_attacker_busd_haven": gen_Haven_swap_pairbh_attacker_busd_haven(),
        "swap_pairhw_attacker_wbnb_haven": gen_Haven_swap_pairhw_attacker_wbnb_haven(),
    },
    "SwaposV2": {
        "swap_spair_attacker_weth_swapos": gen_SwaposV2_swap_spair_attacker_weth_swapos(),
        "swap_spair_attacker_swapos_weth": gen_SwaposV2_swap_spair_attacker_swapos_weth(),
    },
    "UN" : {
        "swap_pair_attacker_busd_un": gen_UN_swap_pair_attacker_busd_un(),
        "burn_un_pair": gen_UN_burn_un_pair(),
        "swap_pair_attacker_un_busd": gen_UN_swap_pair_attacker_un_busd(),
    },
    "Axioma": {
        "swap_axiomaPresale_attacker_wbnb_axt": gen_Axioma_swap_axiomaPresale_attacker_wbnb_axt(),
        "swap_pair_attacker_axt_wbnb": gen_Axioma_swap_pair_attacker_axt_wbnb(),
    },
    "Safemoon": {
        "swap_pair_attacker_weth_safemoon": gen_Safemoon_swap_pair_attacker_weth_safemoon(),
        "burn_safemoon_pair": gen_Safemoon_burn_safemoon_pair(),
        "swap_pair_attacker_safemoon_weth": gen_Safemoon_swap_pair_attacker_safemoon_weth(),
    },
    "Bamboo": {
        "swap_pair_attacker_wbnb_bamboo": gen_Bamboo_swap_pair_attacker_wbnb_bamboo(),
        "burn_bamboo_pair": gen_Bamboo_burn_bamboo_pair(),
        "swap_pair_attacker_bamboo_wbnb": gen_Bamboo_swap_pair_attacker_bamboo_wbnb(),
    },
    "LUSD": {
        "swap_loan_attacker_btcb_lusd": gen_LUSD_swap_loan_attacker_btcb_lusd(),
        "withdraw_lusdpool_lusd_usdt": gen_LUSD_withdraw_lusdpool_lusd_usdt(),
    },
    "LW": {
        "swap_pair_attacker_usdt_lw": gen_LW_swap_pair_attacker_usdt_lw(),
        "burn_lw_pair": gen_LW_burn_lw_pair(),
        "swap_pair_attacker_lw_usdt": gen_LW_swap_pair_attacker_lw_usdt(),
    },
    "GPU": {
        "swap_pair_attacker_busd_gpu": gen_GPU_swap_pair_attacker_busd_gpu(),
        "mint_gpu_attacker": gen_GPU_mint_gpu_attacker(),
    },
    "NeverFall": {
        "deposit_neverFall_usdt_neverFall": gen_NeverFall_deposit_neverFall_usdt_neverFall(),
        "swap_pair_attacker_usdt_neverFall": gen_NeverFall_swap_pair_attacker_usdt_neverFall(),
        "withdraw_neverFall_neverFall_usdt": gen_NeverFall_withdraw_neverFall_neverFall_usdt(),
    },
    "Hackathon": {
        "burn_hackathon_pair": gen_Hackathon_burn_hackathon_pair(),        
    },
    "XAI": {
        "swap_pair_attacker_wbnb_xai": gen_XAI_swap_pair_attacker_wbnb_xai(),
        "burn_xai_pair": gen_XAI_burn_xai_pair(),
        "swap_pair_attacker_xai_wbnb": gen_XAI_swap_pair_attacker_xai_wbnb(),
        "payback_wbnb_owner": gen_XAI_payback_wbnb_owner(),
    },
    "CFC": {
        "swap_pair_attacker_safe_cfc": gen_CFC_swap_pair_attacker_safe_cfc(),
        "burn_cfc_pair": gen_CFC_burn_cfc_pair(),
    },
    "HCT": {
        "swap_pair_attacker_wbnb_hct": gen_HCT_swap_pair_attacker_wbnb_hct(),
        "burn_hct_pair": gen_HCT_burn_hct_pair(),
        "swap_pair_attacker_hct_wbnb": gen_HCT_swap_pair_attacker_hct_wbnb(),
    },
    "SellToken": {
        "borrow_wbnb_owner": gen_SellToken_borrow_wbnb_owner(),
        "deposit_srouter_wbnb_sellc": gen_SellToken_deposit_srouter_wbnb_sellc(),
        "withdraw_srouter_sellc_wbnb": gen_SellToken_withdraw_srouter_sellc_wbnb(),
        "payback_wbnb_owner": gen_SellToken_payback_wbnb_owner(),
    }    
}


def gen_ShadowFi_refinement():
    trans_limit = 1e8 * 1e9 / 1000 / SCALE
    return [
        {
            "burn_sdf_pair": [
                lambda s: s.get("old_sdf.balanceOf(pair)") - s.get("new_sdf.balanceOf(pair)") <= trans_limit,
            ]
        },
        {
            "swap_pair_attacker_sdf_wbnb": [
                lambda s: s.get("old_sdf.balanceOf(attacker)") - s.get("new_sdf.balanceOf(attacker)") <= trans_limit,
            ]
        },
    ]


def gen_BXH_refinement():
    return []


def gen_EGD_refinement():
    return [
        {
            "deposit_egdstaking_usdt_egdslp": [
                lambda s: s.get("arg_0") >= 100e18 / SCALE,
            ]
        },
        {
            "borrow_usdt_pair": [
                lambda s: s.get("arg_0") <= 516000e18 / SCALE,
            ]
        },
    ]


refine_constraints: Dict[str, List[Dict[str, List[LAMBDA_CONSTR]]]] = {
    "ShadowFi": gen_ShadowFi_refinement(),
    "BXH": gen_BXH_refinement(),
    "EGD": gen_EGD_refinement(),
}
