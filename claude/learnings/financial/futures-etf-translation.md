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

## Cross-Refs

- `order-book-pricing.md` — Mid-price and slippage concepts apply to futures spread
