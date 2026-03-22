# XRPL Gotchas

Condensed tripwires for XRPL integration: offer semantics, flag conventions, trust lines, AMM edge cases, and TypeScript boundaries.
**Keywords:** TakerGets, TakerPays, taker_gets_funded, lsfSell, RippleState, getBalanceChanges, hex currency, AMMCreate fee, isValidClassicAddress, Buffer, TextEncoder
**Related:** xrpl-patterns.md, bignumber-financial-arithmetic.md

---

## Offer & Book Semantics

- `TakerGets` = what the offer creator is selling; `TakerPays` = what they want (naming is from taker's perspective)
- OfferCreate requires creator to hold `TakerGets` funds but only needs a trust line (no balance) for `TakerPays`
- `BookOffer` uses PascalCase for main fields but snake_case for funded fields (`taker_gets_funded`) — don't assume uniform casing
- `taker_gets_funded ?? TakerGets` — absence of funded fields means fully funded, not missing data; filter where BOTH amount > 0 AND price > 0
- Unfunded offers (zero balance) excluded entirely from `book_offers` responses by rippled
- `getOrderbook` results must be re-categorized by checking currencies — xrpl.js splits by `lsfSell` flag, not book side
- `client.getOrderbook()` always makes 2 RPC calls (both directions) — no single-side option
- `account_offers` lacks transaction hashes — cross-reference `account_tx` for `OfferCreate`, match by sequence number
- Use `account_objects` with `type: "offer"` when `DomainID` or full ledger fields are needed — `account_offers` omits them

## Flags & Fields

- `tf*` flags are for transactions, `lsf*` for ledger objects — bit positions differ (e.g., `tfHybrid = 0x00100000` vs `lsfHybrid = 0x00040000`)
- `RippleState` balance sign: positive = low account holds the IOU, negative = high account
- `getBalanceChanges()` returns XRP deltas already net of fees — don't subtract `tx.Fee` again

## Trust Lines & Currencies

- Trust line prerequisite: recipient needs trust line to issuer before receiving — EXCEPT sending back to issuer (burn)
- `account_lines` hex currency codes must be decoded to ASCII before user-facing comparison or display

## AMM

- `AMMCreate` has special higher fee — xrpl.js autofill handles it, don't manually set `Fee`
- `amm_info` may return assets in pool's canonical order, not query order — normalize by comparing against your base/quote
- `amm_info` for non-existent pools throws `actNotFound`, `ammNotFound`, or `Account not found` — catch all three

## Validation

- Validate addresses with `isValidClassicAddress()` and seeds with `isValidSeed()` before operations; still wrap `Wallet.fromSeed()` in try-catch
- `dropsToXrp()` and `fundWallet()` return `number` — wrap with `String()` before assigning to string-typed fields

## TypeScript / Browser Boundaries

- `Buffer` is Node-only — use `TextEncoder` + `Array.from` in client components for hex encoding
- Server and client encoding implementations (e.g., credential types) must be tested against shared canonical fixtures
- URI XSS from ledger-stored credential URIs: validate protocol (`/^https?:\/\//i`) before rendering as `<a href>`

## Cross-Refs

- `xrpl-patterns.md` — full XRPL integration patterns (companion)
- `bignumber-financial-arithmetic.md` — BigNumber.js patterns for XRPL financial calculations
