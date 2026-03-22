# Order Book Pricing & Slippage

Mid-price calculations (simple, micro-price, VWAP), walk-the-book slippage estimation, and midprice module design with BigNumber helpers.
- **Keywords:** mid-price, micro-price, VWAP, slippage, walk-the-book, BigNumber, order book, IOC, FOK, xrpl.js, BookOffer, OrderBookEntry
- **Related:** xrpl-patterns.md, bignumber-financial-arithmetic.md

---

## Mid-Price Approaches

- **Simple mid** `(bestAsk + bestBid) / 2` — industry standard for exchange UIs (Binance, Coinbase, CME). Use this for display.
- **Micro-price** — weights top-of-book by opposite side's size: `(askPrice × bidSize + bidPrice × askSize) / (bidSize + askSize)`. Used internally by quant desks/market makers, not displayed on exchange UIs.
- **Weighted mid (VWAP)** — `Σ(price × volume) / Σ(volume)` across all visible levels. Non-standard as a primary mid (distorts toward stale far-from-market orders), but useful as a **supplementary hover metric** alongside simple mid — hover-only, never the default display.

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

## Midprice Module Design

Separate raw BigNumber helpers from the serialized API wrapper:

- `computeMicroPrice(bestAsk, bestBid, bestAskVol, bestBidVol): BigNumber | null` — UI uses directly
- `computeVwap(levels): BigNumber | null` — UI uses directly
- `computeMidpriceMetrics(asks, bids): MidpriceMetrics` — serializes to strings for API transport

This avoids string→BigNumber round-tripping in the UI. The API route calls the serialized wrapper; the order book component calls the raw helpers.

## OrderBookEntry.quality Is Optional

xrpl.js `BookOffer.quality` is `string | undefined`. `OrderBookEntry.quality` must be optional to match — otherwise `normalizeOffer` output requires `as OrderBookEntry[]` casts. `buildAsks`/`buildBids` don't use `quality`, so the optionality is safe.

## Cross-Refs

- `xrpl-patterns.md` — order book fetching (`getOrderbook()`, funded offer fields, depth summary) that feeds into pricing calculations here
- `bignumber-financial-arithmetic.md` — BigNumber.js arithmetic primitives used in slippage/midprice computations
