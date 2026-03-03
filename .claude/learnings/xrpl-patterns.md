# XRPL Patterns

## `getOrderbook()` vs raw `book_offers`

`client.getOrderbook()` (xrpl.js v4.5.0) does significantly more than two `book_offers` calls:
- **Paginates** via `requestAll()` — loops through marker-based pagination to fetch all offers
- **Sorts** both sides by `quality` (exchange rate) using BigNumber — best prices first
- **Limits per-side** after sorting — so `limit=50` returns the 50 best-priced on each side

Raw `book_offers` returns one page in ledger order (not price-sorted). Always prefer `getOrderbook()` unless you need params it doesn't support (e.g., `domain` for permissioned DEX). With raw requests, you need two calls (one per direction) and must normalize the offer format yourself.

## Route-scoped singleton client

When a single route needs a different network than the shared `getClient()` singleton, scope the client to the route file with module-level state. This avoids the shared singleton disconnecting other networks (e.g., a mainnet request would disconnect the active testnet client in `getClient()`).

Pattern: module-level `let client: Client | null`, with connect/reconnect logic mirroring the shared singleton.

## XRPL mainnet WebSocket endpoint

`wss://xrplcluster.com` — public mainnet WebSocket endpoint (cluster of full-history nodes).

## Orderbook: always fetch full book, compute depth server-side

Always fetch `MAX_API_LIMIT` (400) offers per side internally, regardless of display pagination. Compute depth summary (`aggregateDepth()`) server-side from the full book and return it in the response. This ensures depth reflects complete liquidity — display-level slicing (10/25/50/100) happens client-side without affecting the summary.

## DepthSummary: use string for volumes

`DepthSummary.bidVolume` / `askVolume` must be `string` (BigNumber `.toFixed()`), not `number`. Aggregating hundreds of offers can produce values that lose precision as float64. The frontend can `parseFloat()` for display formatting where exact precision isn't needed.

## Funded Offer Fields in book_offers

Confirmed via rippled C++ source (`NetworkOPs.cpp`):

### Three funding states

| Funding status | `taker_gets_funded` present? | In response? |
|---|---|---|
| **Fully funded** | No — omitted | Yes — `TakerGets` is the fillable amount |
| **Partially funded** | Yes (< `TakerGets`) | Yes — use `taker_gets_funded` |
| **Unfunded (zero balance)** | N/A | No — excluded entirely by rippled |

### Key details

- `taker_gets_funded` / `taker_pays_funded` are **only set** when `saOwnerFundsLimit < saTakerGets` (the else branch in rippled)
- When fully funded, the if branch (`saOwnerFundsLimit >= saTakerGets`) skips setting these fields entirely
- Completely unfunded offers (zero owner funds) are omitted from the response unless the offer belongs to the taker
- The fallback pattern `taker_gets_funded ?? taker_gets` is correct: absence of `_funded` genuinely means fully funded

Source: rippled `NetworkOPs.cpp` ~4177-4191.

## RippleState Balance Sign Convention

In XRPL `RippleState` ledger entries, the balance field follows this convention:

- **Positive balance** → the **low** account holds the IOU (has the asset)
- **Negative balance** → the **high** account holds the IOU

The "low" and "high" accounts are determined by the `LowLimit.issuer` and `HighLimit.issuer` fields in the `RippleState` object.

**When computing balance deltas** (finalValue - previousValue):
- A positive delta means the **low** account gained tokens
- A negative delta means the **high** account gained tokens

**Common mistake**: Assuming positive balance means the high account holds the asset. This silently zeroes out balance changes in trade/fill parsers, causing filled orders to not appear.

## Detecting Filled Orders from account_tx

To determine if an `OfferCreate` transaction resulted in a fill (partial or full), parse the transaction metadata:

1. **Filter**: Only look at `OfferCreate` transactions with `TransactionResult === "tesSUCCESS"`
2. **Parse `AffectedNodes`**:
   - `AccountRoot` modifications → XRP balance changes (in drops, divide by 1,000,000)
   - `RippleState` modifications → Token balance changes (see sign convention above)
3. **Compute per-account deltas** for the wallet address
4. **Identify fills**: A fill means the wallet gained one currency and lost another (opposite signs on base/quote deltas)
5. **Filter fee-only changes**: Unfilled offers still modify `AccountRoot` by the tx fee (~12 drops = 0.000012 XRP). Use a threshold of `< 0.001` on both base and quote amounts to skip these false positives.
6. **Determine side**: If the wallet's base currency delta is positive, it's a buy; if negative, it's a sell.

## Vercel Serverless + XRPL WebSocket Connections

On Vercel, each API route can run as a **separate serverless function instance**, each opening its own WebSocket connection to the XRPL node. The WebSocket client singleton is per-process, not per-deployment.

**The Problem:** XRPL public nodes enforce **IP-based connection limits**. When the client polls multiple API routes simultaneously, each route may spawn a separate serverless invocation, each opening its own WebSocket.

**The Mitigation:** Combine multiple XRPL queries into a **single API route** to reduce the number of concurrent serverless invocations and WebSocket connections. Reducing the number of concurrent API calls is the primary lever for managing connection count on Vercel.

## Crossing Offers for Trade/Fill Test Data

To test endpoints that require actual trade data (`filled-orders`, `dex/trades`), you need crossing offers — two accounts placing opposite offers that match and execute:

1. Issuer (with `isIssuer:true` for DefaultRipple) + Trader A + Trader B
2. Trust lines: both traders -> issuer for the currency
3. Issue currency to Trader A (the seller)
4. Trader A places sell offer: `TakerGets=100 USD, TakerPays=50 XRP`
5. Trader B places crossing buy offer: `TakerGets=50 XRP, TakerPays=100 USD`

Step 5 auto-executes against step 4's resting offer, producing a fill visible to both `filled-orders` (per-account) and `dex/trades` (per-pair) endpoints.

Key: Trader B needs XRP (from faucet) but only needs a trust line (not a balance) for USD, since `TakerPays` only requires a trust line.

## xrpl.js Type Gaps (through v4.6.0)

Several fields returned by rippled are missing from xrpl.js TypeScript types:

| Response type | Missing field | Workaround |
|---|---|---|
| `AccountOffer` | `DomainID` | Cast: `offer as unknown as Record<string, unknown>` |
| `AccountTxTransaction` | `close_time_iso`, `date`, `hash` | Cast: `entry as unknown as Record<string, unknown>` |

`DomainID` IS typed on `Offer` (ledger entry) and `OfferCreate` (transaction) — just missing from the `account_offers` response model. `date` is available indirectly via `tx_json.date` (Ripple epoch number) through `ResponseOnlyTxInfo`, but `close_time_iso` (ISO 8601 string) isn't modeled anywhere on `AccountTxTransaction`.

## Currency Code Encoding Rules

XRPL currency codes follow two encoding rules:
- **Standard (3-char):** Passed through as-is — `"USD"` stays `"USD"`
- **Non-standard (>3 chars):** Hex-encoded and zero-padded to 40 chars — `"RLUSD"` becomes `"524C555344000000..."`

When writing tests that mock XRPL responses containing currency codes, use the **encoded** form that matches what the code under test produces.

## Define Typed Interfaces for XRPL Response Shapes

XRPL `account_tx` entries and similar responses arrive as loosely-typed objects. Rather than casting through `as Record<string, unknown>` at every access, define a local interface once and cast at the entry point:

```ts
interface AccountTxEntry {
  tx_json?: { TransactionType: string; Account: string; Fee?: string; hash?: string };
  meta?: TransactionMetadata | string;
  close_time_iso?: string;
}

const entry = rawEntry as AccountTxEntry;  // One cast at the boundary
```

Eliminates scattered inline casts and gives IDE autocomplete.

## Extract Fee Adjustment as a Pure Helper

XRPL balance changes include the transaction fee for the submitting account's XRP balance. When computing fill amounts, the fee must be subtracted — but only for XRP on the submitter's account. Extract as a pure function to avoid duplication:

```ts
function adjustForFee(value: number, currency: string, account: string, submitter: string, feeDrops: string): number {
  if (currency === "XRP" && account === submitter) {
    return value - parseFloat(feeDrops) / 1_000_000;
  }
  return value;
}
```

## TransactionMetadata Double Cast

xrpl.js `TransactionMetadataBase` types don't expose `AffectedNodes` with enough detail to extract created ledger objects. Direct casting fails because `Node` types lack string index signatures. Fix with double cast through `unknown`:

```ts
const nodes = (meta as unknown as {
  AffectedNodes: Array<Record<string, unknown>>;
}).AffectedNodes;

const created = nodes.find(
  (n) => "CreatedNode" in n &&
    (n.CreatedNode as Record<string, unknown>).LedgerEntryType === "PermissionedDomain",
);
```

## Credential Type Encoding != Currency Encoding

| | Credential Type | Currency Code |
|---|---|---|
| Encoding | Raw UTF-8 → hex | Padded to exactly 40 hex chars |
| Max length | 64 bytes | 20 bytes |
| Helper | `encodeCredentialType()` | `encodeXrplCurrency()` |

Using the wrong encoder produces valid-looking hex that silently fails on the ledger. Keep in separate utility files.
