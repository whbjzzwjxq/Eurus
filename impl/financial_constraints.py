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
) -> ACTION_CONSTR:
    amtOutMax = "amtOutMax"
    s_in = gen_summary_transfer(sender, pair, tokenIn, amtIn, percent_in=percent_in_tokenIn, percent_out=percent_out_tokenIn)
    s_out = gen_summary_transfer(
        pair, receiver, tokenOut, amtOut, percent_in=percent_in_tokenOut, percent_out=percent_out_tokenOut
    )

    # Generate Invariants
    old_balIn_pair = f"old_{tokenIn}.balanceOf({pair})"
    old_balOut_pair = f"old_{tokenOut}.balanceOf({pair})"
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
    return gen_summary_ratioswap("ethpledge", "attacker", "attacker", "usdt", "disc", "arg_0", "arg_1", "ethpledge")


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
        lambda s: s.get(amtOut) == s.get(assetInUSD),
        lambda s: s.get(amtOut) >= s.get(_minAmountInUsd),
        *gen_summary_transfer(strategy, attacker, tokenOut, amtOut),
    ]

    return constraints


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

def gen_UN_swap_pair_attacker_un_busd():
    extra_constraints = [
         lambda s: s.get("arg_0") * 80/100 < s.get("old_un.balanceOf(pair)"),
    ]
    return gen_summary_uniswap(
        "pair", "attacker", "attacker", "un", "busd", "arg_0", "arg_1", 
        percent_in_tokenIn=0.905,percent_out_tokenIn=1) + [*extra_constraints] 

def gen_UN_burn_un_pair():
    burn_amount = "burnAmount"
    burn_summary = gen_summary_transfer("pair", DEAD, "un", burn_amount, percent_out=1)
    burn_summary2 = gen_summary_transfer("attacker", DEAD, "un", burn_amount, percent_out=1)
    old_bal_attacker = f"old_un.balanceOf(attacker)"
    new_bal_pair = f"new_un.balanceOf(pair)"
    extra_constraints = [
        lambda s: s.get("arg_0") == s.get(burn_amount) * 100 / 7,
        lambda s: s.get("arg_0") < s.get(old_bal_attacker) * 90 / 100,
        lambda s: s.get(new_bal_pair) >= 1 / SCALE,
    ]
    return [*burn_summary, *burn_summary2, *extra_constraints]

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
    },
    "EGD": {
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
        "burn_un_pair": gen_UN_burn_un_pair(),
        "swap_pair_attacker_un_busd": gen_UN_swap_pair_attacker_un_busd(),
    },
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
