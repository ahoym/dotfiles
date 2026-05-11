Translating leveraged ETF strategies to micro futures (MNQ, MES): sizing, P/L mapping, and DCA mechanics.

**Keywords:** futures, MNQ, MES, TQQQ, SQQQ, leveraged ETF, position sizing, notional, margin, DCA
**Related:** order-book-pricing.md

## ETF → Futures Ticker Mapping

Leveraged ETFs collapse to their base index future. Direction and leverage are controlled by contract count and long/short:

| ETF | Underlying | Futures | Leverage source |
|-----|-----------|---------|-----------------|
| TQQQ (3x Nasdaq) | QQQ | NQ / MNQ | Position sizing (not a 3x contract) |
| SQQQ (-3x Nasdaq) | QQQ | NQ / MNQ (short) | Short the contract |
| SPXL (3x S&P) | SPY | ES / MES | Position sizing |
| TLT (20yr bonds) | — | ZB / UB | Different instrument entirely |
| UVXY (1.5x VIX) | — | /VX | No micro available; $1,000/point |

## P/L Translation

ETF return → futures P/L per contract:
```
QQQ % move = TQQQ % move / 3  (or -SQQQ % move / 3)
MNQ P/L    = QQQ % move × MNQ notional
MNQ notional = $2 × Nasdaq-100 level  (~$40,000 at Nasdaq 20,000)
```

Key difference: ETF P/L scales with shares (continuous). Futures P/L is fixed per contract (discrete). Adding $1,000 to a futures account changes nothing until you can fund another contract.

## Position Sizing Strategies

From most conservative to most aggressive:

| Strategy | Contracts at $20k | Tradeoff |
|----------|-------------------|----------|
| **Full notional** (1 contract per ~$40k notional) | 0 | Can't trade at all when Nasdaq > 10,000 |
| **Fixed dollar** ($20k per contract) | 1 | Conservative; stuck at 1 for years if growth is slow |
| **Margin buffer** (5× margin, ~$20k) | 1 | Same as above but intention is risk-based |
| **Margin multiple** (2.5× margin, ~$10k) | 2 | Faster compounding, larger drawdowns |
| **Bare margin** ($4,100 per contract) | 4 | Maximum leverage; margin call risk on any drawdown |

The fixed-dollar approach ($20k/contract) showed ~23% max drawdown historically vs ~35% with proportional sizing and ~75% with aggressive margin-based sizing.

## DCA is Fundamentally Different with Futures

With ETF shares, $1,000 deposit → proportionally more shares → immediate increase in exposure.

With futures contracts, $1,000 deposit → sits as cash buffer until you cross the next contract threshold. A $1,000/month DCA into a 1-contract MNQ account produces **zero additional exposure** for months until cumulative deposits push past $20k × 2 = $40k for contract #2.

However, once DCA breaks past sizing thresholds, the effect compounds: deposits that enabled an extra contract during a big trend produce outsized returns. In backtesting, $93k in DCA deposits over 8 years produced 4.7× the final balance vs lump sum — the deposits unlocked exponentially more contracts during high-return periods.

## Minimum Contract Floor

With fixed-dollar sizing at exactly the starting balance (e.g., $20k/contract on a $20k account), one losing trade drops below the threshold → 0 contracts → account is permanently dead. Always enforce a minimum of 1 contract as long as margin is covered.

## Whole-shares contract enforcement at the broker boundary

When a project assumes whole-shares (no fractional fills — typical for leveraged ETFs on Schwab), enforce the contract loudly at the adapter layer that constructs the typed order-status object:

```python
def _to_whole_shares(value, field_name: str) -> int:
    as_float = float(value)
    if as_float != int(as_float):
        raise ValueError(
            f"Fractional fill detected in {field_name}={value!r} — "
            f"whole-shares contract violated; adapter must coerce or widen field type."
        )
    return int(as_float)
```

Two failure modes this handles:
- **Broker JSON shape drift** — a field returning `'10'` or `'10.0'` (string instead of int) round-trips through `float()` cleanly, so the adapter doesn't crash on an upstream format change and propagate the crash through the retry layer's broad `except Exception`.
- **Future fractional adapter** — when a broker that supports fractional fills is added (TradeStation, IBKR), a genuinely fractional value (`1.5`) raises immediately with the field name in the diagnostic, surfacing the contract violation at the adapter rather than silently truncating shares the retry loop never reconciles.

Use `if/raise`, not `assert` — `python -O` strips assertions and this is in a trading hot path. (See also: `python-specific.md` → "assert for production guards is a silent-failure footgun".)

## Retry of non-idempotent broker calls is a double-fill risk

For futures market orders (and any non-idempotent broker call), retry-on-failure is more dangerous than fail-fast: a successful fill + lost response is indistinguishable from a real failure, so retry can produce 2× exposure. Recovery via per-leg state persistence (write flat state immediately after the close-leg call) gives next-signal recovery without in-flight retry. Inverts the usual retry wisdom — defensive retry assumes idempotency.

**Cancel-and-replace is the safe counter-pattern.** A blind retry on the original place call is dangerous. A cancel-and-replace LMT ladder (poll order state → confirm fill → cancel before placing replacement) preserves safety because each new placement happens only after the previous order's state is broker-confirmed. The dangerous pattern is unconditionally retrying the place; the safe pattern is conditioning each placement on a prior fill check. This is what makes equity-style LMT ladders safe to port to futures despite the no-blind-retry rule.

## Leveraged ETF ≠ underlying future even when "labels match" (UVXY vs +@VX)

Don't assume `UVXY → +@VX` is a clean substitute just because both are "VIX exposure." Empirically: UVXY's daily return beta to back-adjusted continuous VX is **~2.67×** (correlation 0.805, vol ratio 3.32×, measured 2016-2026 on clean rows). Two compounding sources:

1. **Different underlying.** UVXY tracks a *daily-rebalanced rolling basket* of near-month VIX futures (~50/50 month-1 + month-2). VX is a single front-month contract. The basket is intrinsically more volatile than back-adjusted continuous VX (the back-adjustment smooths roll cost into price drift, dampening per-day vol).
2. **1.5× ETF leverage** stacked on top of (1).

Single-day examples on big vol-ups: UVXY/VX ratio ranges 1.18× to 4.05×. Volmageddon (2018-02-05): VX +16.3%, UVXY +66.2% (4.05×). Algo strategies tuned on UVXY's payoff profile won't generalize to `+@VX` at the same notional sizing — what was a profitable vol-spike capture in the ETF can become a losing leg in the future.

If the ETF→future translation premise is "1:1 contract parity," that's a *slot-count* parity, not a *vol-exposure* parity. Verify with empirical beta before assuming the algo's edge transfers.

## Two senses of futures leverage — margin efficiency vs vol-sensitivity per cash dollar

"Futures are more leveraged than ETFs" is correct in *one* sense and wrong in the other. Distinguish before reasoning about expected P/L:

| Sense | Definition | Winner (VX vs UVXY at $20k) |
|---|---|---|
| **Capital/margin leverage** | Notional held per dollar of cash margin posted | VX wins — $18k notional on ~$13k margin = 1.4× |
| **Vol-exposure per cash dollar deployed** | $-P/L for a 1% move in the underlying, per dollar of cash | UVXY wins — ~3× the VX-equivalent vol exposure for the same starting cash |

Slot-count sizing rules (`floor(cash / $20k_notional)`) under-deploy margin: the algo only uses ~$13k of $20k as VX margin, leaving $7k idle. Maximum-margin sizing would close that gap somewhat, but per-cash vol-sensitivity is bounded above by the *product* (multiplier × underlying-volatility), and the underlying matters more than the leverage label.

When evaluating a new vol product or sizing-policy override: ask which leverage sense your algo's P/L lives on. Signal-driven entries that pay off on vol shocks live on sense 2; capital-efficient hedges live on sense 1. They're not interchangeable.

## Margin-call survival check for leveraged-futures backtests

Most backtesters don't enforce broker margin-call mechanics — equity goes negative on paper, the simulator keeps running, and the final P/L includes recovery the broker would have force-liquidated out of. Compute the survival buffer at the highest sizing the run touches before trusting any leveraged-futures CAGR.

Peak margin utilization = `M·m/s` where M = sizing multiplier, m = margin/contract, s = slot notional. Drawdown survival buffer = `1 − util`. If observed historical max DD exceeds the buffer, the result is paper-only.

Worked example, MNQ ($4,100 margin / $20k slot):

| Multiplier | Util | Survival buffer | DD 35% | DD 50% | DD 62% |
|---|---:|---:|---|---|---|
| 1× | 20.5% | 79.5% | ✓ | ✓ | ✓ |
| 2× | 41.0% | 59.0% | ✓ | ✓ (9pt) | ✗ |
| 3× | 61.5% | 38.5% | ✓ | ✗ | ✗ paper-only |

Two backtests at different sizings can both "succeed" on paper while one would have been called out of position before recovery. The check is a one-line guard against publishing the paper-only one as a live recommendation.

## Daily-reset ETF replication via futures: roll-slippage floor

Replicating a daily-reset leveraged ETF (UVXY, TQQQ, etc.) in the underlying futures has a roll-slippage floor that **micro contracts don't reduce**. Cost lives in two-sided notional turnover × spread %, and tick size scales with point value — so % cost is identical across contract sizes:

| Pair | Tick value | Notional/contract | Slippage % per notional |
|---|---:|---:|---:|
| VX | $50 | $18,000 | 0.278% |
| VXM | $5 | $1,800 | 0.278% |
| ES | $12.50 | ~$220,000 | 0.006% |
| MES | $1.25 | ~$22,000 | 0.006% |

Micro contracts save **commissions** (per-contract, 10× fewer per notional moved) but not slippage. At retail commission rates this is a 1-3% drag reduction, not the order-of-magnitude saving the granularity might suggest.

**Daily roll is a swap — slippage paid on both legs.** When estimating cost from "$X/day turnover" figures, distinguish one-sided from two-sided notional or the estimate is off by 2×. A swap of `(1/dr) × N` notional means two fills per day, each crossing its own bid-ask.

**ETF expense ratio encodes real institutional execution edge.** UVXY's 0.95% replicates at ~10-17%/yr drag via DIY VX/VXM at retail spreads on $1M. Crossover where DIY wins is roughly $50M+ — below that, the wrapper's pooled execution beats hand-rolled mechanics.

**SPVXSTR linear roll** (UVXY's underlying index): `M1 weight = dt/dr` slides 100% → 0% over each contract month, `M2 = (dr−dt)/dr` slides 0% → 100%. Daily action: sell `1/dr` of M1 by notional, buy equivalent M2 notional. The "50/50 basket" framing is the cycle average, not the daily holding.

## Cross-Refs

- `order-book-pricing.md` — Mid-price and slippage concepts apply to futures spread
- `futures-order-type-restrictions.md` — Per-contract MKT-rejection rules; the cancel-and-replace ladder is the mitigation when MKT is disallowed (VIX-family on Cboe)
