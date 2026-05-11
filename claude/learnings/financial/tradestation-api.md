TradeStation Web API behavior: account-type gating, validation ordering, TIF rules, preview endpoint, options-chain permissions, futures-option symbol formats.
- **Keywords:** TradeStation, TS, TS API, AccountType, Futures account, Margin account, orderconfirm, OrderID, DAY, GTC, market hours, options expirations, 403 permission, VX futures options, symbol format
- **Related:** ~/.claude/learnings/financial/futures-etf-translation.md, ~/.claude/learnings/financial/futures-order-type-restrictions.md, ~/.claude/learnings/financial/vendor-divergence.md

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

## Cross-Refs

- `futures-etf-translation.md` — ETF/futures math, margin-call survival check, daily-reset replication roll-slippage floor
- `futures-order-type-restrictions.md` — Per-contract MKT-rejection rules (CFE VIX-family) + wide-crossing LMT mitigation
