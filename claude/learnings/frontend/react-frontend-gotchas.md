Companion to `react-patterns.md`. Tripwires for React 19, Next.js/Turbopack, and Playwright.
- **Keywords:** React 19, setState, useEffect, hydration, suppressHydrationWarning, Next.js 16, Turbopack, proxy.ts, dynamic route params, Playwright, getByRole, aria-label, .first()
- **Related:** ~/.claude/learnings/playwright-patterns.md

---

## React 19

- `setState` inside `useEffect` triggers lint errors — fix depends on case: lazy initializer (hydration/init), render-time sync (prop changes), or async callbacks (fetches)
- `suppressHydrationWarning` hides the warning but user still sees a flash of wrong value — gate rendering on hydration state instead
- Data-fetching effects: move synchronous `setLoading(true)` to render-time via prev-key pattern; only async callbacks belong in the effect body

## Next.js 16 / Turbopack

- `proxy.ts` replaces `middleware.ts` — exported function must be named `proxy()`, runs on Node runtime (not Edge)
- Dynamic route params are `Promise<{...}>` — forgetting `await` causes runtime error, not always a type error
- Rate limiter wiring: bucket key pattern `${ip}:${method}:${pathname}` keeps GET/POST limits independent per route
- JSX must be in `.tsx` files — Turbopack rejects JSX in `.ts` with a misleading parse error
- React 19 `<Context value={}>` shorthand not supported — must use `<Context.Provider value={}>` or build fails
- Dev server may not detect new API route files added while running — clear `.next` and restart

## Playwright

- `getByRole` matches accessible name (`aria-label`) over visible text — if aria-label differs from button text, `getByRole` uses the label
- `textContent` on containers concatenates all child text without separators — use role-based selectors instead
- `.first()` is dynamic: after removing first match, resolves to next — use count-based assertions for removal tests
- `page.on("dialog")` stacks handlers across serial tests on shared page — use `page.once()` for one-time handling
- Transient success banners (auto-clear after N seconds) are unreliable assertions — assert the side effect instead

## Cross-Refs

- `~/.claude/learnings/playwright-patterns.md` — full Playwright patterns (getByRole, dialog handlers, .first())
