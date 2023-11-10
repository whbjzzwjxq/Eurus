# class SynthesizerByPattern:
#     def __init__(self, config: Config):
#         self.config = config
#         self.roles = self.config.roles
#         self.candidates: List[Sketch] = []
#         self.candidates_signs: Set[str] = set()
#         actions = [init_action_from_list(a, True) for a in self.config.groundtruth]
#         self.gt_sketch = Sketch(actions).symbolic_copy()

#         if self.config.pattern == "BuySell Manipulation":
#             self.gen_candidates_buysell()
#         elif self.config.pattern == "Price Discrepancy":
#             self.gen_candidates_pricediscrepancy()
#         elif self.config.pattern == "Token Burn":
#             self.gen_candidates_tokenburn()
#         elif self.config.pattern == "Liquidity Ratio Break":
#             self.gen_candidates_lrbreak()
#         else:
#             raise CornerCase(f"Unknown pattern: {self.config.pattern}!")

#         self.candidates: List[Sketch] = sorted(self.candidates, key=len)

#         # Remove all candidates after the ground-truth
#         gt_idx = -1
#         for idx, c in enumerate(self.candidates):
#             if len(c) != len(self.gt_sketch):
#                 continue
#             if c == self.gt_sketch:
#                 gt_idx = idx
#         if gt_idx == -1:
#             raise ValueError("Ground truth is not covered by the candidates!")
#         self.candidates = self.candidates[: gt_idx + 1]

#     def check_duplicated(self, sketch: Sketch) -> bool:
#         return str(sketch) in self.candidates_signs

#     def extend_candidates_from_template(
#         self,
#         template: List[AFLAction],
#         template_times: List[int],
#     ):
#         sketches: List[Sketch] = []
#         for times in itertools.product(*template_times):
#             actions = []
#             for i in range(len(template)):
#                 t = times[i]
#                 actions.extend([template[i]] * t)
#             # Rename parameters
#             sketch = Sketch(actions).symbolic_copy()
#             # Prune too long candidates
#             if len(sketch) > len(self.gt_sketch):
#                 continue
#             sketches.append(sketch)

#         for s in sketches:
#             if not s.check_implemented(self.roles):
#                 continue
#             if self.check_duplicated(s):
#                 continue
#             self.candidates.append(s)
#             self.candidates_signs.add(str(s))

#     def gen_candidates_buysell(self):
#         lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
#         assets = [k for k, v in self.roles.items() if v.is_asset]
#         stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
#         swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
#         defi_entrys = [k for k, v in self.roles.items() if v.is_defientry]
#         # timer = time.perf_counter()
#         # i = 0
#         # fmt: off
#         for (
#             lend_pool0, lend_pool1, asset0, asset1, swap_pair0, asset2, asset3, defi_entry, asset_hacked, swap_pair1, swap_pair2, stable_coin
#         ) in itertools.product(
#             lend_pools, lend_pools, assets, assets, swap_pairs, assets, assets, defi_entrys, assets, swap_pairs, swap_pairs, stable_coins
#         ):
#             template: List[AFLAction] = [
#                 Borrow(lend_pool0, asset0, "amt0"),
#                     Borrow(lend_pool1, asset1, "amt1"),
#                         Swap(swap_pair0, asset2, asset3, "amt2"),
#                         Transaction(defi_entry, asset_hacked, "amt3"),
#                         Swap(swap_pair0, asset3, asset2, "amt4"),
#                     Payback(lend_pool1, asset1, "amt5"),
#                     Swap(swap_pair1, asset_hacked, stable_coin, "amt6"),
#                     Swap(swap_pair2, stable_coin, asset0, "amt7"),
#                 Payback(lend_pool0, asset0, "amt8"),
#             ]
#         # fmt: on
#             template_times = [
#                 (0, 1),
#                 (0, 1),
#                 (0, 1),
#                 (1,),
#                 (0, 1),
#                 (0, 1),
#                 (0, 1),
#                 (0, 1),
#                 (0, 1),
#             ]

#             self.extend_candidates_from_template(template, template_times)

#             # print(f"Epoch {i} timecost: {time.perf_counter() - timer}")
#             # timer = time.perf_counter()
#             # i += 1

#     def gen_candidates_pricediscrepancy(self):
#         lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
#         assets = [k for k, v in self.roles.items() if v.is_asset]
#         stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
#         swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
#         oracles = [k for k, v in self.roles.items() if v.is_oracle]
#         # fmt: off
#         for (
#             lend_pool0, asset0, swap_pair0, asset1, oracle, swap_pair1, swap_pair2, stable_coin, swap_pair3
#         ) in itertools.product(
#             lend_pools, assets, swap_pairs, assets, oracles, swap_pairs, swap_pairs, stable_coins, swap_pairs
#         ):
#             template: List[AFLAction] = [
#                 Borrow(lend_pool0, asset0, "amt0"),
#                     Swap(swap_pair0, asset0, asset1, "amt1"),
#                     Sync(oracle),
#                     Swap(swap_pair1, asset1, asset0, "amt2"),
#                     Swap(swap_pair2, asset0, stable_coin, "amt3"),
#                     Swap(swap_pair3, asset1, stable_coin, "amt4"),
#                 Payback(lend_pool0, asset0, "amt5"),
#             ]
#         # fmt: on

#             template_times = [
#                 (1,),
#                 (1,),
#                 (0, 1),
#                 (1,),
#                 (0, 1),
#                 (0, 1),
#                 (1,),
#             ]
#             self.extend_candidates_from_template(template, template_times)

#     def gen_candidates_tokenburn(self):
#         lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
#         assets = [k for k, v in self.roles.items() if v.is_asset]
#         stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
#         swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
#         oracles = [k for k, v in self.roles.items() if v.is_oracle]
#         # fmt: off
#         for (
#             lend_pool0, asset0, swap_pair0, asset1, oracle, swap_pair1, swap_pair2, stable_coin,
#         ) in itertools.product(
#             lend_pools, assets, swap_pairs, assets, oracles, swap_pairs, swap_pairs, stable_coins
#         ):
#             template: List[AFLAction] = [
#                 Borrow(lend_pool0, asset0, "amt0"),
#                     Swap(swap_pair0, asset0, asset1, "amt1"),
#                     Burn(oracle, asset1, "amt2"),
#                     Sync(oracle),
#                     Swap(swap_pair0, asset1, asset0, "amt3"),
#                     Swap(swap_pair1, asset0, stable_coin, "amt4"),
#                     Swap(swap_pair2, asset1, stable_coin, "amt5"),
#                 Payback(lend_pool0, asset0, "amt6"),
#             ]
#         # fmt: on
#             template_times = [
#                 (1,),
#                 (1,),
#                 (1,),
#                 (0, 1),
#                 (1,),
#                 (0, 1),
#                 (0, 1),
#                 (1,),
#             ]
#             self.extend_candidates_from_template(template, template_times)

#     def gen_candidates_lrbreak(self):
#         lend_pools = ["owner"] + [k for k, v in self.roles.items() if v.is_lendpool]
#         assets = [k for k, v in self.roles.items() if v.is_asset]
#         stable_coins = [k for k, v in self.roles.items() if v.is_stablecoin]
#         swap_pairs = [k for k, v in self.roles.items() if v.is_swappair]
#         oracles = [k for k, v in self.roles.items() if v.is_oracle]
#         defi_entrys = [k for k, v in self.roles.items() if v.is_defientry]
#         # fmt: off
#         for (
#             lend_pool0, asset0, swap_pair0, asset1, defi_entry, oracle, swap_pair1, swap_pair2, stable_coin,
#         ) in itertools.product(
#             lend_pools, assets, swap_pairs, assets, defi_entrys, oracles, swap_pairs, swap_pairs, stable_coins,
#         ):
#             template: List[AFLAction] = [
#                 Borrow(lend_pool0, asset0, "amt0"),
#                     Swap(swap_pair0, asset0, asset1, "amt1"),
#                     BreakLR(oracle, defi_entry),
#                     Sync(oracle),
#                     Swap(swap_pair0, asset1, asset0, "amt3"),
#                     Swap(swap_pair1, asset0, stable_coin, "amt4"),
#                     Swap(swap_pair2, asset1, stable_coin, "amt5"),
#                 Payback(lend_pool0, asset0, "amt6"),
#             ]
#         # fmt: on
#             template_times = [
#                 (1,),
#                 (1,),
#                 (1,),
#                 (0, 1),
#                 (1,),
#                 (0, 1),
#                 (0, 1),
#                 (1,),
#             ]
#             self.extend_candidates_from_template(template, template_times)
