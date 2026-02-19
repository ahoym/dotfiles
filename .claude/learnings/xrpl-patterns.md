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

## xrpl.js BookOffer Mixed Casing

xrpl.js `BookOffer` type uses **PascalCase** for main fields (`TakerGets`, `TakerPays`, `Account`, `Sequence`) but **snake_case** for funded fields (`taker_gets_funded`, `taker_pays_funded`). Easy to assume all fields follow the same convention — always check the type definition.

## account_offers vs account_objects for DomainID

`account_offers` returns **simplified** offer objects (snake_case fields: `seq`, `flags`, `taker_gets`, `taker_pays`, `quality`, `expiration`). It does **not** include `DomainID` even if the offer was placed in a permissioned domain.

To get full ledger entry fields including `DomainID`, use `account_objects` with `type: "offer"` instead. This returns PascalCase fields (`Sequence`, `Flags`, `TakerGets`, `TakerPays`, `DomainID`, etc.).

```typescript
// BAD — DomainID missing from response
client.request({ command: "account_offers", account: address });

// GOOD — full ledger entries with DomainID
client.request({ command: "account_objects", account: address, type: "offer" });
```

## Transaction Flags vs Ledger Entry Flags

XRPL transaction flags (`tf*`) and ledger entry flags (`lsf*`) use **different bit positions** for the same concept. When checking flags on ledger objects (from `account_objects`, `book_offers`), use `lsf*` values, not `tf*`.

| Flag | Transaction (`tf*`) | Ledger Entry (`lsf*`) |
|------|--------------------|-----------------------|
| Passive | `tfPassive = 0x00010000` | `lsfPassive = 0x00010000` |
| Sell | `tfSell = 0x00020000` | `lsfSell = 0x00020000` |
| **Hybrid** | **`tfHybrid = 0x00100000`** | **`lsfHybrid = 0x00040000`** |

Note that Passive and Sell happen to have the same values, but **Hybrid does not**. Always use the correct constant for the context.
