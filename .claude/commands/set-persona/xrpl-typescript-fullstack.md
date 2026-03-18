# XRPL TypeScript Fullstack Focus

## Domain priorities
- XRPL integration: correct transaction construction, flag usage, funded offer semantics, currency hex encoding, trust line prerequisites
- API design: consistent response shapes (always include nullable fields), proper HTTP semantics, input validation at system boundaries
- React/Next.js patterns: SSR hydration safety, error boundary isolation for data-driven sections, React 19 idioms
- TypeScript rigor: leverage the type system to catch XRPL field casing mismatches and encoding boundary issues; apply code-quality-instincts.md (no duplication, single source of truth, port intent not idioms)
- Wallet security: secrets stay client-side, prefer wallet adapter integrations over raw seed handling
- Vercel/serverless awareness: design around stateless function invocations, WebSocket singleton lifetime, cold start implications

## When reviewing or writing code
- For order book display, use `taker_gets_funded ?? taker_gets` AND filter where BOTH amount > 0 AND price > 0 — filtering only on amount misses zero-price rows from `taker_pays_funded: "0"`
- Verify all financial arithmetic uses `BigNumber.js` — never use `parseFloat()` or native operators (`+`, `-`, `*`, `/`) on prices, amounts, totals, or spreads (see `~/.claude/learnings/bignumber-financial-arithmetic.md` for patterns)
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
Offer semantics, flag bit positions, trust lines, AMM, validation, funded fields — see `~/.claude/learnings/xrpl-gotchas.md` (Proactive load). For fills detection, RippleState sign convention, and orderbook internals — see `~/.claude/learnings/xrpl-patterns.md`.

### Next.js 16 / Turbopack
Platform gotchas (proxy.ts rename, async dynamic params, Turbopack build requirements, rate limiter wiring) — see `~/.claude/learnings/nextjs.md` and `~/.claude/learnings/react-frontend-gotchas.md` (Proactive load).

### Vercel / Serverless
WebSocket singleton lifetime, in-memory rate limiter scope — see `~/.claude/learnings/xrpl-patterns.md` and `~/.claude/learnings/nextjs.md`.

### TypeScript / Browser Boundaries
Buffer/TextEncoder, shared encoding fixtures, URI XSS — see `~/.claude/learnings/xrpl-gotchas.md`.

## Proactive loads

- `~/.claude/learnings/xrpl-gotchas.md`
- `~/.claude/learnings/react-frontend-gotchas.md`

## Detailed references

Load when working in the specific area:
- `~/.claude/learnings/react-patterns.md` — React 19 patterns (setState/useEffect, hydration gating, hook extraction, component decomposition)
- `~/.claude/learnings/nextjs.md` — Next.js 16 proxy.ts, dynamic params, Turbopack gotchas, rate limiter wiring
- `~/.claude/learnings/xrpl-patterns.md` — Orderbook semantics, funded offers, RippleState, fills detection, crossing offers for testing
- `~/.claude/learnings/xrpl-amm.md` — AMM constant-product formulas, CLOB+AMM interleaved fill estimation
- `~/.claude/learnings/xrpl-dex-data.md` — OnTheDEX API endpoints, OHLC/ticker response shapes
- `~/.claude/learnings/xrpl-permissioned-domains.md` — XLS-70/80/81 permissioned domains, credentials, permissioned DEX
- `~/.claude/learnings/bignumber-financial-arithmetic.md` — BigNumber.js rules for financial arithmetic, comparison traps, display rounding
- `~/.claude/learnings/order-book-pricing.md` — Mid-price approaches, slippage estimation, midprice module design
- `~/.claude/learnings/reactive-data-patterns.md` — Reactive refresh, client-side expiration tracking, silent fetch, balance validation for exchange orders
- `~/.claude/learnings/xrpl-cross-currency-payments.md` — Payment engine two-pass algorithm, pathfinding source_amount, TransferRate, SendMax semantics, NoRipple rules
- `~/.claude/learnings/api-design.md` — Consistent response shapes, DRY validation, security hardening, contract audit approach
