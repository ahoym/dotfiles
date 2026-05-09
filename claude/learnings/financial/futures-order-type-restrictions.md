Per-contract order-type rules on futures: VIX-family rejects MKT, mitigation via wide-crossing LMT.

**Keywords:** futures, MKT, market order, limit order, VIX, VXM, VX, Cboe, CFE, contract specification, order rejection, RejectReason
**Related:** futures-etf-translation.md, order-book-pricing.md

## The gotcha

Some exchanges reject MKT (market) orders for specific contracts as a hard rule. Most prominently, **Cboe rejects MKT on VIX-family futures** (VX full-size, VXM mini-VIX). The rejection is exchange-side, not broker-side — surfaces with broker-terse codes like `Error: "FAILED"` plus the actual reason in a `RejectReason` field:

```
"RejectReason": "future contract VXM: order Type = MKT not allowed"
"Status": "REJ"
```

CME equity-index contracts (NQ, MNQ, ES, MES) accept MKT. The rule is per-contract, not per-exchange. Don't generalize from CME experience.

## How it surfaces in code

A futures execution path that places MKT directly (or escalates to MKT on the final attempt of a LMT-first ladder) silently breaks for VIX-family contracts. Mock tests pass cleanly because they don't exercise exchange rules — only live (or sim against a real broker) catches it. The first symptom is usually a terse rejection log; broker integrations often drop the `RejectReason` field on the way to the application log unless explicitly captured.

## Mitigation pattern: wide-crossing LMT

For contracts where MKT is disallowed, replace the MKT-fallback with a **wide-crossing LMT**:

- Buy: `current_price × (1 + buffer)` — sets a max cap
- Sell / sell-short: `current_price × (1 - buffer)` — sets a min cap

The buffer functions as a max-acceptable price cap, not the actual fill price. In normal regimes the broker routes to NBBO best within the cap and the fill lands at prevailing market. In extreme regimes the cap protects against gap fills — precisely when you wouldn't want a blind MKT anyway.

**Buffer sizing:** match the contract's spread + volatility profile. VIX-family realizes 5-8% daily vol; 2% buffer crosses normal spreads with comfortable headroom in fast regimes. Tighter products (e.g. equity-index micros) can use less. Configurable per-contract beats hardcoded.

## Implementation pattern

Per-contract specification with policy flags, not magic-string product checks at the call site:

```python
@dataclass(frozen=True)
class ContractSpec:
    margin_per_contract: float
    notional_per_contract: float
    allow_market_fallback: bool = True       # MKT-accepting default
    market_fallback_buffer_pct: float = 0.0  # crossed price = current × (1 ± pct)
```

Final-attempt branch in the ladder reads the spec; no per-product if-tree in the execution path. Keeps execution logic generic; product-specific rules live with the product registration.

## Onboarding check

Before adding a new futures contract to a registry like `CONTRACT_SPECS`:

1. Verify the exchange's order-type permission table for that contract (broker docs or one-shot sim test).
2. If MKT is disallowed, set `allow_market_fallback=False` and pick a buffer sized for the product's spread + vol.
3. Comment the rationale at the spec entry — future maintainers should not "fix" the flag back to default.

Likely candidates beyond VIX-family: less-liquid agriculturals, ETF-derivative futures with auction-only sessions, single-stock futures on some exchanges. Confirm per product.

## Cross-Refs

- `futures-etf-translation.md` — ETF → futures sizing and P/L translation; the "Retry of non-idempotent broker calls is a double-fill risk" section pairs with this one (the no-blind-retry rationale doesn't preclude cancel-and-replace LMT ladders, which are exchange-rule-compliant).
- `order-book-pricing.md` — Mid-price + slippage concepts inform buffer sizing.
