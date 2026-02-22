# XRPL Patterns

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

### Source reference

rippled `NetworkOPs.cpp` lines ~4177-4191:

```cpp
if (saOwnerFundsLimit >= saTakerGets)
{
    // Sufficient funds no shenanigans.
    saTakerGetsFunded = saTakerGets;
}
else
{
    // Only provide, if not fully funded.
    saTakerGetsFunded = saOwnerFundsLimit;
    saTakerGetsFunded.setJson(jvOffer[jss::taker_gets_funded]);
    std::min(saTakerPays, multiply(saTakerGetsFunded, saDirRate, saTakerPays.issue()))
        .setJson(jvOffer[jss::taker_pays_funded]);
}
```

## account_offers vs account_objects for DomainID

`account_offers` returns **simplified** offer objects (snake_case fields: `seq`, `flags`, `taker_gets`, `taker_pays`, `quality`, `expiration`). It does **not** include `DomainID` even if the offer was placed in a permissioned domain.

To get full ledger entry fields including `DomainID`, use `account_objects` with `type: "offer"` instead. This returns PascalCase fields (`Sequence`, `Flags`, `TakerGets`, `TakerPays`, `DomainID`, etc.).

```typescript
// BAD — DomainID missing from response
client.request({ command: "account_offers", account: address });

// GOOD — full ledger entries with DomainID
client.request({ command: "account_objects", account: address, type: "offer" });
```

## AMM: AMMCreate Fee Handled by xrpl.js Autofill

The `AMMCreate` transaction type has a special fee (higher than normal transactions) that xrpl.js handles automatically via `submitAndWait` / autofill. You do NOT need to manually calculate or set the `Fee` field — just omit it and let the library handle it.

## AMM: amm_info May Return Assets in Opposite Order

The XRPL `amm_info` response returns `asset` and `asset2` in the pool's canonical order, which may **not match** the order you queried with. If you query with `asset=XRP, asset2=USD`, the response might return `asset=USD, asset2=XRP`.

**You must normalize:** Compare the response's `asset`/`asset2` currencies against your query's base/quote currencies and swap if needed. This affects:
- Which reserve amount maps to base vs quote
- Spot price calculation (quote per unit base)
- Frozen flags (`asset_frozen` vs `asset2_frozen`)

```typescript
// Check if response order matches query order
const swapped = responseAsset.currency !== queriedBaseCurrency;
const baseReserve = swapped ? asset2Value : assetValue;
const quoteReserve = swapped ? assetValue : asset2Value;
const spotPrice = Number(quoteReserve) / Number(baseReserve);
```

**Discovered from:** Building the `/api/amm/info` route — without normalization, spot prices and reserve labels were inverted for certain currency pairs.

## Transaction Flags vs Ledger Entry Flags

XRPL transaction flags (`tf*`) and ledger entry flags (`lsf*`) use **different bit positions** for the same concept. When checking flags on ledger objects (from `account_objects`, `book_offers`), use `lsf*` values, not `tf*`.

| Flag | Transaction (`tf*`) | Ledger Entry (`lsf*`) |
|------|--------------------|-----------------------|
| Passive | `tfPassive = 0x00010000` | `lsfPassive = 0x00010000` |
| Sell | `tfSell = 0x00020000` | `lsfSell = 0x00020000` |
| **Hybrid** | **`tfHybrid = 0x00100000`** | **`lsfHybrid = 0x00040000`** |

Note that Passive and Sell happen to have the same values, but **Hybrid does not**. Always use the correct constant for the context.

## AMM: amm_info Error Message Variants for Non-Existent Pools

When querying `amm_info` for a pool that doesn't exist, xrpl.js throws errors with different messages depending on the situation:

| Scenario | Error message contains |
|----------|----------------------|
| No AMM pool for this pair | `"actNotFound"` |
| No AMM pool (alternate) | `"ammNotFound"` |
| Account doesn't exist on network | `"Account not found"` |

Catch all three variants to return `{ exists: false }` instead of a 500:

```typescript
const msg = err instanceof Error ? err.message : String(err);
if (msg.includes("actNotFound") || msg.includes("ammNotFound") || msg.includes("Account not found")) {
  return Response.json({ exists: false });
}
```

The `"Account not found"` case occurs when the queried issuer account doesn't exist on the target network (e.g., devnet account queried on testnet).

## xrpl.js Validation Helpers

xrpl.js v4.5.0 provides built-in validation helpers:

- **`isValidClassicAddress(address)`** — validates well-formed XRP Ledger classic address
- **`isValidSeed(seed)`** — validates well-formed XRPL wallet seed

Always validate inputs before using them in XRPL operations. Even with `isValidSeed()` pre-validation, wrap `Wallet.fromSeed()` in a try-catch as defense-in-depth — the validation function checks format, but edge cases could still cause exceptions.

## Issuer Burn Mechanics: No Trust Line Required

Sending issued currency back to the issuer does NOT require a trust line on the issuer's side. The issuer implicitly accepts their own IOUs, effectively "burning" or redeeming tokens. Only non-issuer accounts need trust lines.

- Any holder can send tokens back to the issuer at any time
- The issuer's balance is always negative (outstanding IOUs); receiving tokens reduces that
- No `TrustSet` transaction needed on the issuer's account

**Transfer UI:** When a transfer recipient is the issuer of the currency, skip the trust line validation check and set `trustLineOk = true`. Use a derived `isBurn = destinationAddress === selectedBalance?.issuer` flag to drive both the validation skip and a UI warning explaining the tokens will be destroyed.

### Accurate Order Book Display Pattern

When displaying order book data, use `taker_gets_funded ?? taker_gets` (and same for pays) for actual fillable size. Filter where BOTH `amount > 0` AND `price > 0` — filtering only on amount misses the case where `taker_pays_funded` is `"0"` (producing a 0-price row with positive amount).

## client.getOrderbook() Internals

`client.getOrderbook()` always makes **two** internal `book_offers` RPC calls (one per direction: bids and asks), then separates the results into `buy` and `sell` arrays via `separateBuySellOrders()`.

Key implications:

- **There is no option to request only one side.** Even if you only need bids, the client will still fetch both directions.
- **Client-side filtering** (e.g., slicing the returned arrays to limit depth) only saves payload size and rendering cost — it does **not** reduce XRPL WebSocket/connection load.
- Each `getOrderbook()` call = 2 RPC round trips over the WebSocket, regardless of how the results are consumed.

This is relevant when optimizing polling intervals or combining API calls to reduce connection pressure on XRPL public nodes.

## account_offers Does Not Return Transaction Hashes

The XRPL `account_offers` command only returns these fields per offer:
- `seq` (offer sequence number)
- `flags`
- `taker_gets`
- `taker_pays`
- `quality`
- `expiration` (optional)

**No transaction hash is included.** To get the hash of the transaction that created an offer, you must cross-reference `account_tx` results, filtering for `OfferCreate` transactions and matching by sequence number. This requires an additional API call and matching logic, adding network overhead.

## getBalanceChanges() Already Includes Fee Deduction

`getBalanceChanges()` from xrpl.js returns XRP balance deltas that are **already net of transaction fees**. The `AccountRoot` ledger entry in transaction metadata reflects the fee deduction in its `FinalFields.Balance` vs `PreviousFields.Balance`.

**Implication:** Explicitly subtracting `tx.Fee` from `getBalanceChanges()` output **double-counts** the fee. Use the raw delta as-is for accurate trade amounts.

**Example:** If a wallet receives 100 XRP from a trade and pays 12 drops fee:
- `getBalanceChanges()` returns: +99.999988 XRP (correct, net of fee)
- Subtracting `tx.Fee` again: +99.999976 XRP (wrong, double-deducted)

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

On Vercel, each API route can run as a **separate serverless function instance**, and each instance opens its own WebSocket connection to the XRPL node (via the singleton in `lib/xrpl/client.ts` — but the singleton is per-process, not per-deployment).

**The Problem:** XRPL public nodes enforce **IP-based connection limits**. When the client polls multiple API routes simultaneously (e.g., orderbook + trades + balances), each route may spawn a separate serverless invocation, each opening its own WebSocket.

**The Mitigation:** Combine multiple XRPL queries into a **single API route** (e.g., a `/api/dex/market-data` endpoint) to reduce the number of concurrent serverless invocations and WebSocket connections.

**Key Takeaway:** The `lib/xrpl/client.ts` singleton only helps within a single serverless invocation. Across concurrent invocations, each process gets its own singleton instance. Reducing the number of concurrent API calls is the primary lever for managing connection count on Vercel.
