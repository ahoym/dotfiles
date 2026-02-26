# XRPL AMM Learnings

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
