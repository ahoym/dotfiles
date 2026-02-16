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

## bignumber.js Not Transitive in pnpm

Even though `xrpl` uses `bignumber.js` internally, pnpm's strict dependency isolation means it's **not importable** from your project unless explicitly installed as a direct dependency (`pnpm add bignumber.js`). This differs from npm's flat `node_modules` behavior where transitive deps are hoisted and importable.

## BigNumber `comparedTo()` Returns `number | null`

BigNumber.js `comparedTo()` returns `number | null` (null when comparing NaN). When used in `Array.sort()` callbacks, TypeScript rejects it because sort expects `(a, b) => number`. Fix: append `?? 0`:

```typescript
asks.sort((a, b) => b.price.comparedTo(a.price) ?? 0);
```
