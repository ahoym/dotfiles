# Refactoring Guidelines

## Survey Before Acting

Before proposing any refactoring changes, do a full survey:

1. **Count instances** — grep for the pattern across the codebase, not just spot-check. You'll often find more instances than initially visible.
2. **Categorize variants** — not all instances of a "similar" pattern are identical. An audit may reveal distinct variants where only one is worth extracting.
3. **Check existing abstractions** — before creating a new hook/component, verify one doesn't already exist.
4. **Size the work** — count files touched, lines changed, and test coverage gaps before committing.

## Commit Granularity for Refactoring

One logical unit per commit — the new abstraction + all its consumers + its tests belong together. This makes each commit independently reviewable and revertable.

| Good | Bad |
|---|---|
| "Extract useFormSubmit hook and refactor 7 components" | "Create use-form-submit.ts" then "Update component-a" then "Update component-b" ... |

## When to Use a Factory vs Individual Hooks

**Use a factory** when 3+ hooks follow an identical pattern with only 1-2 parameters varying and have no extra logic beyond what the factory provides.

**Keep individual hooks** when the hook has extra parameters, custom logic beyond fetch-and-extract, or only 1-2 instances exist (wait for a third before abstracting).

## Assess Before Adding React Context

Before replacing prop drilling with React Context, measure these three factors:

1. **Drilling depth** — 2 levels is acceptable and common; Context adds value at 3+
2. **Consumer count** — under 5 consumers doesn't justify the abstraction overhead
3. **Update frequency** — if the Context holds polling data that updates on different schedules (e.g., orderbook every 3s, balances every 3s, orders on events), every consumer re-renders on every tick even if they only need one field

For monolithic data objects with mixed update frequencies, prop drilling with scoped props is often **better** than Context. Splitting into multiple Contexts to fix re-render issues adds more complexity than the prop drilling it replaces.

## Split PRs by Risk Profile

Split PRs by **risk and reviewability**, not by batch or phase boundaries:

- **Bug fixes that change observable behavior** get their own PR, separate from pure test additions — even if they're in the same implementation batch
- **Pure refactors** (module splits, extractions) can be grouped if they touch independent areas
- **New shared abstractions** (hooks, utilities) get their own PR so the API can be reviewed before adoption

This gives reviewers focused diffs and produces cleaner git history for bisecting.

## Parallel Batch Failure Handling

When one of several parallel agents fails (tests break, refactor is more complex than expected):
1. **Let successful agents merge** — don't block the entire batch on one failure
2. **Re-attempt the failed agent** from the merged state of successful work
3. The re-attempted agent gets a fresh worktree branched from the updated base

This minimizes wasted work and keeps the batch moving forward.

## Gate Strategy: Unit Tests + Selective E2E

- **Every batch:** gate with build + unit tests (type check + fast tests)
- **Behavior-changing PRs only:** also run E2E tests
- **Pure refactors and test additions:** skip E2E — they add latency without catching new regressions

E2E tests are slow (network calls, browser launches, external dependencies). Reserve them for PRs where user-visible behavior changes.

## Phased Refactoring Approach

When refactoring a codebase, organize work into three phases:

### Phase 1 — Quick DRY wins (low risk)

Extract shared helpers, deduplicate functions, fix inconsistencies, standardize patterns. These are mechanical, safe changes.

### Phase 2 — Test coverage (medium risk)

Add tests for critical pure functions and business logic. The Phase 1 cleanup reduces surface area, making test targets clearer. Focus on untested modules with complex logic (parsers, validators, algorithms).

### Phase 3 — Structural refactors (higher risk)

Decompose large functions/hooks, consolidate overlapping types, extract shared utilities. Tests from Phase 2 provide a safety net.

**Why this ordering matters:**
- Phase 1 makes the code easier to test.
- Phase 2 makes structural changes safer.

## Fix Bugs Structurally Through Refactoring

When a refactoring plan includes both "add tests" and "split/extract" phases, use them together strategically:

1. **Test phase:** Identify bugs, write tests that expose them, document the root cause
2. **Split phase:** Design the extracted module so its API naturally prevents the bug class

**Example — resource leak in a monolithic module:**
- Phase 1: Documented that the module managing timers didn't clean up old timers when inputs changed
- Phase 2: Extracted a dedicated module that owns its own lifecycle cleanup. The leak is impossible by construction.
- Phase 1 tests verify the Phase 2 fix without a separate "fix" commit

**Why this beats patching first:** The patch may be thrown away during the split, the extracted API naturally prevents the bug class, and tests from Phase 1 serve as regression tests for Phase 2.

## Deciding What NOT to Refactor

Some identified opportunities aren't worth pursuing. Skip when:
- Only 2 instances exist and they serve different purposes
- The "refactor" would add a feature rather than deduplicate existing code
- The change would require judgment calls about behavior, not just mechanical cleanup

Document skipped items and why — it shows thoroughness without wasted effort.

## Test Layering Strategy

Build tests in layers, each adding confidence before the next:

**Layer 1: Pure function unit tests** — validators, parsers, encoders. No mocking, run instantly.

**Layer 2: Handler/route tests** — colocated test files. Mock external services and test the full request→response flow. Cover: missing required fields → 400, invalid values → 400, happy path → 2xx, service failure → 422, server error → 500.

**Layer 3: Integration error-path tests** — hit the running server. Catch issues that unit tests miss (middleware, serialization, actual HTTP behavior).

**Critical step:** Run the full suite *before any refactoring*. All green = tests correctly describe current behavior. Some failures = you've found bugs — decide per failure whether to fix code or fix test.

## Refactoring Order: Dependencies First

When applying multiple refactors that depend on each other:

1. **Shared helpers first** (add validators, parsers to shared modules)
2. **Consumer changes second** (update routes/components to use new helpers)
3. **Test updates last** (adjust tests for changed status codes or response shapes)

Reversing this order causes intermediate failures that waste debugging time.

## Map Refactoring Targets to Test Coverage

Before starting any refactoring, build a coverage map:

| Refactor | Files Affected | Existing Tests? | Action |
|---|---|---|---|
| Extract shared helper | N routes | No tests | Write tests first |
| Refactor complex parser | 1 lib file | No unit tests | Write unit tests first |
| Fix status codes | 2 routes | No tests | Write tests — they'll reveal the bug |
| Change validator signature | 16 routes | Has lib test | Safe to refactor immediately |

Items with no tests get tests first; items with existing coverage can be refactored immediately.

## Content-Loss Audit After Large Refactors

When a refactor renames, splits, or merges files, run a parallel audit to verify no sections were dropped. Launch one agent per old file — each extracts `##` headings from the old version (`git show main:<path>`) and traces each to a new file.

**Pattern:** The audit agent produces a table mapping old heading → new file → status (✅/❌). Missing sections surface immediately. This caught 9 dropped sections in a 6-file hub-and-spoke refactor that otherwise would have been silently lost.

**When to apply:** Any refactor that deletes or renames 3+ files. The parallel agent cost (~30s) is trivial compared to discovering content loss later.

## See also

- `code-quality-instincts.md` — code quality signals that trigger refactors
- `process-conventions.md` — PR splitting and review process
- `testing-patterns.md` — test recipes for refactoring safety
