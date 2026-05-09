Futures order prices must snap to the contract's minimum price increment (tick), not just round to cents. Exchanges reject off-grid LMTs.

**Keywords:** futures, tick size, price increment, LMT order, off-grid, broker reject, MNQ, VX, VXM, Cboe, CME
**Related:** futures-order-type-restrictions.md, numeric-precision-strategy.md, order-book-pricing.md

## The bug

`round(price, 2)` enforces cent precision, but VX/VXM trade in 0.05 increments and MNQ in 0.25. A `19.19` LMT on VX gets rejected by TradeStation as:

```
Order failed. Reason: future contract VX: order Price = 19.19000000 is not precise [ 5/100 ]
```

The `[N/M]` payload tells you the tick grid: `5/100 = 0.05`. CME Globex / Cboe surface the same constraint with similar messages.

Off-grid prices come from two sources:
1. **Synthetic/midpoint quotes** — broker market data isn't always tick-aligned (cross-quotes, halted markets, derived NBBO mids).
2. **Crossing-LMT math** — `current_price × (1 ± buffer)` rarely lands on grid (e.g. `19.40 × 1.02 = 19.788`).

## The fix

Register `tick_size` per contract spec and snap before any LMT is placed:

```python
def snap_price_to_tick(price: float, tick_size: float) -> float:
    return round(round(price / tick_size) * tick_size, 4)
```

The trailing `round(_, 4)` absorbs float-division fuzz (`19.20` doesn't surface as `19.200000000000003`); sufficient for tick sizes ≥ 0.0001.

## Common futures tick sizes

| Contract | Tick | $/contract |
|----------|------|-----------|
| MNQ | 0.25 | $0.50 |
| NQ | 0.25 | $5.00 |
| VX (full VIX) | 0.05 outright, 0.01 spreads | $50 / $10 |
| VXM (mini VIX) | 0.05 outright, 0.01 spreads | $5 / $1 |
| ES | 0.25 | $12.50 |
| MES | 0.25 | $1.25 |
| CL (crude) | 0.01 | $10 |

Equities default to 0.01 (cent grid) — the futures gotcha doesn't apply, which is why `round(price, 2)` survives there.

## Crossing-LMT direction

When snapping a wide-crossing LMT (final-attempt buffer designed to cap fill price), round-to-nearest is fine in practice — a single-tick excursion is noise vs a 2% buffer. If the buffer is a hard cap, snap conservatively (toward `current_price`): floor for buys, ceil for sells.

## When this matters

Triggers any time price math feeds into an order:
- Crossing-LMT / wide-LMT final attempts (multiplier × buffer)
- Stop-trigger derivation (entry price ± N ticks)
- TWAP/VWAP slice prices computed from rolling averages
- Any "round to nearest cent" pattern in a futures path

Lint heuristic: `round(price, 2)` next to a broker call on a futures path is suspect. The right pattern is `snap_price_to_tick(price, spec.tick_size)`.

## `round(_, 10)` Required Before Directional Ceil/Floor

The `round(price/tick_size)` form above relies on Python's round-to-nearest absorbing sub-tick float-division fuzz (`19.20 / 0.05` → `383.999...`, then `round()` → `384`). For directional rounding (`mode="ceil"` for buys, `mode="floor"` for sells), the fuzz survives:

```python
math.floor(19.20 / 0.05)  # = 383, off by one tick
math.floor(round(19.20 / 0.05, 10))  # = 384, correct
```

Pattern: pre-round to 10 decimals before `floor`/`ceil`, then multiply by `tick_size`, then `round(_, 4)` for the final tick-multiply. The trailing 4-decimal absorb is still sufficient — only the directional op needs the wider window.

```python
def snap_price_to_tick(price: float, tick_size: float, mode: Literal["nearest", "ceil", "floor"] = "nearest") -> float:
    if not math.isfinite(price): raise ValueError(...)  # guard non-finite first
    ratio = price / tick_size
    if mode == "ceil":    units = math.ceil(round(ratio, 10))
    elif mode == "floor": units = math.floor(round(ratio, 10))
    else:                 units = round(ratio)
    return round(units * tick_size, 4)
```

Derive `mode` from existing leg semantics where possible: `mode = "ceil" if leg.cross_sign > 0 else "floor"` for crossing-LMT — avoids threading a new direction parameter through the call chain.
