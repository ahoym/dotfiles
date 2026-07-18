TradeStation Web API behavior: account-type gating, validation ordering, TIF rules, preview endpoint, options-chain permissions, futures-option symbol formats.
- **Keywords:** TradeStation, TS, TS API, AccountType, Futures account, Margin account, orderconfirm, OrderID, DAY, GTC, market hours, options expirations, 403 permission, VX futures options, symbol format, continuous symbol, @MNQ, @TY, order symbol, barchart probe, suggest endpoint, entitlement, data vs trade entitlement
- **Related:** ~/.claude/learnings/financial/futures-etf-translation.md, ~/.claude/learnings/financial/futures-order-type-restrictions.md, ~/.claude/learnings/financial/vendor-divergence.md
- **Scope:** TradeStation-specific — patterns reflect a single broker's API. Cross-vendor patterns live in `vendor-divergence.md`.

## Account types gate asset class, not just permission

`AccountType: "Futures"` accounts can't hold equities. Rejection on equity orders returns `"Closing Transactions Only - below minimum equity ratio requirement"` (not `"not approved"`) because there's no equity-margin facility against which to measure the ratio. Account types from `GET /brokerage/accounts`: `Cash`, `Margin`, `Futures`. Equity-trading scripts must resolve to a Margin or Cash account, not a Futures one.

## OrderID generated before margin/account-type validation

TS assigns an `OrderID` to any structurally-valid order envelope **before** running margin and account-type checks. OrderID generation is *not* proof of account permission — a rejected order can come back with a populated `OrderID` and `"Status": "REJ"`. Don't infer "account is permissioned for X" from receiving an OrderID alone; the full envelope (`Error`, `Message`, `RejectReason`) carries the actual outcome.

## TimeInForce DAY rejected outside market hours

`Duration: "DAY"` is only accepted while equity markets are open. Outside RTH (overnight, weekends, holidays), TS rejects with `"Only GTC/GTC+/GTD/GTD+ orders when markets are closed"`. Inspection/verification scripts that may run any time should default to `GTC`, which works in both regimes.

## orderconfirm is the actual permission gate (preview without placement)

`POST /orderexecution/orderconfirm` runs full margin + account-type + symbol-permission validation and returns estimated cost / commission / BP impact, **without placing the order**. Safe to call against `live` env. The orderconfirm response (`Errors` present vs `Confirmations` populated) is the definitive "can this account trade this symbol" answer — distinct from `/orderexecution/orders` which actually places.

## 403 on options chain endpoints = permission gate, not missing resource

`GET /marketdata/options/expirations/{underlying}` returning HTTP **403** (not 404) means the endpoint exists but the account/credentials aren't authorized — typically because real-time options data subscription is inactive, or futures-options approval is denied. Distinguishing 403-permission from 404-not-found matters when probing what an account can access; treat 403 as informative ("you can't see this") not as "doesn't exist."

## Futures-option symbol format: web UI is authoritative

TS's canonical futures-option symbol format isn't uniformly documented across their API surface. When `/marketdata/symbols/{guess}` returns `"invalid symbol"` on common formats (`VXM26C20`, `OVXM26C20`, `VXM26C2000`), the authoritative source is the TS web platform's option chain UI — clicking an option contract shows the exact symbol string TS expects. Trying multiple formats programmatically wastes calls; the web lookup is one click and definitive.

## `@`-continuous order routing is per-product (data-entitled ≠ order-routable)

A continuous-contract symbol that quotes fine for market data may still be rejected for **order placement** — and the rule is per-product, not universal. `@MNQ` routes for orders; `@TY` does **not** (`Order failed. Reason: @TY is not a valid order symbol`), even though `@TY` returns bars on `/marketdata/barcharts`. Don't generalize from one product's continuous-order behavior. Route futures orders against the **explicit contract month** (e.g. `TYU26`), reserving `@`-continuous for market data. Verified sim + live, 2026-05.

This is the extreme case of **data entitlement ≠ trade entitlement**: a symbol can be fully entitled for quotes yet unusable as an order symbol. Confirm order routing with an actual (sim) placement, not a successful barchart/quote.

## `/symbols/suggest` is unreliable; the barchart probe is the authoritative validity check

`GET /marketdata/symbols/suggest/{text}` returns `{"Errors":[{"Error":"NotFound","Message":"invalid symbol"}]}` even for known-good roots (`MNQ`, `Nasdaq`, `TY`) — don't trust it to discover or confirm a symbol. The reliable triage is a 1-bar `GET /marketdata/barcharts/{sym}`:

| Response | Meaning |
|---|---|
| `200` + `"Bars"` | recognized **and** entitled — usable |
| `200` + `"Not entitled"` | recognized, **unsubscribed** (entitlement gap) |
| `400` + `"Invalid Symbol"` | not a TS symbol at all |

Entitlement is per-env: probe both `sim` and `live` if the algo runs against live (data entitlement on one doesn't guarantee the other).

## Far-from-mid resting limit verifies order routing without a fill or position

To confirm a contract is order-routable (the L4 / gold-standard check beyond `orderconfirm`'s preview), place a **limit far through the market so it cannot fill** — BUY ~20% *below* mid (snapped DOWN), SELL ~20% *above* (snapped UP) — confirm the broker accepts it (`Status` → `ACK`/working, not `REJ`), then cancel. Proves quoting + routing + symbol-validity (the `@TY`-style "not a valid order symbol" reject surfaces here) with **zero fill risk and no position**, even on `live`. A rejection is the verdict, not an error — catch the `place_order` raise and report it. Acceptance ≠ fill: a far-from-mid limit never crosses, so a true fill test still needs a marketable order (safe on `sim`).

## One registry-driven verify tool beats per-instrument probe scripts

Verification scripts proliferate one-per-ticker (`verify_at_mnq_order`, `verify_us_treasury`, …). Collapse to one generic probe parameterized by a `--root`/`--symbol` that resolves tick + the active dated contract from the contract registry (`CONTRACT_SPECS` + `next_active_contract`). A new contract added to the registry is then verifiable with no new script. Keep it **verify-once** — no "verify everything" sweep; a contract that passed stays passed (YAGNI).

## Short positions report a signed-negative Quantity

TS reports a short with `Quantity` *signed negative* (`-2.0`) alongside `LongShort: "Short"` — redundant encoding. A normalizer that guards `Quantity <= 0` (assuming a positive magnitude) crashes on **every** `get_balance` while short, wedging the account until manually flattened. `MarketValue` may likewise arrive signed for a short; `AveragePrice` stays positive (entry price).

**Normalize defensively — magnitude + authoritative flag.** When a field's sign convention is uncertain (some payloads a magnitude, some signed), take `abs(value)` and re-sign from the authoritative direction field — round-trips both `-2`+Short and `2`+Short to `-2`:

```python
qty = abs(float(pos["Quantity"]))
qty = -qty if pos["LongShort"] == "Short" else qty   # LongShort is authoritative
market_value = abs(float(pos["MarketValue"]))         # may be signed for a short
```

## Cross-Refs

- `futures-etf-translation.md` — ETF/futures math, margin-call survival check, daily-reset replication roll-slippage floor
- `futures-order-type-restrictions.md` — Per-contract MKT-rejection rules (CFE VIX-family) + wide-crossing LMT mitigation
- `futures-tick-rounding.md` — Off-grid LMT rejection; `snap_price_to_tick` must round to the tick's own decimal count (1/64, 1/32 need 6/5 places)
