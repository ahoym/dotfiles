XRPL Automated Market Maker mechanics: constant-product formulas, CLOB+AMM interleaving, LP tokens, and error codes.
- **Keywords:** AMM, XLS-30, constant product, LP token, AMMCreate, AMMDeposit, AMMWithdraw, AMMVote, AMMBid, amm_info, impermanent loss, auction slot, trading fee
- **Related:** ~/.claude/learnings/financial/order-book-pricing.md, ~/.claude/learnings/financial/bignumber-arithmetic.md

---

## Constant-Product Formulas with Fee

XRPL AMM uses `x * y = k` with fee on the **input** asset. Fee rate = `tradingFee / 100_000` (max 1000 = 1%).

Key formulas (B = base reserves, Q = quote reserves, f = fee rate):

| Function | Formula | Notes |
|----------|---------|-------|
| Marginal buy price | `Q*B / ((B-consumed)^2 * (1-f))` | Fee on quote input inflates price |
| Marginal sell price | `Q*B*(1-f) / (B+consumed*(1-f))^2` | Fee on base input reduces proceeds |
| Max buy before price P | `B - sqrt(Q*B / (P*(1-f)))` | Clamp to 0 |
| Max sell before price P | `(sqrt(Q*B*(1-f)/P) - B) / (1-f)` | Clamp to 0 |
| Buy cost (delta) | `Q*B*delta / ((B-consumed-delta)*(B-consumed)*(1-f))` | Integral of marginal buy |
| Sell proceeds (delta) | `Q*B*delta*(1-f) / ((B+consumed*(1-f))*(B+(consumed+delta)*(1-f)))` | Integral of marginal sell |

Refs: [AMM Concepts](https://xrpl.org/docs/concepts/tokens/decentralized-exchange/automated-market-makers), [XLS-30d](https://github.com/XRPLF/XRPL-Standards/discussions/78)

## Interleaved CLOB+AMM Fill Estimation

The XRPL DEX engine routes through both CLOB and AMM, picking the better-priced source. To estimate fills:

1. Compare AMM marginal price vs next CLOB level price
2. If AMM is better: compute how much AMM can fill before price crosses CLOB level (`ammMaxBuyBeforePrice`/`ammMaxSellBeforePrice`), consume that chunk
3. Consume from CLOB level
4. Repeat; after CLOB exhausted, fill remainder from AMM (cap at 99% of reserves to avoid asymptote)
5. Track `clobFilled` and `ammFilled` separately for source breakdown display

"Better" means: lower price for buys, higher price for sells.

## `amm_info` Asset Order Normalization

`amm_info` may return `amount`/`amount2` in a different order than the `asset`/`asset2` requested. Always match the response amounts by currency+issuer to determine which is base vs quote, rather than assuming positional correspondence.

```ts
const amount1IsBase =
  amount1.currency === baseCurrency &&
  (baseCurrency === "XRP" || amount1.issuer === baseIssuer);
const base = amount1IsBase ? amount1 : amount2;
const quote = amount1IsBase ? amount2 : amount1;
```

## AMM Overview (XLS-30)

Native AMM support via the XLS-30 amendment, enabled on mainnet 2024-03-22. Key properties:
- **Constant product formula**: `x * y = k` with equal weights (W=0.5)
- **One AMM per pair**: Each unique asset pair can have exactly one AMM
- **LP tokens**: Liquidity providers receive LP tokens proportional to pool share
- **Votable trading fee**: 0-1% in units of 1/100,000
- **Auction slot**: 24-hour trading advantage slot that mitigates impermanent loss
- **Special AMM account**: Pseudo-random address AccountRoot that holds assets and issues LP tokens. Regular key set to account zero, master key disabled. Not subject to reserve, cannot sign transactions.

### LP Token Currency Codes

LP tokens use a special 160-bit hex currency code: first 8 bits are `0x03`, remainder is a truncated SHA-512 hash of the two asset currency codes and issuers. Initial LP issuance: `sqrt(Amount1 * Amount2)`. Returning all LP tokens triggers auto-deletion of the AMM.

## AMM Transaction Types

### AMMCreate

Creates AMM and provides initial funding. **Special cost**: destroys at least the incremental owner reserve (0.2 XRP on mainnet after 2024 reserve reduction), not the standard ~0.00001 XRP fee. Use xrpl.js autofill for dynamic fee calculation.

Prerequisites: at most one asset can be XRP, cannot use LP tokens, creator must hold both assets, DefaultRipple must be enabled on issuer.

### AMMDeposit

Two categories: **double-asset** (proportional, no fee): `tfTwoAsset`, `tfTwoAssetIfEmpty`. **Single-asset** (subject to trading fee): `tfSingleAsset`, `tfOneAssetLPToken`, `tfLimitLPToken`, `tfLPToken`.

### AMMWithdraw

Auto-deletion: if last LP tokens returned and pool has ≤512 trust lines, AMM auto-deletes. If >512 trust lines remain, `AMMDelete` must be called.

### AMMVote

Up to 8 LP holders can vote on trading fee. Effective fee is weighted average by LP token balance.

### AMMBid

24-hour auction slot for discounted trading (1/10 of normal fee). Proceeds partially burned (reducing total LP supply, increasing remaining holders' share).

## AMM + CLOB Integration

The AMM's offer is injected into the liquidity stream alongside order book offers during trade execution. **Critical: `book_offers` does NOT include AMM liquidity** — AMM synthetic offers are injected only at the tx execution layer, not the API query layer. Must separately query `amm_info` for pool depth.

## AMM-Specific Error Codes

| Code | Applies To | Description |
|------|-----------|-------------|
| `tecAMM_UNFUNDED` (162) | AMMCreate | Insufficient assets to fund pool |
| `tecAMM_BALANCE` (163) | Deposit/Withdraw | Would drain one side or rounding error |
| `tecAMM_FAILED` (164) | Deposit/Withdraw | Conditions not satisfied (e.g., EPrice too low) |
| `tecAMM_INVALID_TOKENS` (165) | Create/Withdraw | LP token conflicts or withdrawal rounds to zero |
| `tecAMM_EMPTY` (166) | Deposit/Withdraw | Pool has no assets; must use `tfTwoAssetIfEmpty` |
| `tecAMM_NOT_EMPTY` (167) | Deposit | Used `tfTwoAssetIfEmpty` on non-empty pool |
| `tecAMM_ACCOUNT` (168) | General | Operation not allowed on AMM accounts |
| `tecDUPLICATE` | AMMCreate | AMM already exists for this pair |
| `tecFROZEN` | All | Frozen token involved |
| `terNO_RIPPLE` | AMMCreate | Issuer hasn't enabled DefaultRipple |

### Frozen Asset Edge Case

When an issuer freezes a token in an AMM pool: LP tokens also freeze (can receive but not send/sell), deposits and withdrawals fail with `tecFROZEN`. `amm_info` response includes `asset_frozen` / `asset2_frozen` boolean fields.

### Empty Pool State

When all LP tokens are redeemed: if ≤512 trust lines, AMM auto-deletes. If >512, AMM enters "empty" state — only `tfTwoAssetIfEmpty` deposit or `AMMDelete` can proceed. Normal deposits fail with `tecAMM_EMPTY`.

## Impermanent Loss Mitigation

1. **Auction slot**: Near-zero-fee arbitrage rebalances pool immediately when prices diverge
2. **Fee accumulation**: Trading fees distributed proportionally to LP holders on withdrawal
3. **Auction proceeds burned**: Increases remaining holders' proportional share

## AMM Liquidity in Transaction Metadata

AMM liquidity consumed during trade execution appears in `AffectedNodes` as `LedgerEntryType: "AMM"` modifications — not as Offer nodes. When parsing metadata to determine fill sources (CLOB vs AMM), check for modified AMM nodes separately from modified/deleted Offer nodes.

## Cross-Refs

- `~/.claude/learnings/financial/order-book-pricing.md` — mid-price, slippage estimation for interleaved CLOB+AMM fills
- `~/.claude/learnings/financial/bignumber-arithmetic.md` — BigNumber.js patterns for AMM formula computations
