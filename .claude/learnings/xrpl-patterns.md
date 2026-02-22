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
