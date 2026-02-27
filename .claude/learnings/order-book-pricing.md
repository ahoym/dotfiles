# Order Book Pricing & Slippage

## Mid-Price Approaches

- **Simple mid** `(bestAsk + bestBid) / 2` — industry standard for exchange UIs (Binance, Coinbase, CME). Use this for display.
- **Micro-price** — weights top-of-book by opposite side's size: `(askPrice × bidSize + bidPrice × askSize) / (bidSize + askSize)`. Used internally by quant desks/market makers, not displayed on exchange UIs.
- **Weighted mid (VWAP)** — `Σ(price × volume) / Σ(volume)` across all visible levels. Non-standard as a primary mid (distorts toward stale far-from-market orders), but useful as a **supplementary hover metric** alongside simple mid. Both xrpl-dex-portal and issued-currencies-manager use it this way — hover-only, never the default display.

## Slippage Estimation (Walk-the-Book)

Walk levels best-price-first, accumulate size until target amount filled:

```ts
for (const level of levels) {
  const consume = BigNumber.min(remaining, level.amount);
  filledAmount += consume;
  totalCost += consume * level.price;
  worstPrice = level.price;
  remaining -= consume;
}
avgPrice = totalCost / filledAmount;
slippage = |avgPrice - midPrice| / midPrice × 100;
```

- For **buys**: walk asks ascending (lowest first)
- For **sells**: walk bids descending (highest first)
- Track `fullFill` (remaining <= 0) and warn when book depth is insufficient
- Most useful for market-style orders (IOC/FOK); for limit orders, show "X% immediately fillable at avg Y"
- Best placement: on the order form after amount entry, not baked into the mid-price display
