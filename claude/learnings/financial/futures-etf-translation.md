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

## Cross-Refs

- `order-book-pricing.md` — Mid-price and slippage concepts apply to futures spread
- `futures-order-type-restrictions.md` — Per-contract MKT-rejection rules; the cancel-and-replace ladder is the mitigation when MKT is disallowed (VIX-family on Cboe)
