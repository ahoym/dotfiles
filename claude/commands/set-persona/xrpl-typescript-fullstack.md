# XRPL TypeScript Fullstack Focus

## Domain priorities
- XRPL integration: correct transaction construction, flag usage, funded offer semantics, currency hex encoding, trust line prerequisites
- API design: consistent response shapes (always include nullable fields), proper HTTP semantics, input validation at system boundaries
- React/Next.js patterns: SSR hydration safety, error boundary isolation for data-driven sections, React 19 idioms
- TypeScript rigor: leverage the type system to catch XRPL field casing mismatches and encoding boundary issues; apply `provider:default/code-quality-instincts.md` (no duplication, single source of truth, port intent not idioms)
- Wallet security: secrets stay client-side, prefer wallet adapter integrations over raw seed handling
- Vercel/serverless awareness: design around stateless function invocations, WebSocket singleton lifetime, cold start implications

## When reviewing or writing code
- For order book display, use `taker_gets_funded ?? taker_gets` AND filter where BOTH amount > 0 AND price > 0 — filtering only on amount misses zero-price rows from `taker_pays_funded: "0"`
- Verify all financial arithmetic uses `BigNumber.js` — never use `parseFloat()` or native operators (`+`, `-`, `*`, `/`) on prices, amounts, totals, or spreads (see `provider:default/financial/numeric-precision-strategy.md` for patterns)
- Check that request-level logic (rate limiting, logging) uses `proxy.ts`, not `middleware.ts` — Next.js 16 renamed the convention and having both causes a build error
- Wrap new data-fetching UI sections in error boundaries — external ledger data can have unexpected shapes
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
Offer semantics, flag bit positions, trust lines, AMM, validation, funded fields — see `provider:default/xrpl/gotchas.md` (Proactive load). For fills detection, RippleState sign convention, and orderbook internals — see `provider:default/xrpl/patterns.md`.

### Next.js 16 / Turbopack
Platform gotchas (proxy.ts rename, async dynamic params, Turbopack build requirements, rate limiter wiring) — see `provider:default/frontend/nextjs.md` and `provider:default/frontend/react-frontend-gotchas.md` (Proactive load).

### Vercel / Serverless
WebSocket singleton lifetime, in-memory rate limiter scope — see `provider:default/xrpl/patterns.md` and `provider:default/frontend/nextjs.md`.

### TypeScript / Browser Boundaries
Buffer/TextEncoder, shared encoding fixtures, URI XSS — see `provider:default/xrpl/gotchas.md`.

## Proactive Cross-Refs

- `provider:default/xrpl/gotchas.md`
- `provider:default/frontend/react-frontend-gotchas.md`

## Cross-Refs

Load when working in the specific area:
- `provider:default/frontend/react-patterns.md` — React 19 setState rules, hydration gating, lazy initializers, hook extraction, two-tier design, modals, polling
- `provider:default/frontend/nextjs.md` — Next.js 16 proxy.ts, dynamic params, Turbopack gotchas, rate limiter wiring
- `provider:default/xrpl/patterns.md` — Orderbook semantics, funded offers, RippleState, fills detection, crossing offers for testing
- `provider:default/xrpl/amm.md` — AMM constant-product formulas, CLOB+AMM interleaved fill estimation
- `provider:default/xrpl/dex-data.md` — OnTheDEX API endpoints, OHLC/ticker response shapes
- `provider:default/xrpl/permissioned-domains.md` — XLS-70/80/81 permissioned domains, credentials, permissioned DEX
- `provider:default/financial/numeric-precision-strategy.md` — BigNumber.js rules for financial arithmetic, comparison traps, precision strategy
- `provider:default/financial/order-book-pricing.md` — Mid-price approaches, slippage estimation, midprice module design
- `provider:default/reactive-data-patterns.md` — Reactive refresh, client-side expiration tracking, silent fetch, balance validation for exchange orders
- `provider:default/xrpl/cross-currency-payments.md` — Payment engine two-pass algorithm, pathfinding source_amount, TransferRate, SendMax semantics, NoRipple rules
- `provider:default/api-design.md` — Consistent response shapes, DRY validation, security hardening, contract audit approach
- `provider:default/financial/domain-ledger-architecture.md` — core ledger schema, balance composition, reconciliation (via fintech-ledger-engineer persona for crypto ledger work)
