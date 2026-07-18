Methodology for safe, incremental refactoring: survey-first approach, commit granularity, phased execution, PR splitting, and content-loss audits.
- **Keywords:** refactoring, survey, grep, commit granularity, factory vs hooks, React Context, PR splitting, risk profile, phased refactoring, test layering, content-loss audit, bulk rename, bulk line deletion, config-dict script, parallel batch, vendor integration, domain wiring, prudential gate, mechanical gate, Docker smoke test, runtime import check, CMD path change, ModuleNotFoundError, sub-functions, engine, DSL, rule chain, combinator, named branch, abstraction tax, round-trip validation, destructive migration, format cutover, --commit flag, bundle commit, atomic-commit-passes-tests, platform-conditional branches, OS branches, dedupe blindly, package-manager tracking, parity test, equivalence test, guarded duplication, consolidation signal, union of constraints, shared home invariant, pyarrow-free, dependency-free invariant, verify-first plan, secondhand reads, source conflict, hard verify-point, lagging stylistic sweep, comment conciseness pass, rebase re-run sweep, conflict partial map, sweep new content, call-site comment pointer, inherited roadmap, status-block staleness, verify against main, dead-but-shipped type, re-audit do-not-resurface, in-place replace not rebuild, scripted structured-doc edit, derived count recompute, dropped-heading assert, idempotent resolver, invariant checker before transform, reconstruct drops boundary content, redirect stub, file-existence check, fixture resolution
- **Related:** ~/.claude/learnings/code-quality-instincts.md, ~/.claude/learnings/process-conventions.md, ~/.claude/learnings/testing/testing-patterns.md

---

## Parity-Test-Guarded Duplication → Consolidate, but Honor Every Invariant

A dedicated parity/equivalence test that exists only to keep two near-identical implementations in sync is a strong **consolidation signal** — and its docstring often names the safe exit ("if a future PR merges these, delete this module").

When consolidating, the shared home must satisfy the **union of every constraint each copy independently honored** — not just the one the test mentions. The obvious target (or the one the test suggests) may break an invariant the *other* copy was protecting. Example: two `merge_candles` copies existed to dodge a `utils → broker` import-boundary ban; one copy was *also* kept dependency-free ("importable anywhere"). Moving the canonical impl into the existing pyarrow-heavy module would satisfy the boundary but break the dependency-free invariant — so a new minimal dependency-free module was the correct home. Enumerate all constraints (import boundary, optional-dep-free, IO-free, broker-agnostic) before picking where shared code lives.

## Plans From Secondhand or Lagged Reads: Verify-First + Flag Conflicts

When drafting an implementation plan from a subagent summary or partial reads rather than a full direct read, mark specifics (line numbers, helper names, sizing bases) as "verify at implementation" and lead with a verify-first checklist. If two sources disagree on a load-bearing fact (e.g. a code comment says futures size off `equity`, the equivalence-test docstring says `cashAtHand`), record BOTH and flag it as a hard verify-point — never assert one as truth. A confidently-wrong "must not break" claim in a plan is worse than an explicit unknown.

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

## Refactor-meets-feature merge: integrate, don't take either side wholesale

Distinct from same-extraction add/add (above): one branch adds *new* symbols to a module while trunk independently *extracts other* symbols out of it into a new shared module (e.g. trunk moved constants/exceptions to `_shared.py`; the branch added a new lock/retry path + exception to the same `manager.py`). Neither "take trunk" nor "take branch" is right — make the merged file look like trunk's slimmed version *plus* the branch's additions. Force `git merge` (not rebase): rebase replays the branch's additions once per commit against a moving target, while a single merge collapses the integration into one pass. Place each new symbol by *actual ownership* — a manager-only exception stays in `manager.py` even though sibling exceptions moved to `_shared.py`; the resulting asymmetry reflects usage, not a smell.

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

## A redirect-stub masks file-existence integrity checks

Replacing a deleted/moved file with a redirect stub (instead of deleting it) keeps the path resolvable — so file-existence checks, fixture `ground_truth` resolution, and "does it still exist" greps pass *falsely* until the stub is removed. Audit for and remove leftover stubs before trusting an all-green run, and when moving/deleting a referenced file grep **all** artifact types for the path (fixtures, configs, indexes), not just code cross-refs.

## Round-trip-validate before deleting source data in destructive migrations

A migration tool that deletes the source after writing the target must read the target back and compare byte-equivalent to the source *before* unlinking. Mismatch → preserve source, non-zero exit. Gate the destructive step behind a `--commit` (or `--apply`) flag so the default is dry-safe:

```python
write_to_new_format(target_dir, candles)
ok, msg = validate_round_trip(candles, target_dir)
if not ok:
    return Result(ok=False, error=f"round-trip failed: {msg}")  # source preserved
if commit:
    source_path.unlink()
```

Compare field-by-field, not via a single equality check. Storage-layer type coercions are easy to miss (int64 vs float, ms vs s, NaN handling) and silent rounding can pass a naive `==`. The check is what proves the *new* format encodes the *same* information — not just "the file is non-empty."

## Bundle format-cutover commits when readers + writers + data change together

"One logical unit per commit" usually means *small* atomic commits. For a storage-format migration where readers, writers, and on-disk data must all change at once, the logical unit is *large* — splitting across commits leaves intermediate states with broken cache reads or red tests.

Decision rule: if the swap commit leaves `pytest` red until the data migration commit lands, the two must bundle.

| Split (preferred when possible) | Bundle (cutover) |
|---|---|
| Swap can fall through to old format → tests pass | Swap fails-loud without new format → tests fail |
| Reader-only or writer-only change | Both readers and writers change |
| No on-disk data change in the commit | Source data deleted in same operation |

The cutover commit may be hundreds of files by count (data add/delete churn). That's fine — what matters is logical coherence, not line count. Bisect granularity through a cutover is just "before/after the cutover" anyway.

## `@patch` Decorators Break When Code Moves

When extracting a function into a new module, every test `@patch("old_module.symbol")` referencing imports-at-the-old-location breaks silently — the patch targets a name that no longer exists in the new caller's namespace. Mock at the new import location: if `sleep` moved from `logic.plz.operations` into `logic.libs.execution`, patches must become `@patch("logic.libs.execution.sleep")`.

Audit step after any extraction: `grep -r "@patch.*old_module" tests/` and rewrite each. Tests that still pass after the move are passing for the wrong reason — they're patching a no-op.

**Partial extraction → patch BOTH modules, not just move the patch.** When only *some* calls of a symbol move (the regime tree moved to `branches.py` but the top-level split + a sibling helper still call `is_RSI_greater_than` from the algo module), the symbol is now reached from two namespaces. A test that patches only one misses the other path's calls. Patch it in *each* module that imports it, and combine the `patch.multiple(...)` contexts with `contextlib.ExitStack` (`stack.enter_context(...)` per module) so one `with _patch(ind):` still reads cleanly. The test *assertions* stay byte-identical — only the patch plumbing follows the moved code; that unchanged-assertion green is what proves behavior preservation.

**Private→public rename + back-compat alias preserves imports, NOT `@patch` interception.** Promoting `_foo`→`foo` with a module-level alias `_foo = foo` keeps `from mod import _foo` working — but a test patching `mod._foo` replaces only the *alias* attribute; once callers invoke `foo`, the patch no longer intercepts (it targets a different name). Every `@patch("mod._foo")` string must move to the new name regardless of the alias. The alias gives false confidence that patch-target tests are unaffected by the rename.

## Closure State Dicts for Callback-Driven Helpers

When extracting a callback loop (e.g., `retry_until_filled(place_fn, update_fn, ...)`), two patterns keep the signature small:

1. **`place_fn` returns `Optional[tuple[...]]`** — `None` signals exit-early, tuple carries forward state. One signature covers normal, dry-run, and "nothing to do" paths without an extra `check_fn` parameter.
2. **Closure state dicts** — when `update_fn` needs values `place_fn` computed (price, ticker, qty), use a mutable dict captured in closure scope. Avoids a separate context object or expanding the helper's signature.

Both push state-passing into the caller's closures, keeping the helper itself stateless.

## Extract the shared wiring, not a flag-heavy spec — divergent call-site ordering is the tell

When N call sites *look* like one primitive, the genuine shared piece is often just the **wiring** around a per-site closure, not the closure itself. Six order sites each did `poll, cancel = _broker_poll_cancel(...); retry_until_filled(place_fn, ...)` with the same `MAX_TRIES`/sleep — that tail was the real dup. The `place_fn`s themselves diverged and stay per-site.

The tell that one signature **can't** unify the sites: their internal **ordering** differs. Buy needs `fetch_price → size_qty(price)`; sell needs `size_qty → fetch_price`. A single shell with a fixed order can only serve both via a flag — and a `Spec` that needs 5 flags to cover 6 sites is the over-abstraction the sites were warning you about. Stop at the shell that bundles the shared plumbing (poll/cancel + retry defaults "in one place"); leave the divergent closures alone. Sibling to "Reach for sub-functions before engines/DSLs" — same instinct, applied to a callback-driven primitive instead of an if/elif tree.

## Inject leaves into a shared skeleton: pure values eager, side-effectful computations as thunks

When collapsing two near-identical nested-conditional functions into one parameterized skeleton, each algo passes its differing leaves *as data*. Split the leaves by effect:

- **Pure values** (a `Signal(ticker)`, a constant) → pass eagerly. Constructing the untaken one is harmless (no I/O, no log).
- **Side-effectful computations** (further indicator calls, `logger.info`, broker reads) → pass as zero-arg thunks (`lambda: buy_the_dips(...)`). An eager call would fire the *untaken* branch's side effects and corrupt the log/behavior.

The signature documents the contract: `oversold_main: Signal` (value) vs `bonkers_terminal: Callable[[], Signal]` (thunk). One genuine *control-flow* difference (not just data) earns a real flag — e.g. `check_fluxing: bool` for the one branch that skips a sub-check — kept distinct from the value/thunk leaves.

## Migration stability-guards must default missing legacy state to the prior semantic

A guard that suppresses churn by comparing against persisted state (`last_weight`, `last_hash`, `last_target`) reads `None`/absent for data written before that field existed — so the guard can't fire and the *first* post-migration run churns (close+reopen, rewrite, resend) even when nothing changed. Default the missing value to whatever the legacy shape implied (e.g. a legacy single-position file ⇒ full weight `1.0`) so an unchanged target is recognized as unchanged on tick one. Add a regression test using the **old** file format asserting no action when the target matches.

## A refactor's coverage gap is usually pre-existing — land the tests off main, not the branch

When a behavior-preserving refactor exposes a thin spot in test coverage, check whether the gap predates the refactor before adding tests on the branch: `git diff --stat main...branch -- tests/`. If the relevant test files are byte-identical to main, the gap is base coverage missing on main, not something the refactor introduced. Branch the new tests off `main` as a standalone PR — they cover behavior that already ships, and once the refactor branch rebases it inherits them as a free regression backstop (the same tests re-run against the refactored code path and prove equivalence). Adding them on the refactor branch instead conflates "missing base coverage" with "coverage for this change" and ties shippable tests to an unmerged refactor.

## A lagging stylistic-sweep branch: rebase re-runs the sweep on new content

A branch doing a uniform stylistic pass (comment conciseness, rename, format normalization) that's fallen behind main has a second job at integration time: main merged new code that never went through the pass. Treat the rebase as **re-running the sweep on the newly-merged content**, not just replaying your commit.

- **Conflicts are a partial map, not the whole job.** Conflicts surface only where the new content touched the *same lines* your sweep edited. Resolve each by applying your branch's style to the incoming side (keep the concise/renamed form, extend it to the new entries). Then separately sweep the conflict-free new files/sections — `git diff --stat $(git merge-base HEAD main)..main -- <area>` lists everything that arrived, most of which won't conflict.
- **Fold the new-content sweep into the same commit** (`commit --amend`) so the branch stays one logical unit; force-push with `--force-with-lease`.
- A call-site comment whose full rationale now lives in the callee's docstring should shrink to a one-line pointer (`see X.update_excursion`) rather than duplicate it — newly-merged code often duplicates because it landed without the callee's doc.

## Converting Scattered Literals to a Derived Helper — Scope to the Diff, Separate by Intent

When a reviewer asks to derive ~N scattered literals from a constant (e.g. test equity values from a sizing notional), scope the conversion to the lines the triggering PR actually changed (`git diff <base>...HEAD`), not every textual match. The same numeric literal often encodes different intents: a *derived* value (convert — e.g. a bucket-midpoint equity → `equity_for_contracts(n)`), a *boundary* value probing a different threshold (keep — `$1k`/`$2k` testing a margin cliff, not a notional bucket), and an *input/prior-state* value that isn't derived at all (keep — e.g. a persisted `cashAtHand` that the code overwrites). Verify each match's role before swapping; a blanket find-replace silently corrupts the boundary and input cases.

## Isolate an entangled rename into its own commit by reverse-then-redo

The clean approach is a rename-first prep PR (above), but agents typically make *all* edits in the working tree before committing — and `git add -p` is unavailable in the harness, so whole-file staging can't split a rename out of the other edits sharing a file. Recovery: **reverse the rename** in the working tree (replace_all back to old names), commit the substantive changes on the old names, then **re-apply the rename** and commit it alone. Two rules make each commit green in isolation: (1) order any consumer/import update *before* the rename commit — a commit that renames a definition while a consumer still imports the old name fails on checkout; drop the shim / update the import first; (2) re-run the import-sorter after the redo (`ruff check --fix`) — a rename reorders alphabetized import blocks. Net diff is identical to doing it in one commit; the history just bisects cleanly.

## A behavior-preserving refactor's oracle is the original on the same inputs, not committed reference numbers

When refactoring code whose printed output is pasted into a doc (research tables, golden snapshots), don't diff a fresh run against the doc: the doc's numbers drift once the committed data/cache advances past the doc's stamped vintage, so a mismatch reads as a refactor bug when it's just newer data. Verify equivalence by `git stash`-ing the refactor and diffing **refactored-vs-original output on the current inputs** — empty diff = behavior-preserving; the doc is a valid oracle only when its inputs are pinned.

```bash
run > ref.txt; git stash push -- <paths>; run > orig.txt; git stash pop; diff orig.txt ref.txt
```

For an **expensive multi-target capture**, take the original from a throwaway worktree at HEAD (`git worktree add --detach ../wt HEAD`) instead of `git stash`: stash serialises (blocks the tree) and — worse — editing the live tree while a long baseline job is mid-run *contaminates* it, since the runner reads source at exec time and silently mixes old/new code across targets. The worktree isolates the baseline so it runs in parallel with continued editing; diff the two output dirs at the end.

**Strip non-deterministic lines before the byte-diff.** Scripts that log wall-clock
timestamps or print an env/venv-setup banner produce "diffs" that are pure noise — a
fresh worktree's first run also emits the uv venv-creation banner the warm tree doesn't.
Pipe both sides through a `sed`/`grep -v` that drops the timestamp prefix + banner lines
before `diff`; a surviving diff is then a real behavior change. Don't eyeball a raw diff
full of timestamps and conclude "changed."

## Falsify a "Shared Helper" Finding Before Extracting — Three Phantom-Duplication Shapes

An audit/finding that says "X is duplicated, extract a shared helper" is a hypothesis — read the real code first. Three shapes make it a false positive:

- **Already-factored** — the "duplicate" call sites already delegate to a common helper (e.g. two `_last_persisted_*_weight` fns that both just call `weight_from_mapping`). Nothing to extract.
- **One-sided** — the duplication exists in only one of the two paths the finding assumes (e.g. a budget-scaler present in the backtest with no live twin). A "shared" helper would *invent* a second use case.
- **Intentionally-divergent** — same formula, different edge policy or inputs *by design* (Sharpe with/without risk-free rate; `profit_factor` returning `None` vs `inf`). Unifying changes behavior — the divergence is the point.

Only genuine same-semantics duplication across 2+ real call sites is extractable. The other three are **deferrals with documented evidence** — a first-class outcome, not a failure to ship.

## An Extraction's Composability Payoff Is a Premise to Verify, Not a Given

Sibling to "Falsify a Shared Helper Finding" (which checks the duplication is *real*): even real duplication isn't worth extracting unless the *payoff* materializes — usually "the next new-X gets cheap." Verify that claim against the code; two modes silently kill it:

- **The abstraction spans an N=2 that diverges by design.** Two implementations sharing a thin skeleton + many by-design-divergent leaves (holdings source, sizing basis, persistence policy) don't get cheaper behind a Protocol — a *3rd* example brings its own divergent leaves, so "new case ≈ 40 LOC" is illusory; it's 150+ LOC of new leaves either way. The interface just bakes in from N=2.
- **The hard part survives the abstraction unchanged.** If the irreducible logic (a broker+asset-class wire translation, an exact-vs-broad guard) lives *inside* the leaves, collapsing the dispatch doesn't shrink it — the new case writes the same branches. Payoff = "1 stub vs N stubs," small, bought with churn on a hot/risky path.

When the payoff is speculative (no concrete 3rd case; an unverified "it'll plug into the future pipeline" handshake), defer the framework and ship only the slice that's safe *and* pays off today. Add the ~5-line Protocol the day a real 2nd consumer lands — the existing examples usually already structurally satisfy it, so nothing is lost by waiting.

## Multi-Wave Refactor Handoff to a Fresh Session

A roadmap written *before* execution goes stale the moment you ship — add a **Status block as the single source of truth** (per-item ✅ shipped / ⏸ deferred) and reconcile any body text still reading as the original plan. For the handoff:

- **Name the base branch.** If prior waves are unmerged, say "base on `<wave-N-branch>` until its PR merges, then rebase onto main" — items assuming the prior wave's new files/symbols break on bare main.
- **Cite symbols, not line numbers, for refs into already-changed files.** A line number into a file a prior wave touched shifts on merge; a re-grep of the symbol survives. List the touched files so the next session knows which refs to distrust.
- **Bake framing corrections into the roadmap** rather than trusting the next session to re-derive them (e.g. "the framework already shipped — don't rebuild it").
- **When re-verification *flips* a planned wave, the handoff is the deliverable.** A defer-with-evidence is a first-class outcome, not a punt: record each dropped item as a "verified not worth building" entry citing the code, so the next session doesn't re-attempt it. **Quarantine, don't delete** superseded guidance — retitle the section `SUPERSEDED`/`CLOSED` with a "do NOT execute" banner and keep it as the audit trail of what the plan *was*. If the *next* wave's framing leaned on a now-deferred item (a "this is the terminal of X" handshake), correct every cross-reference threaded through it, not just the headline — grep the deferred item's name across the doc.

## "Preserve-behavior" hinges on the exact default — read it at the source

Routing a call site through a shared helper preserves behavior only if the helper's *defaults* match what each site relied on. A site that omitted a kwarg inherited the *constructed object's* default, not `None` — so giving the helper `build(..., benchmark_ticker=None)` silently flips it when the real default was `"SPY"`. Read the actual default at the definition (`@dataclass` field, `__init__` signature) — never from the call you're copying, and never from a verifier subagent's summary: an adversarial verifier that *read the file* still mis-stated a default in one session; only opening `config.py` caught it before it shipped a silent behavior change. (See `claude-code/multi-agent/quality.md` — un-verified findings are hypotheses.)

## Relocating a byte-identical expression is parity-safe by construction

When a helper *relocates* the exact same expression rather than reimplementing it — e.g. `candles[int(len(candles)*frac)].datetime` lifted verbatim into a constructor — the output is identical by construction and the migration can't numerically drift. Pin the exact expression in a unit test as a regression guard, and prefer a cheap spot-check (re-run one consumer, diff one printed value) over re-running every expensive consumer. Contrast a *reimplemented* duplicated computation, where a full parity test per site earns its keep.

## Reverting one extraction from a multi-commit branch — `checkout <commit>^`, and don't forget its doc edits

To undo a single logical extraction a reviewer rejected while keeping the rest of a multi-commit branch, restore the pre-extraction blobs with `git checkout <extract-commit>^ -- <files>` — but first prove that commit is their **sole** modifier (`git log <extract-commit>..HEAD -- <files>` empty), or `<commit>^` silently drops later edits to those files. Watch for **non-code** files the same commit touched (a `CLAUDE.md` recipe / doc paragraph — `git show <commit> --stat` lists them); revert those with a *targeted Edit* since the file may carry other PR changes you must keep. Re-run the affected tests after — a faithful revert restores the pre-extraction green.

## Detach an opt-in feature into a pure core + self-contained overlay

To make a feature *off by default and structurally absent* from the production path (not merely flag-gated-off), revert the core to a pure function and move ALL feature logic into a standalone overlay module the production path no longer imports — the overlay stays explorable from backtests/research without touching live.

When the overlay must alter the pure core's internal branching but you've removed the core's feature params, **extract the core's branch-dispatch into a plain-typed helper both call** — e.g. `dispatch_by_regime(is_bullish: bool, …)` invoked by both `plz_algo_v2` and the overlay. One shared seam, no duplicated `if`, no divergence; the helper carries no feature knowledge so the core stays pure. Beats the overlay re-implementing the dispatch, which silently drifts when the core's branch selection later changes.

## Detaching a paused feature from a live path: numbered re-wire markers, migrate integration→unit tests

To remove a paused/dormant feature from a production entry path — stronger than flag-gating-off, since it also strips the **import-time** surface a per-tick `try/except` can't guard (a module import or import-time config resolution that could block startup) — replace every call site with a numbered marker comment (`[FEATURE RE-WIRE n/N]`) plus one central note (why + where the N sites are + the prior-wiring commit SHA). Keep the implementation module + its tests intact (explorable from tests/research).

Migrate the now-dead **integration** tests (they drove the detached wiring through the entry point) to direct **unit** tests on the extracted module — same scenarios, called with fakes — so the implementation's coverage survives the detach. Pairs with "Detach an opt-in feature into a pure core + self-contained overlay" (the structural half) — this is the operational half: markers, surface accounting, and test migration.

## Wrap the Nth Call-Arg Across Many Sites with a Bracket-Aware Transformer, Not Regex

To mechanically wrap one argument across ~N call sites (`f(a, X)` → `f(a, g(X))`) where the args contain commas (dict literals) or parens (`float("nan")`), a regex mis-splits on the inner punctuation and silently corrupts a subset. Write a tiny paren-depth + string-skipping scanner that finds the call's matching close paren and the top-level comma, then splices `g(...)` around the last arg. Run it as a one-shot script over the file, then review the diff and run the tests. Reliable where `sed`/regex breaks on nesting; the ~60-site wrap lands in one pass.

## Prove a no-op when the committed golden is itself stale: stash-isolate

To prove a refactor changed no behavior you normally diff a regenerated output against
the committed golden — but that fails when the *committed* golden is itself stale (it
doesn't even match a fresh run of the pre-refactor code, e.g. a result table never
regenerated after an earlier change). Then diff *your-edits run* against a *clean-tree
run* instead: `git stash push <changed files>`, regenerate → `clean.txt`;
`git stash pop`, regenerate → `mine.txt`; `diff clean.txt mine.txt`. Identical proves
your edits are a true no-op — independent of the pre-existing golden drift (a separate
finding to flag, not silently re-baseline). Isolates *your* effect from baseline rot.

Common trigger: a research/results branch **rebased onto a PR that refreshed the data
cache** replays its old-vintage result tables unchanged, so they silently drift from the
data they now ship with. Diagnose by comparing `git log -1 --format=%ci` on the data
partition vs the results file — data newer than results = stale golden. Capture a fresh
HEAD baseline (current code on current data) as the no-op oracle.

## Split a compute-and-print script into compute() + render() for an output-preserving, composable refactor

A report/analysis script that interleaves computation with `print()` becomes composable by
splitting it into `compute() -> JSON-serializable dict` (the numbers) + `render(data)` (the
`print()` f-strings, reading from the dict) + a shared CLI tail (`--json` emits the data, else
renders). The numbers become testable + machine-readable with zero output change. Two rules keep
it a true no-op: `render()` keeps every f-string **character-identical** (only the value source
changes, local var → dict key), and `compute()` returns **plain Python types** (cast every numpy
scalar — `float(x)`/`int(x)` — or `json.dumps` raises).

Verify byte-parity against a captured pre-refactor baseline, not the committed output (which may
be stale — see stash-isolate). Across many scripts, fan out one subagent per file with a shared
convention + that file's baseline as the oracle; cheap scripts self-verify (run + `diff` ==
baseline), expensive ones edit-only with a final batch byte-diff — don't trust a slow runner's
self-reported byte-identity.

## Isolate a data/vintage refresh into its own commit before a behavior change

When a change both (a) refreshes regenerated artifacts to a newer data vintage and (b) alters
behavior, commit them separately: first regenerate with the **old** behavior on the new data (a
pure data-drift commit), then apply the behavior change and regenerate again. The second commit's
artifact diff is then the behavior effect **alone** — directly the quantification a reviewer asks
for ("how much did this move?") — instead of an unattributable data+behavior blend. Pairs with the
stash-isolate no-op proof: the first commit's diff is pure data drift, the second pure behavior.

## Inheriting Prior Refactor Work: Verify Status, Don't Re-Derive Deferrals

A handoff roadmap's Status block records the plan's *intent at write-time*, not ground
truth — the effort may have stalled, reverted, or a "shipped / PR open" item may never
have merged. Before acting on an inherited multi-wave roadmap, reconcile every status
claim against `main`: `git log`/`git grep` the named symbol, confirm the cited call site
changed, check a "merged" branch actually landed. Two recurring stale shapes: a type
"shipped" but with **zero production importers** (dead code — its consumer PR never
merged), and a wave marked "shipped, PR open" living only on a local branch. (Worked: a
roadmap claimed Phase-4B "SHIPPED — PRs OPEN"; `main`'s call site was untouched and the
branch was local-only.)

When the inherited work includes a prior audit, **seed every finder + verifier with the
prior audit's "do-not-resurface" list** (its deferred/refuted items + the code evidence)
so a fresh pass doesn't re-derive settled conclusions. An audit that re-surfaces a
reverted extraction or a refuted metric-unification burns the verification budget
re-killing it.

## Only leaf helpers move "down" into a shared base module

Before consolidating helpers into a shared base module (a `_common.py`, a `utils`, the
root of an effort's import DAG), check the dependency *direction*. The base is imported
BY the others, so it can only absorb helpers that depend on nothing above it. An
**aggregator** that imports sibling modules can't move into the module those siblings
import FROM — that's a circular import (`_common → ribbon_portfolio → _common`). Tell:
the helper's own module imports 3+ siblings. Such top-of-DAG helpers stay put (or get a
NEW module *above* the leaves), regardless of an issue that says "consolidate into the
base." Single-definition + sibling-imported is already DRY; relocation into the root is
often infeasible, not a missed cleanup.

## Share a state machine via a pure decision-function, not class extraction

When two consumers need the same state-transition logic but own *different* surrounding
state (one tracks a peak per-tick + serializes to JSON; the other walks an event list),
don't extract a shared stateful class — extract the **decision** as a pure function both
call, leaving each consumer's state ownership + lifecycle intact. To kill a second copy
of a trip/reclaim hysteresis: lift `step(state, input) -> new_state` out of the
production class, have its `apply()` call it (byte-identical), and have the research
consumer call the same function. The production class keeps its serialization/non-finite
handling untouched — lowest-risk path to one source of truth. Pin it with a parity test
that drives both consumers over a shared input sequence and asserts identical decisions.

## A flagged inner-duplicate can sit inside a whole-function copy of the shared engine — widen the collapse

When a review flags a duplicated *sub-component* (a state machine, a formula) and points
at the SSOT primitive, check the *enclosing* function before swapping just the primitive:
it may be a verbatim re-implementation of the larger shared unit the primitive belongs to
(an inline equity-curve walker that re-rolls the whole `portfolio_curve` engine, not only
its breaker). Collapse to the engine (`portfolio_curve(..., breaker=...)`), not the
primitive — a net-negative diff removing the duplication the finding under-scoped. Inverse
of "Falsify a Shared Helper Finding" (which guards *over*-extraction). A sibling copy that
genuinely *can't* use the engine (different sizing model) still routes the primitive alone.
Prove either collapse behavior-preserving via the refactored-vs-original output diff above.

## Relocating a helper into a base/shared module is gated by import direction

Before moving a "duplicated" helper *down* into a shared/base module (`_common.py`, a `*_base`), check where it sits in the import graph — the move may be infeasible or unnecessary:

- **A top-of-graph composer can't move down — it's a circular import, not a low-value tidy.** If the helper imports from N sibling modules that themselves import the base, relocating it into the base inverts the graph and cycles. Composition helpers (e.g. `_combined_legs` calling `_bear_legs` + `_pyramid_legs`, each pulling from ~6 siblings) belong at the top, in the module that owns their domain; the base stays leaf-level (loaders / metrics / constants), often with an explicit "importable in isolation, no engine dependency" invariant the move would break.
- **Single-definition-imported-across-siblings already satisfies de-dup.** One `def` that N scripts `from sibling import helper` has *zero* copies to collapse — the consolidation goal is already met. Confirm real duplication (`rg '^def helper'` → >1 hit) before proposing the move; absent that, it buys only relocation, which the graph forbids anyway.

Inverse of the `TYPE_CHECKING` import-cycle fold (above): there, tight coupling says fold helpers *up* into a class; here a top-of-graph composer must *stay* up. See also "Deciding What NOT to Refactor."

## Scripted edits to a structured doc: replace in place, never rebuild the region

Rewriting a whole region (a contents map, a table, a frontmatter block) to fix a *derived* value inside it — a count, a total, an anchor list — silently drops whatever the rebuild loop didn't model. A "recount the map" pass that reconstructed the block via `splitlines()` → filter → `"\n".join()` deleted an entire section that lived at the region's boundary. Every write should instead be a targeted replace of a line you matched:

```python
assert text.count(old_line) == 1, f"ambiguous anchor: {old_line}"
text = text.replace(old_line, new_line, 1)
```

Three guards make it safe:

- **Assert nothing vanished** — diff the set of headings/keys before vs after and fail on any loss. This is what catches the bug; the transform itself always looks fine.
- **Make it idempotent** — a resolver that runs twice (retry, partial failure) must converge, not compound. Re-running a reconstruct-style pass turned one dropped section into a corrupted map.
- **Recompute derived values from the final content**, not by arithmetic on both sides' numbers — after a union merge, `ours + theirs` double-counts anything both sides added.

Write the invariant checker *before* the transform. Its real job is catching your own edit script, not the input; if it only ever runs after you're confident, it runs too late. Corollary: an assert on a substring (`"<<<<<<<" not in text`) is not an invariant — anchor it to structure.

## Cross-Refs

- `~/.claude/learnings/code-quality-instincts.md` — code quality signals that trigger refactors
- `~/.claude/learnings/process-conventions.md` — PR splitting and review process
- `~/.claude/learnings/git-patterns.md` — the `git grep` false-negative pair; proving a branch landed before deleting it
- `~/.claude/learnings/testing/testing-patterns.md` — test recipes for refactoring safety
- `~/.claude/learnings/python-specific.md` — `[dependency-groups].dev` + deferred imports for production-image dep exclusion (relevant when the new format introduces a heavy dep)
