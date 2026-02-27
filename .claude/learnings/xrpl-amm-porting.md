# XRPL AMM Module Porting (dex-portal → issued-currencies-manager)

## AmmPoolInfo type divergence

This repo uses nested `AmmPoolInfo`: `pool.asset1?.value`, `pool.assetFrozen`.
Dex-portal uses flat: `pool.asset1Value`, `pool.asset1Frozen`.

When porting `buildAmmPoolParams`, adapt field access — don't change the type. The nested shape is more correct and changing it ripples into panel, hook, and OpenAPI schema.

## amm-fee.ts divergence

Both repos get the same XRPL `trading_fee` integer (e.g., 1000 = 1%).

- **This repo**: `fee / 1000` → `"1.00%"` (treats range as 0–1000 mapping to 0%–1%)
- **Dex-portal**: `(fee / 100_000) * 100` → `"1%"` (raw XRPL unit = 1/100,000, then × 100 for percent)

Same result, different expression. The `amm-math.ts` module uses `FEE_DIVISOR = 100_000` internally (raw XRPL spec), which is correct regardless of display helper.

## order-book-levels.ts is a direct extraction

`order-book-levels.ts` in dex-portal is a verbatim extraction of `order-book.tsx` lines 43-67 in this repo — identical ask/bid classification, funded amount preference (`taker_gets_funded ?? taker_gets`), sort order (descending by price), and zero-funded filtering. Port is copy-paste; refactoring the component to import is pure deduplication.

## AMM marginal price ↔ effective price relationship

At consumed=0:
- `ammMarginalBuyPrice = spotPrice / (1 - fee)` — what dex-portal displays as "effective buy price"
- `ammMarginalSellPrice = spotPrice * (1 - fee)` — the fee-adjusted sell side

Computing these server-side in `/api/amm/info` avoids client BigNumber overhead. The formulas diverge from spot as `consumed` increases (slippage), but at zero they're simple fee adjustments.
