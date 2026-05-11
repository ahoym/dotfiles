Methodology for safe, incremental refactoring: survey-first approach, commit granularity, phased execution, PR splitting, and content-loss audits.
- **Keywords:** refactoring, survey, grep, commit granularity, factory vs hooks, React Context, PR splitting, risk profile, phased refactoring, test layering, content-loss audit, bulk rename, bulk line deletion, config-dict script, parallel batch, vendor integration, domain wiring, prudential gate, mechanical gate, Docker smoke test, runtime import check, CMD path change, ModuleNotFoundError, sub-functions, engine, DSL, rule chain, combinator, named branch, abstraction tax
- **Related:** ~/.claude/learnings/code-quality-instincts.md, ~/.claude/learnings/process-conventions.md, ~/.claude/learnings/testing-patterns.md

---

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

## Reach for sub-functions before engines/DSLs

When modularizing a deeply-nested `if/elif/else` policy, the first move is **named sub-functions**, not a combinator engine (`Rule(when, signal, with_side_effect)` walked by a `RuleChain`, etc.). Engines cost real budget:

- **Vocabulary tax.** A reader has to learn the engine's primitives (`Rule`, `when`, `then=/otherwise=`, `with_side_effect`) before they can read any leaf. Sub-functions are plain Python — `def _bullish_branch(ds): if ...: return Signal(...)` reads top to bottom.
- **Stack-trace opacity.** Engine predicates are usually inline `lambda ds: ...`; an exception inside an indicator points at "predicate at line 67," not at a named branch. Sub-functions named `_bullish_branch` / `_bearish_branch` show up in tracebacks and grep results.
- **Unrealized "rules-as-data" upside.** The engine pays for itself only if you actually iterate, mock, or compose rules at runtime. If the call sites are `engine(datasets)` and nothing else, you've paid the abstraction tax without spending it.

**Sub-function recipe:**
1. First pass: extract each branch as a named `def`. `_bullish_branch(ds)`, `_bearish_branch(ds)`, etc. Plain `if/return` at every level.
2. Second pass: deduplicate repeated patterns into shared helpers (`_shorts_vs_bonds`, `_fluxing_or_overbought`). Helpers emerge from the duplication, not from a top-down design.
3. Only graduate to an engine if a real consumer needs introspection/composition/runtime reordering and sub-functions can't serve it. That bar is rare.

**Tell that an engine is over-abstracted:** every call site is `engine(input)`; tests still mock indicator imports at module level (engine adds nothing); no code iterates the rule list; no test composes rules at runtime. If those are all true, sub-functions would have done the same job for less.

**Concrete payoff observed:** A 7-level `if/elif/else` algo refactored first to a `Rule`/`when`/`signal` engine (~250 LOC across `rule_chain.py` + algo + engine tests), then re-refactored to sub-functions (~135 LOC, no new vocabulary). Same 22 branch-coverage tests passed in both versions — they were behavioral, not engine-bound. Sub-function version was strictly easier to read.

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

## Categorize References Before Bulk Renaming

When renaming a directory that's referenced across many files, categorize each reference as "this repo's structure" vs "generic convention" before replacing. Bulk find-and-replace without this step causes over-replacement — e.g., `.claude/` as a Claude Code project convention should stay, but `.claude/` meaning "this repo's config directory" should change. Assign batches to parallel agents with clear category instructions to prevent both under- and over-replacement.

## Post-Commit Grep for Rename Stragglers

After committing a rename, grep the full tree for the old name. Index files, cross-ref sections, and config files outside the changeset are commonly missed.

## Encoding Corruption from Copy/Paste in Structural Refactors

Moving content between files can introduce invisible encoding differences that render as replacement characters (�) on GitHub. `git diff` after content moves catches byte-level corruption.

## `replace_all: true` for Mechanical Path Migrations

`Edit(replace_all=true)` with one call per old path handles most files in path migrations. Only files needing structural changes (added `mkdir -p`, etc.) need targeted edits. Final grep catches bare paths without trailing `/`.

## Rename-first PR before abstraction refactor

Before a structural refactor that will touch many files (introducing a protocol/ABC, splitting a module, migrating call sites), ship a prep PR that does pure renames and legacy-name cleanup. The structural PRs that follow contain only structural changes, not rename noise — smaller diffs, easier review, cleaner revert boundaries.

Typical prep PR scope for an abstraction refactor:
- Rename legacy-vendor names to current-vendor names (`tda_client` → `schwab_client`)
- Drop aliased legacy imports (`from X import Y as Y_legacy`)
- Update stale docstrings that reference removed systems

Kent Beck: "make the change easy, then make the easy change." Even when renames look trivial individually, bundling them into the structural PR makes the diff harder to reason about ("did this line change because of the refactor or the rename?"). Tracked as PR "A0" or similar in a phased plan — always first.

## `DRY_RUN` env flag as zero-behavior-change review gate

For refactor PRs whose acceptance criterion is "zero behavior change" (touching live systems, order execution, API writes, file mutations), introduce a `DRY_RUN=1` env flag early in the PR sequence. When set, the system runs its full live flow but suppresses every side effect — logging what **would** happen instead.

Use it as a review gate: reviewer runs the branch end-to-end with `DRY_RUN=1` against real dependencies **before and after** the PR, diffs the two logs. Zero diff = zero behavior change confirmed, including interactions unit tests can't cover (conditional code paths, indicator fall-through, timing-dependent branches, real API response variance).

Introduce the flag as part of the first PR that touches the affected call site — same PR that migrates to the abstraction or refactors the entry point. Cheap to wire in (~20 lines), turns every subsequent refactor PR in the chain into a testable artifact against production-shaped inputs at zero real-world cost. Especially valuable for the highest-risk structural transitions (eager-fetching rewrites, DI migrations, retry-loop relocations).

## Read the implementation plan before scoping a multi-PR migration

Issue bodies state ACs but rarely state the *boundary* — what's deferred to the next PR vs done now. The linked design or implementation plan gives the phase context that prevents scope creep. Without it, ACs like "all calls route through the adapter" sound total when the plan actually splits them across this PR (libs surface), the next PR (internal factories), and a third (test-mocking migration).

Order: issue body for ACs → linked plan for phase boundaries → code for current state → only then estimate scope.

## Targeted bulk line-deletion via Python config-dict script

When a sweep needs to delete N hand-picked lines across M files (e.g., stripping restatement docstrings flagged by manual review), a small Python script with `{path: [line_numbers]}` config beats N `Edit` calls or fragile sed regex:

```python
STRIP = {
    "tests/foo.py": [22, 45, 67, ...],   # line numbers from manual triage
    "tests/bar.py": [12, 88, ...],
}

def process(path, line_nums):
    lines = open(path).readlines()
    drop = set(n - 1 for n in line_nums)
    drop |= {n + 1 for n in drop if n + 1 < len(lines) and lines[n + 1].strip() == ""}
    open(path, "w").writelines(ln for i, ln in enumerate(lines) if i not in drop)
```

**Why this beats alternatives:**
- The dict IS the audit trail — operator can read the rubric and the script in one glance.
- One pass per file vs. N `Edit` calls; no per-file Read-before-Edit cycle.
- Reversible: adjust the dict and re-run on a fresh checkout.
- Auto-strips the trailing blank line so class-with-just-methods doesn't end up with a stray gap.

**When sed is wrong here:** regex over `class … docstring … blank … def … docstring` is fragile to indent and accidentally catches helper docstrings you wanted to keep. Use sed for regex bulk rewrites (see `~/.claude/learnings/bash-patterns.md` → "Bulk Path Rewriting with sed Files"); use this script for hand-curated line lists where the classification lived in the operator's head.

**Workflow:** read each file once → classify line-by-line into the strip set → run script → run tests + lint. The judgment lives in the dict; the script is just executor.

## Tuple → dataclass mock migration: replace_all per unique value

When migrating `MagicMock(return_value=(N, N, N))` → `MagicMock(return_value=Foo(N, N, N))`, don't try one regex over the test file. Tuple literals appear in multiple shapes (poll returns, factory returns mixing dict + scalars), so a broad regex over-matches.

Recipe:
1. `grep -n "return_value=(" file.py` — list every unique tuple value
2. For each unique value, `Edit replace_all=true` with `return_value=(N, N, N)` → `return_value=Foo(N, N, N)`
3. Handle list-context cases (`side_effect=[(N, N, N), Exc]`) as targeted single edits — `replace_all` won't match across the bracket boundary

## Vendor-integration vs domain-wiring split

Adapter / multi-vendor PRs naturally split along two seams:

- **Vendor integration:** SDK/HTTP client, normalization, adapter class implementing the protocol. Depends only on the protocol shape — once that's merged, this is greenfield work that lands fully inert (nothing imports it; composition root still rejects the env value).
- **Domain wiring:** composition-root branch (`if BROKER == "x":`), contract-test extension with recorded fixtures + golden files. Depends on test infra + activation gates from the same phase.

When a ticket says "Blocked by: Phase X complete," check whether the gate is **mechanical** (types/protocol not yet defined → genuinely blocking) or **prudential** (avoid review-track collision, conservative serialization → splittable). Prudential gates are the seam — split into B2a (vendor, parallel-safe with the cascade) and B2b (wiring, gated). Cuts critical-path time without violating the original gate's intent.

## `TYPE_CHECKING` import-cycle dance signals modules to fold

`if TYPE_CHECKING: from foo import Bar` exists solely to dodge a runtime circular import. When the dancing module's helpers all take `Bar` as primary arg (`def helper(bar: Bar, ...)`), it's effectively `Bar`'s methods written awkwardly — the modules are too tightly coupled to be split cleanly. Fold the helpers into `Bar` as methods:

- The `TYPE_CHECKING` workaround vanishes
- The call surface gets one canonical home (`bar.helper(...)` instead of `helper(bar, ...)`)
- New helpers naturally land as methods, keeping "all calls live in one place" enforceable

Demote the underlying transport methods to private (`_get`/`_post`/etc.) at the same time — they were public solely to be reachable from the now-deleted helper module. SDK-style classes (boto3, schwab-py) follow this shape.

## Rebase add/add resolution: prefer trunk wholesale when implementations converge

See `~/.claude/learnings/git-patterns.md` → "Add/add rebase conflict where trunk independently shipped the same extraction." The refactoring corollary: when two parallel PRs ship the same extraction and one merges first, the second branch should rebase and take trunk's version wholesale — line-by-line merging produces a Frankenstein that satisfies neither code review.

## Classify pre-existing behavior before "preserving" it through a refactor

When migrating code through an abstraction, behavior that "looks weird" is one of three things:

| Classification | Action |
|---|---|
| **Intentional design** (operator-controlled invariant, safety rail) | Preserve verbatim, document *why* |
| **Latent bug** that no caller exercises | Preserve as-is, file follow-up |
| **Trivially scoped fix** in the migration's blast radius | Fix in same PR |

Mistaking intentional design for a bug produces follow-up tickets that propose changing intentional behavior — work that would actively break the system.

Verify *why* before classifying. Signals of intentional design:
- Inline comments explaining the decision
- Operator-controlled config (limits files, feature flags) that depends on the behavior
- Tests asserting "this is the contract" (not just "this is what the code does")
- **Commented-out alternative code paths** — deliberate-abandonment signal. If `# x = broker_field` sits dead inside an active function, someone *chose* to stop reading `broker_field` and left the comment as documentation. Read it as "we used to do this and explicitly don't anymore," not "stale code to clean up."

If unsure, ask before classifying. The default of "preserve and follow-up" is the wrong answer when the behavior is load-bearing.

## Domain-keyed registry beats threading product-specific values through call sites

When a function needs per-product values (margin/notional for a futures contract, decimals for a currency, rate-limit for a vendor), and those values are *properties of the domain entity* identified by a key the function already parses, push the lookup into a registry — don't thread them through every caller.

```python
# Anti-pattern: param-thread
def trigger_position(ticker, account, *, margin: float, notional: float): ...
# Caller now needs product knowledge:
trigger_position(ticker, acct, margin=MNQ_MARGIN, notional=MNQ_NOTIONAL)

# Pattern: registry keyed by base symbol
@dataclass(frozen=True)
class ContractSpec:
    margin_per_contract: float
    notional_per_contract: float

CONTRACT_SPECS: dict[str, ContractSpec] = {
    "MNQ": ContractSpec(4_100.0, 20_000.0),
}

def trigger_position(ticker, account):
    _, base_symbol = _parse_ticker(ticker)
    spec = CONTRACT_SPECS[base_symbol]
    ...

# Caller is now product-agnostic:
trigger_position(ticker, acct)
```

Tells: caller has to import constants whose names contain the product (`MNQ_*`); two parallel parameters always travel together; tests pass the same constants every time. Refactor signal — the values aren't really arguments, they're a property of the parsed key.

Don't put it on the *Account* (or other call-site-adjacent type) just because the values are needed there — accounts could trade multiple products, and Account would acquire fields it doesn't own. The contract identifies the spec; the registry resolves it.

## Re-export moved helpers to preserve caller compat

When relocating a private helper into a new module during a refactor, re-export from the original module so existing imports keep working:

```python
# old_module.py — after moving helpers to new_module
from new_module import _helper_a, _helper_b

__all__ = [..., "_helper_a", "_helper_b"]
```

Keeps the refactor diff scoped to the structural change — caller renames belong in a separate pass. Especially valuable when private helpers are tested directly (`from logic.foo.roll import _third_friday`); without re-export, every test import has to churn alongside the move.

## Smoke-test Docker import after `CMD` path changes

After a refactor moves the script invoked by `CMD ["python", "./path/script.py"]`, run an explicit import check — `ls` and `python --version` confirm the image *built*, not that it can *run*:

```bash
docker run --rm --entrypoint python <image> -c 'import config.X; import logic.Y'
```

`ls scripts/trading/` passes on broken images; pytest passes too because it auto-adds rootdir to `sys.path`. The `ModuleNotFoundError` only surfaces at the production runtime path. The build success + lint pass + test pass combo is not a green light for a path-relocation refactor — the runtime import is the only reliable signal.

Pairs with `python-specific.md` → "`python ./path/script.py` puts only the script's dir on `sys.path`" for the underlying mechanism.

## Cross-Refs

- `~/.claude/learnings/code-quality-instincts.md` — code quality signals that trigger refactors
- `~/.claude/learnings/process-conventions.md` — PR splitting and review process
- `~/.claude/learnings/testing-patterns.md` — test recipes for refactoring safety
