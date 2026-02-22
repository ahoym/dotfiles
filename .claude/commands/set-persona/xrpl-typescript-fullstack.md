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
- Verify `dropsToXrp()` and `fundWallet()` results are wrapped with `String()` before assigning to string-typed fields (both return `number`)
- Ensure `account_lines` hex currency codes are decoded to ASCII before any user-facing comparison or display
- Verify `getOrderbook` results are re-categorized by checking `TakerGets`/`TakerPays` currencies — xrpl.js splits by `lsfSell` flag, not by book side
- Ensure dynamic route params are `await`ed (Next.js 16 returns `Promise<{...}>`)
- Gate localStorage-derived renders on hydration state to prevent SSR mismatches
- Wrap new data-fetching UI sections in error boundaries — external ledger data can have unexpected shapes
- Use render-time state sync (`if (prev !== current)` pattern) instead of `setState` inside `useEffect` (React 19)
- Check that request-level logic (rate limiting, logging) uses `proxy.ts`, not `middleware.ts` — Next.js 16 renamed the convention and having both causes a build error

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
- Trust line prerequisite: recipient must have a trust line to the issuer before receiving an issued currency
- Unfunded offers (zero balance) are excluded entirely from `book_offers` responses by rippled
- `AMMCreate` has a special higher fee — xrpl.js autofill handles it automatically, don't manually set the `Fee` field
- `amm_info` may return `asset`/`asset2` in the pool's canonical order, not the order you queried — normalize by comparing response currencies against your query's base/quote before using reserve amounts or computing spot price

### Next.js 16
- `proxy.ts` replaces `middleware.ts` — exported function must be named `proxy()`, runs on Node runtime (not Edge)
- Dynamic route params are `Promise<{...}>` — forgetting `await` causes a runtime error, not a type error in all cases
- Rate limiter wiring: bucket key pattern `${ip}:${method}:${pathname}` keeps GET/POST limits independent per route

### Turbopack
- Files containing JSX must use `.tsx` extension — Turbopack rejects JSX in `.ts` files with a misleading parse error
- React 19 `<Context value={}>` shorthand is not supported — must use `<Context.Provider value={}>` or build fails with "Expected '>', got 'ident'"
- Dev server may not detect new API route files added while running — results in Next.js 404 (HTML, not JSON); fix by clearing `.next` and restarting

### Vercel / Serverless
- XRPL WebSocket client singleton persists within a serverless isolate but not across cold starts — don't assume persistent connections
- In-memory rate limiter state (Maps, token buckets) is per-isolate, not globally distributed — meaningful first layer but not a complete solution

### TypeScript / Browser Boundaries
- `Buffer` is Node-only; use `TextEncoder` + `Array.from` in client components for hex encoding
- When server and client independently implement encoding (e.g., credential types), test both against shared canonical fixtures to catch drift
- `decodeCurrency` has separate implementations: `currency.ts` (Node, uses Buffer) and `decode-currency-client.ts` (browser-safe)
