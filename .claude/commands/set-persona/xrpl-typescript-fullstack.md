# XRPL TypeScript Fullstack Focus

## Domain priorities
- XRPL integration: correct transaction construction, flag usage, funded offer semantics, currency hex encoding, trust line prerequisites
- API design: consistent response shapes (always include nullable fields), proper HTTP semantics, input validation at system boundaries
- React/Next.js patterns: SSR hydration safety, error boundary isolation for data-driven sections, React 19 idioms
- TypeScript rigor: leverage the type system to catch XRPL field casing mismatches and encoding boundary issues
- Wallet security: secrets stay client-side, prefer wallet adapter integrations over raw seed handling
- Vercel/serverless awareness: design around stateless function invocations, WebSocket singleton lifetime, cold start implications

## When reviewing or writing code
- Flag any XRPL code using `tf*` flags on ledger objects — must use `lsf*` equivalents (bit positions differ, e.g. `tfHybrid = 0x00100000` vs `lsfHybrid = 0x00040000`)
- Check that `taker_gets_funded ?? TakerGets` fallback is used for book offers — absence of funded fields means fully funded, not missing data
- Watch for `account_offers` when `DomainID` or full ledger fields are needed — use `account_objects` with `type: "offer"` instead
- Validate addresses with `isValidClassicAddress()` and seeds with `isValidSeed()` before XRPL operations; still wrap `Wallet.fromSeed()` in try-catch as defense-in-depth
- For order book display, use `taker_gets_funded ?? taker_gets` AND filter where BOTH amount > 0 AND price > 0 — filtering only on amount misses zero-price rows from `taker_pays_funded: "0"`
- Verify `dropsToXrp()` and `fundWallet()` results are wrapped with `String()` before assigning to string-typed fields (both return `number`)
- Ensure `account_lines` hex currency codes are decoded to ASCII before any user-facing comparison or display
- Verify `getOrderbook` results are re-categorized by checking `TakerGets`/`TakerPays` currencies — xrpl.js splits by `lsfSell` flag, not by book side
- Verify all financial arithmetic uses `BigNumber.js` — never use `parseFloat()` or native operators (`+`, `-`, `*`, `/`) on prices, amounts, totals, or spreads
- Wrap new data-fetching UI sections in error boundaries — external ledger data can have unexpected shapes

## Code style

Enforce `learnings/code-quality-instincts.md` (no duplication, single source of truth, port intent not idioms).

TypeScript-specific:
- Prefer named functions over IIFEs (`(() => { ... })()`) — if logic needs a block, extract a helper
- Avoid `as` casts — fix the type mismatch at the source (widen the source type, narrow the producer's return type, or add a type guard)

## When making tradeoffs
- Correctness over convenience — XRPL transactions are irreversible, validate thoroughly before signing
- Wallet adapters over raw seeds for any production path — localStorage encryption has marginal ROI when adapters exist
- Explicit over magical — prefer direct XRPL client calls over abstractions that hide transaction semantics
- Server/client parity — when both sides encode the same value (currency codes, credentials), test against shared fixtures
- Minimal secrets exposure — sign server-side when possible, never persist seeds longer than needed
- Export encryption over storage encryption — exported files leave the browser security boundary, localStorage is at least origin-scoped

## Known gotchas & platform specifics

### XRPL
- `TakerGets` = what the offer creator is selling; `TakerPays` = what they want in return (naming is from the taker's perspective, not the creator's)
- OfferCreate requires the creator to hold `TakerGets` funds, but only needs a trust line (no balance) for `TakerPays`
- `BookOffer` uses PascalCase for main fields (`TakerGets`, `Account`) but snake_case for funded fields (`taker_gets_funded`) — don't assume uniform casing
- Trust line prerequisite: recipient must have a trust line to the issuer before receiving an issued currency — EXCEPT sending back to the issuer (burn), which requires no trust line
- URI XSS from ledger-stored credential URIs: validate protocol (`/^https?:\/\//i`) before rendering as `<a href>` — `javascript:` payloads in on-ledger data are a stored XSS vector
- Unfunded offers (zero balance) are excluded entirely from `book_offers` responses by rippled
- `AMMCreate` has a special higher fee — xrpl.js autofill handles it automatically, don't manually set the `Fee` field
- `amm_info` may return `asset`/`asset2` in the pool's canonical order, not the order you queried — normalize by comparing response currencies against your query's base/quote before using reserve amounts or computing spot price
- `amm_info` for non-existent pools throws `"actNotFound"`, `"ammNotFound"`, or `"Account not found"` (issuer doesn't exist on network) — catch all three to return `{ exists: false }` instead of a 500
- `client.getOrderbook()` always makes 2 RPC calls (both book directions) — no option to request only one side; client-side array slicing saves rendering cost but not WebSocket load
- `account_offers` does not return transaction hashes — cross-reference `account_tx` filtering for `OfferCreate` and match by sequence number
- `getBalanceChanges()` returns XRP deltas already net of fees — don't subtract `tx.Fee` again (double-counts the deduction)
- `RippleState` balance sign: positive = low account holds the IOU, negative = high account — common mistake is assuming positive means "your" side
- Detecting fills from `account_tx`: 6-step algorithm parsing `AffectedNodes` for balance changes — see `xrpl-patterns.md` "Detecting Filled Orders from account_tx" for recipe

### Next.js 16 / Turbopack
- Platform gotchas (proxy.ts rename, async dynamic params, Turbopack build requirements, rate limiter wiring) — see `learnings/nextjs.md`

### Vercel / Serverless
- XRPL WebSocket client singleton persists within a serverless isolate but not across cold starts — don't assume persistent connections
- In-memory rate limiter state (Maps, token buckets) is per-isolate, not globally distributed — meaningful first layer but not a complete solution

### TypeScript / Browser Boundaries
- `Buffer` is Node-only; use `TextEncoder` + `Array.from` in client components for hex encoding
- When server and client independently implement encoding (e.g., credential types), test both against shared canonical fixtures to catch drift
- XRPL currency code decoding (hex ↔ ASCII) requires separate server-side (Node, `Buffer`) and browser-safe implementations — keep in distinct files to avoid Node API bundling into client code

## Detailed references

Load when working in the specific area:
- `learnings/react-patterns.md` — React 19 patterns (setState/useEffect, hydration gating, hook extraction, component decomposition)
- `learnings/nextjs.md` — Next.js 16 proxy.ts, dynamic params, Turbopack gotchas, rate limiter wiring
- `learnings/xrpl-patterns.md` — Orderbook semantics, funded offers, RippleState, fills detection, crossing offers for testing
- `learnings/xrpl-amm.md` — AMM constant-product formulas, CLOB+AMM interleaved fill estimation
- `learnings/xrpl-dex-data.md` — OnTheDEX API endpoints, OHLC/ticker response shapes
- `learnings/xrpl-permissioned-domains.md` — XLS-70/80/81 permissioned domains, credentials, permissioned DEX
- `learnings/bignumber-financial-arithmetic.md` — BigNumber.js rules for financial arithmetic, comparison traps, display rounding
- `learnings/order-book-pricing.md` — Mid-price approaches, slippage estimation, midprice module design
- `learnings/api-design.md` — Consistent response shapes, DRY validation, security hardening, contract audit approach
