# React Frontend Focus

## Domain priorities
- Component architecture: clear state ownership, thin orchestrators, sub-components that own their own action state
- React 19 idioms: render-time state sync over useEffect, lazy initializers, no synchronous setState in effects
- SSR/hydration safety: gate client-only renders on hydration state, never trust `suppressHydrationWarning` as a fix
- Accessibility by default: semantic HTML first, ARIA only when native semantics can't express the interaction, keyboard navigation for all interactive elements
- Testing strategy: assert side effects over transient UI state, scope selectors to containers, role-based over text-based locators
- Design system discipline: centralize tokens before component-level changes, extract abstractions only when a second consumer appears
- Code quality: apply `~/.claude/learnings/code-quality-instincts.md` principles throughout (no duplication, single source of truth, port intent not idioms)

## When reviewing or writing code
- Flag any `setState` called synchronously inside `useEffect` — use lazy `useState` initializers for hydration/init, render-time sync (`if (prev !== current)` pattern) for prop changes
- Verify localStorage-derived renders are gated on a hydration flag — prevents SSR mismatches AND flash of wrong values
- When extracting custom hooks, pass primitive values (strings, IDs) not resolved objects — avoids circular dependencies when the hook both produces and consumes derived state
- Modals should handle form input only — lift execution state to the parent so modals close immediately and the parent drives the async operation
- For pages over ~200 lines, look for decomposition: slim orchestrator + sub-components + shared hooks. But don't extract sub-components under 50 lines or hooks with only one consumer
- Before abstracting a "repeated pattern" across N components, audit every consumer's actual usage — two focused tiers covering 6/8 cases beats one over-generalized wrapper for 8/8
- Verify interactive non-button elements have the full trio: `role="button"` + `tabIndex={0}` + `onKeyDown` — missing any one breaks keyboard or screen reader access
- Run the accessibility checklist: `aria-current` on active nav links, `aria-expanded` on collapsibles, `aria-pressed` on toggles, `aria-label` on icon-only buttons, `type="button"` on non-submit buttons
- In Playwright tests: assert side effects (list count changes, form resets) rather than transient success banners; use `exact: true` for short button names; scope selectors to containers with `.locator()`

## When making tradeoffs
- Semantic HTML over ARIA — prefer `<button>` over `<div role="button">`, reach for ARIA only when native semantics don't express the interaction
- Side-effect assertions over UI-state assertions in tests — data changing is more reliable than a toast appearing
- Design tokens over per-component styling — upfront centralization cost compounds as the system grows
- Composition over premature abstraction — three similar lines is better than a shared helper with one caller

## Known gotchas & platform specifics

### Next.js 16 / Turbopack
- Platform gotchas (proxy.ts rename, async dynamic params, Turbopack build requirements) — see `~/.claude/learnings/frontend/nextjs.md`

## Proactive loads

- `~/.claude/learnings/frontend/react-frontend-gotchas.md`

## Cross-Refs

These learning files contain full recipes, code examples, and edge cases for each sub-domain. Load when working in the specific area:

- `~/.claude/learnings/code-quality-instincts.md` — Universal code quality instincts (no duplication, single source of truth, port intent)
- `~/.claude/learnings/frontend/react-state-effects.md` — React 19 setState rules, hydration gating, lazy initializers, per-environment state
- `~/.claude/learnings/frontend/react-hooks-and-ui.md` — Hook extraction, two-tier design, modals, polling, page decomposition
- `~/.claude/learnings/reactive-data-patterns.md` — Reactive refresh, client-side expiration tracking, silent fetch pattern
- `~/.claude/learnings/frontend/nextjs.md` — Next.js 16 proxy.ts, dynamic params, Turbopack gotchas, rate limiter wiring
- `~/.claude/learnings/frontend/accessibility-patterns.md` — ARIA attribute patterns with code examples
- `~/.claude/learnings/frontend/ui-patterns.md` — Tailwind tooltips, SVG gotchas, design token centralization
- `~/.claude/learnings/testing/testing-patterns.md` — Vitest/RTL stack, vi.mock hoisting, route handler test patterns, shared test helpers, jsdom gotchas
- `~/.claude/learnings/testing/playwright-patterns.md` — 17 testing patterns covering selectors, state, modals, assertions
