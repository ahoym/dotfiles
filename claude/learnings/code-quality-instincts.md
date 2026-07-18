Fundamental practices that apply across languages and frameworks. These are the filters that should run on every line of code — during implementation, not just refactoring.
- **Keywords:** DRY, single source of truth, dead code, guard variables, log security, PII, enums, test coverage, domain isolation, naming, placeholder, UUID, sandbox, documentation security, source-of-truth reconstruction, generalization vs new paradigm, silent default tracing
- **Related:** ~/.claude/learnings/process-conventions.md, ~/.claude/learnings/refactoring-patterns.md

---

## "No layer owns this" vs "wrong layer owns this"

Architectural review heuristic: distinguish missing-safety-net (no layer enforces a constraint) from misplaced-safety-net (wrong layer enforces it). The remediation differs — missing requires adding a guard somewhere; misplaced requires a refactor. An addresser rebuttal "this layer shouldn't own X" does NOT resolve the finding if no layer currently owns X. Re-review must close the loop on which layer will own it, not just which one shouldn't.

## Verify "execution path untouched" claims for plumbing-layer changes

When a PR changes a translation/routing table (e.g., signal-to-symbol map) but claims the live execution path is untouched, verify the execution layer's behavior when the downstream resource is unconfigured. The execution layer typically gates on configuration; if the gate's failure mode is silent (skip vs raise), the plumbing change can produce unintended behavior in production. "Probably safe" isn't a merge gate for financial systems — verify or guard explicitly.

## Don't duplicate logic across modules

If a calculation exists in a utility, import it. Don't inline a copy — even if the copy is "just a few lines." Duplication means two places to update and two places for bugs to diverge.

## Single source of truth for definitions

Never define the same interface, type, constant, or enum in two files. One canonical location, re-exported where needed.

## Port intent, not implementation

When porting code from another repo, adapt to the target's structure. Don't carry over idioms that made sense in the original context but not the new one.

## Remove dead code aggressively during refactors

Refactor phases are opportunities to audit and prune. When adding new functionality, check for functions/constants the new code supersedes and remove them along with their tests. Net-negative line counts on feature PRs are a healthy signal.

## Reuse existing calculation functions instead of duplicating logic

When implementing new features, check if the calculation you need already exists in the codebase. Inline reimplementations diverge silently from the canonical version.

## Use named guard variables for multi-condition early returns

Instead of multiple separate `if ... return` statements, name each condition with a descriptive boolean variable and chain into a single guard. Documents what each condition protects against.

## Inline dict values when keys already describe them

Intermediate variables that duplicate dict key names add indirection without value. Inline the function call directly into the dict literal unless the variable is reused elsewhere or the key name doesn't describe the value.

## Never log authentication tokens or PII

Auth tokens logged at INFO level are a security vulnerability. PII in logs creates compliance risk. Downgrade level AND remove the sensitive value. Treat log statements containing secrets or PII as security bugs.

## Generic error messages for uniqueness constraint violations

Don't reveal which field caused a uniqueness violation (e.g., "email already exists"). Generic messages like "duplicate entry" reduce enumeration attack surface.

## Avoid unnecessary wrapper methods

One-line delegation methods add indirection without value. Call dependencies directly unless the wrapper adds caching, error handling, or other real behavior. Extends to service layers: remove indirection that doesn't add validation or transformation.

## Rename parameters to reflect intent, not implementation

When a parameter name describes implementation (`clientId` for what's actually an idempotency key), rename to match semantic role (`requestId`). Misleading names cause bugs.

## Name features for what they actually do

If the implementation is a single train/test split, don't call it "walk-forward analysis." Name for current behavior, not aspirational scope.

When you *rename* an aspirational name to match current behavior (`StrategyPipeline` → `OverlayPipeline` for a class that runs only the overlay chain) and the codebase genuinely has a future use for the old name, reserve it in the plan/design doc with a bridge note ("Phase 1's `OverlayPipeline`, widened to fold in the algo") instead of deleting it — the implemented artifact gets the honest name, the aspirational name stays earmarked for the phase that earns it.

## Add discoverability comments for cross-cutting behavior

When a global handler silently catches what domain-specific handlers previously handled, add comments pointing to the global one. Cross-cutting behavior needs breadcrumbs at the point of displacement.

## Domain isolation: keep conversion logic in the owning domain

When Service A needs data from Domain B, expose a method on Service B rather than reaching into B's repositories directly. Preserves boundaries and keeps transformation logic with the domain that understands it.

## Defer work that isn't needed yet

Don't add schema columns, endpoints, or abstractions for features that haven't been designed. It's cheaper to add later than to migrate away from the wrong one. "Do we technically need this?" is a powerful review question.

## Always include negative test cases

Happy-path-only tests are incomplete. Include not-found, invalid input, and edge case scenarios.

## Don't commit hardcoded test data in production code paths

Placeholder values (hardcoded IDs, sample UUIDs) in production code are merge hazards. Parameterize or remove with a TODO reference.

## Prefer enums over strings for fields with known value sets

When a field represents a fixed set of values, use an enum or equivalent. Makes the model self-documenting and prevents invalid values at compile time.

## Add comments explaining domain-specific constants

Constants that encode business rules (terminal status sets, cutoff values) need inline documentation explaining the "why" behind the value set.

## Update tests when API contract changes

When switching identity sources (e.g., request-param to JWT), tests must stop passing the old parameter. Stale test params are false documentation of the API surface.

## Log level demotion requires justifying where signal is preserved

When downgrading log levels, identify the alternative location where the information is still logged appropriately. Without justification, important signals disappear from production logs.

## Inline parameter documentation replaces verbose guideline sections

Instead of maintaining separate guideline sections documenting constructor parameters, add inline comments directly to the code. Co-located documentation reduces staleness risk and trims the guideline file.

## Eliminate duplicate entities through inheritance

When two dataclasses share core fields, create a base dataclass with shared fields and extend for specific attributes. Reduces duplication while preserving semantic distinction.

## Raise exceptions instead of returning None for invalid states

Returning `None` for invalid states is ambiguous — callers can't distinguish "no results" from a bug. Raise a specific exception to make failure explicit and let callers handle it.

## Name the primary method `run()` — demote secondary methods

The primary use case of a class should own the simplest method name (e.g., `run()`). Secondary methods get descriptive names. When a class has multiple public methods, the one representing the core purpose gets the clean name.

## Consolidation: each piece of knowledge in exactly one location

When the same content appears in guidelines, code comments, and documentation, consolidate to the most natural home. The single-source-of-truth principle applies to instructions and reference material, not just code.

## Replace real sandbox/environment UUIDs in committed documentation with placeholders

Real sandbox UUIDs (vault IDs, wallet IDs, organization IDs) committed to source control could overlap with staging/prod values and create confusion or security exposure. Treat sandbox identifiers as potentially sensitive — use clearly fictional placeholders like `<vault-id>` or `00000000-0000-0000-0000-000000000001` in committed docs.

### Use reported timestamps from external systems, not Instant.now()
When integrating with external systems (banks, exchanges, APIs), use the system's reported timestamp for event/transaction records. `Instant.now()` captures when your service processed the event, not when it actually occurred -- creating inaccurate timing data that compounds across retries, queue delays, and timezone differences. Fall back to `Instant.now()` only when the external system genuinely doesn't provide a timestamp. A missing timestamp from an external system that normally provides one is a signal worth investigating, not silently papering over.

### Explicit denomination fields on financial domain models
In multi-currency systems, add explicit denomination fields (e.g., `marketValueAsset`) to financial models rather than relying on implicit context. When a `balance` field could be denominated in any of several currencies, the denomination must travel with the value. Without it, consumers must infer the currency from context -- which breaks when the same model appears in different contexts.

### Remove unnecessary abstraction layers with single implementations
When an interface has exactly one implementation and no realistic prospect of additional ones, prefer using the concrete class directly. Indirection layers (e.g., a `Store` interface wrapping a single DAO) add cognitive load without providing polymorphic value. If a second implementation materializes later, extracting an interface is a straightforward refactor. The cost of premature abstraction (extra files, indirection, harder debugging) exceeds the cost of extracting later.

### Nested guard mis-scope: test orthogonal boundary conditions

Defensive guards often fail not because they're wrong, but because they're at the wrong level of the if/else tree. Author thinks about one anomalous case `(filled<0, remaining<0)`, places the guard inside that branch, ships. Misses the orthogonal case `(filled<0, remaining==0)` which takes a different branch and bypasses the guard entirely.

**Review heuristic:** for every new defensive guard, enumerate the 4 quadrants of its conditions. `(filled<0, remaining<0)`, `(filled<0, remaining>=0)`, `(filled>=0, remaining<0)`, `(filled>=0, remaining>=0)`. Confirm which quadrants the guard actually covers. If the guard's stated intent is "catch anomalous filled", it must live where all anomalous-filled paths converge, not inside one anomalous-remaining branch.

### A fetch-and-validate guard's scope follows where the value is *consumed*, not where it's fetched

A guard that skips/aborts on a bad input belongs at every site that *uses* the value to make a decision — not uniformly wherever the value is *fetched*. A live quote is fetched on every order attempt, but it's only *consumed* for sizing on buys and limit-pricing on limit orders. A market-sell *exit* fetches the price too (for proceeds) but doesn't price the order — gating it on the same "bad quote → skip" guard would strand the position open on a transient sentinel. Map the buy/sell × limit/market matrix and place the guard per-cell: buy→skip, futures→raise (fail loud on the delicate path), market-sell→never block. Leave a one-line comment at each *un*-guarded site stating the deliberate omission, or the next refactor "uniformly applies" it and breaks the exit. Sibling to "Nested guard mis-scope" (correct *level*) — this is correct *scope* across sites.

### `url.startswith(prefix)` is not URL allow-listing

`url.startswith("https://example.com")` passes for `https://example.com.evil.com/`. Without a path/separator anchor, prefix-matching a URL is a bypass class. Compare parsed components instead:

```python
from urllib.parse import urlparse
parsed = urlparse(url)
if parsed.scheme == "https" and parsed.netloc == "example.com":
    ...
```

INFO-level for loopback URIs (`127.0.0.1:N`), HIGH-level for any internet-facing OAuth redirect URI validation, webhook origin check, or CORS allow-list. Same class as path-prefix bypass (`/admin` vs `/administrative`).

### Transport-layer dataclasses don't carry behavior choice

When a dataclass identifies *who* (e.g., `Account` with `id`, `broker`, `limits_key`), don't add fields that select *what algorithm to run on it*. Coupling identity to behavior is a layering violation that bleeds business decisions into transport types.

### A magic constant can encode a hidden assumption about a sibling parameter

A tuning constant validated at one value of a *related* parameter silently breaks when that parameter varies — e.g. a `barsback=50_000` request cap sized for 5-min bars 400s at 15/30/60-min, where the same row count spans far more calendar time. When you see a magic number, ask "what *other* parameter's value does this implicitly assume?" Scope the workaround to the case it was validated for (guard it: `if unit != "Minute"`) rather than letting it apply universally.

Pattern: keep behavior selection at the entry point as `(identity, callable)` pairs. The loop collapses to `for identity in IDENTITIES:` once all converge on one behavior.

```python
DISPATCH = [
    (account_a, lambda: algo_v2()),
    (account_b, lambda: algo_v2(main_ticker="UPRO")),
]
for identity, behavior_fn in DISPATCH:
    run(behavior_fn(), identity)
```

## Sibling-field validation gap

When a function validates one field (e.g., `if AveragePrice <= 0: raise`), scan for which other fields share the same invariant. For numeric normalization, the answer is usually all of them — a guarded `AveragePrice` next to an unguarded `Quantity` is a bug waiting on bad input. Review heuristic when reading a guard: list the sibling fields in the same dict/struct and verify each.

## Constructor kwarg silently ignored after testability refactor

When adding optional kwargs that shadow env-var or config reads (e.g., `def __init__(self, client_secret: str | None = None)`), trace every consumer of the original source to verify the kwarg is actually stored on `self` and read from there. The shadow-and-discard pattern — kwarg accepted, validated as not-None, then discarded while consumers still read the env var — is easy to introduce when init grows. The bug looks correct (validation passes, no exception) but runtime silently uses the wrong value. Detection: when reviewing a constructor that adds DI seams, grep every reference to the original source and confirm it now reads from the instance.

## Pull the cause when redundancy looks suspicious

Code that looks redundant (restatement docstrings, repetitive validation, peer-mismatched imports) often exists because something enforces it: a lint rule, a "project convention," a legacy contract. Find the cause before proposing removal — treating symptoms leaves them to recur.

Examples:
- Ruff `D` (pydocstyle) enforces D102/D103, so authors satisfy with restatement docstrings (`"""Tests that <name>."""`). The rule is the cause; stripping docstrings without a `per-file-ignores` for `tests/**` lint-fails.
- A project's `from foo.utils.logger import logger` shared-logger pattern looks like a convention but loses per-module namespace (`getLogger(__name__)`). Peer-aligning to the smell compounds it; the canonical Python idiom is the right move even when it diverges from "convention."

Heuristic: when a reviewer flags redundancy, read what produces the pattern (lint config, shared utility implementation, historical PR). The fix is often at the cause, not the symptom — and sometimes the cause reveals the "redundancy" is load-bearing.

## Test-only state in production code signals wrong-level DI seam

Fields, branches, or error paths that exist solely to support test injection (e.g., a `_token_injected` flag gating a runtime "injected token expired and cannot refresh" branch) mean the seam was placed at the wrong abstraction level — production code shouldn't know it's being tested. Fix: inject the collaborator (Protocol + impls), not the data the collaborator produces. The flag and its branch disappear because production no longer distinguishes "real init" from "test init."

Detection: grep for `_*_injected`, `_test_*`, `_is_mock_*`, or error messages mentioning "injected"/"mock"/"test path." Each hit is a candidate for collaborator extraction.

## Env-discriminator default args are a footgun

For classes whose constructor takes an env arg distinguishing real-money from fake-money behavior (`sim`/`live`, `prod`/`staging`, `real`/`dry-run`), don't default it. Cost asymmetry argues fail-loud at the construction boundary — silently running on the wrong env can mean data loss, real losses, or worse. Make the arg required so callers state intent explicitly:

```python
# BAD — silent default, future copy-paste from a test fixture lands in sim
def __init__(self, *, env: str = "sim") -> None: ...

# GOOD — TypeError on omission forces the caller to pick
def __init__(self, *, env: str) -> None: ...
```

Pair with a positive test (`test_env_is_required` raising `TypeError` on `env=` omission) to lock the contract — removing the default is only half the fix; the test guards against future regressions.

Same logic for any boundary where the cost of the wrong choice is asymmetric: payment vs. dry-run, live trading vs. paper, prod DB vs. staging.

## Document non-leakage contracts on pluggable Protocol surfaces

When a wrapper exception inlines `str(exc)` from a pluggable backend (TokenStore, FetchAdapter, BrokerAdapter), the wrapper has a non-leakage contract that's invisible to anyone implementing a new backend. Document it on the Protocol's docstring, not just enforce it at runtime:

```python
class TokenStore(Protocol):
    """Protocol for OAuth token persistence backends.

    Implementations MUST NOT include credential material in exception
    messages. The manager drops the chain via ``from None`` when wrapping
    store failures, but the message body is preserved — a store that
    echoes secrets in `str(exc)` would leak through any handler that
    surfaces the wrapping exception's message.
    """
```

Belt-and-braces with the runtime fix (`from None` chain-drop on the wrapper). A runtime scrub catches today's known leak vector, but the Protocol contract teaches future implementers what the surface promises — they see the constraint at the API definition, not after a security review flags their backend. Same pattern applies to: adapter-injected log messages (must not echo PII), plugin error codes (must not leak internal state), custom comparator/equality functions (must be total / commutative if the consumer treats them so). Any time wrapper code trusts the Protocol's *behavior*, document the trust on the Protocol — not just in the wrapper's implementation comments.

## General-typed guard with specific-constant body = silent contract mismatch

Guard like `is_futures = trade.contract_root is not None` is general (any contract_root); body that hardcodes `MNQ_NOTIONAL_PER_CONTRACT` is specific. When the general case fires (e.g., NQ, ES), the body silently produces wrong results with no error. Either narrow the guard (`is_mnq = trade.contract_root == "MNQ"`) or parameterize the body. A flavor of "test the universal quantifier."

## Symmetric-fix scan after a targeted fix

A fix to one early-exit path in a loop (e.g., `continue` advancing a pointer in the futures branch) often needs the same fix in structurally analogous branches (the ETF branch). Reviewer's first pass typically flags the salient one; the addresser must scan for siblings — not just patch the cited line. Pattern: after reading a fix, grep for the same control-flow construct elsewhere in the function. "Bug class, not bug instance."

## Probe before encoding test anchors

Before asserting a date, holiday, library lookup, or external constant in a test, run a one-liner to verify rather than reasoning from spec:

```bash
python -c "from datetime import date; import holidays; print(date(2024,6,19) in holidays.financial_holidays('NYSE', years=2024))"
```

Prevents fictitious test data and discovers library behavior (does this calendar include Juneteenth? what year was it added?) before encoding into a parametrize table. Tests that anchor on wrong dates pass silently and rot — the assertion holds against your incorrect mental model, not reality.

## "Already in state X" guards must compare full identity, not partial

No-op guards on idempotent operations (`if already_in_X: return`) must compare every field that distinguishes a meaningful transition, not just one. Bug pattern: a futures position-rotation guard compared `direction` (LONG/SHORT) only, so `+@VXM` → `+@VX` (both LONG) silently no-op'd instead of rotating bases.

Lint smell: parsing a tuple and discarding fields with `_` immediately above an equality check on the kept fields:

```python
current_direction, _ = parse(current)   # discarded base
desired_direction, _ = parse(desired)
if current_direction == desired_direction: return  # missing base in compare
```

The `_` is a flag. If a parsed field participates in equality in any sibling code path, it usually belongs in *this* compare too. When in doubt, compare the full normalized form (the input string itself, or the full parsed tuple) — partial-equality bugs are silent and only surface when a previously-degenerate dimension (here: base symbol — always the same product before VX rotation landed) becomes meaningful.

Degenerate sub-case: the guard compares against a field that is *never populated* (`new_weight == last_weight` where `last_weight` is always `None`). This isn't partial-identity — it's a dead comparison that can never short-circuit (or always does), so the no-op guard silently does nothing. When reviewing a `new == last` guard, confirm `last` is actually written somewhere on a prior path.

## Don't reconstruct what the source-of-truth already computes

When the system-of-record (broker, database, external API) exposes an aggregate (account equity, sum, materialized view) that you currently compute by hand from its components, prefer reading the aggregate directly. Hand-rolled reconstructions silently drift when the components stop tracking the underlying truth — e.g. local `cashAtHand + position.market_value` worked for equities (cashAtHand tracks broker cash) but broke for futures (cashAtHand frozen at allocation, MarketValue is notional). The broker's own equity field was right both times. Pattern smell: any time a calculation locally mirrors what an SoR field reports, that mirror is a maintenance liability waiting for one regime to invalidate one of the inputs.

## When proposing a new approach, check if it's a generalization of the working case

If one branch of a system works and another is broken, before designing a fundamentally new mechanism for the broken case, examine the working case carefully. The working code may already be implementing the right pattern — just inlined, hand-rolled, or specialized. The smallest fix is often **promoting** the working pattern to use the proper primitive directly, which fixes the broken case as a side effect without introducing a new paradigm. Symptom of having missed this: feeling like you're adding a "second way to do P/L" / "futures-specific branch" / "new abstraction layer" — back up and ask whether the existing way is doing what the new way would do, just locally.

## Trace silent defaults when output is suspiciously zero/round

When a computed value lands on `0`, `None`, `[]`, or your input baseline exactly, suspect a silent default upstream. Common culprits: `next((x for x in xs if pred(x)), None)`, `dict.get(key, 0)`, `bal.get("Equity", 0.0)`, exception swallowed in a try/except. Trace which default produced the round number — the bug is almost always there, not in the math. Diagnostic: change the default to a sentinel (`raise`, `NaN`, a unique string) and re-run; if the symptom changes, the default was hiding the bug.

## Truth-by-construction indexes for growing directories

When a directory's contents change frequently (data files, generated artifacts, files arriving from multiple workflows), maintain its index by **regenerating it from on-disk state on every write**, not by hand. The index becomes a function of the directory; it can never drift. Pattern: writer walks the tree → renders the index → atomic-replaces. Examples: data fetcher always re-walks and rewrites a catalog at the end of every run; CI regenerates a manifest on each commit. Skip "last regenerated" timestamps if you want diffs to reflect only data changes — a freshness stamp creates spurious diffs every run while adding zero correctness signal (the per-row "last bar" / "last build" is the freshness signal you want).

## Cache layering: committed-stable + ephemeral-dynamic with one-way writes

When a system has both committed-to-git stable inputs (reproducible across commits) and dynamically-fetched data (broker/API/today's response), have one lookup function try the committed cache first, ephemeral cache second, dynamic fetch last. **Critical invariant: dynamic fetches write only to the ephemeral cache, never to the committed one.** Otherwise a fresh API call silently overwrites your reproducible fixture and tests start drifting. The committed cache stays ground truth, mutated only via an explicit operation (a fetcher script run, a vendor backfill). Per-key automatic preference means a single consumer can mix sources transparently — committed for keys that have it, ephemeral for the rest, no flag, no fallback chain to manage.

## Trailing-edge mid-formation bars in append-only caches

Append-only caches with `prefer="existing"` (or any "existing wins on overlap") merge policy cement any mid-period snapshot the previous run wrote. If the fetcher runs mid-session/mid-bar and writes the still-forming bar, the next refresh's *finalized* end-of-period bar is dropped — its `datetime` collides with the snapshot, and existing wins. The cache silently degrades to mid-formation state for that period forever.

Fix: drop existing bars whose timestamp is at/after the start of the currently-open period **before** the merge. Compute a per-Unit cutoff (start-of-today UTC for Daily, start-of-current-bucket for Minute, ISO-Monday for Weekly, first-of-month for Monthly), filter `existing` to bars `< cutoff`, then merge. Finalized prior-period bars stay protected; the trailing edge yields to the fresh fetch.

```python
cutoff_ms = _current_period_cutoff_ms(unit, interval)
finalized_existing = [c for c in existing if c["datetime"] < cutoff_ms]
finalized_fetched = [c for c in fetched if c["datetime"] < cutoff_ms]  # both sides
merged = merge_candles(finalized_existing, finalized_fetched, prefer="existing")
```

**Filter `fetched` too, not just `existing`.** Dropping only the existing side leaves a latent gap: a fetch path that *returns* the in-formation bar re-introduces it post-merge. Vendor "last N bars" queries (`barsback`) include the current forming bar; date-bounded queries (`firstdate`) often return only settled bars — so the bug stays invisible until the unfiltered path runs, then writes a partial trailing bar for that path's tickers only. The `< cutoff` drop on the fetched set is a no-op for the settled-only path and drops the forming bar for the other. (Manifestation: `financial/continuous-contract-data-quirks.md` → barsback vs firstdate.)

Sub-case of the "Cache layering" entry above — the one-way-write invariant doesn't help when the writer writes garbage early. Same hazard whenever a refresh policy biases toward existing on conflict and a refresh can run before the period closes.

## Two near-duplicate functions differing only in body work → callable-param helper

When two public functions share 90%+ of their body and differ only in one line of work (`json.dump(data, f)` vs `f.write(content)`, etc.), extract one private helper that takes a `write_fn` (or `body_fn`/`work_fn`) callable and pass the body-specific call as a lambda. Cleaner than a string-discriminator branch (`if mode == "json": ...`) because the caller's intent is a function, not a flag.

```python
def _write_atomic(path, write_fn):
    target = Path(path); target.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(prefix=target.name + ".", suffix=".tmp", dir=str(target.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f: write_fn(f)
        os.replace(tmp_path, target)
    except BaseException:
        try: os.unlink(tmp_path)
        except FileNotFoundError: pass
        raise

def write_json_atomic(path, data, *, indent=2):
    _write_atomic(path, lambda f: json.dump(data, f, indent=indent))

def write_text_atomic(path, content):
    _write_atomic(path, lambda f: f.write(content))
```

Pairs with the "Avoid unnecessary wrapper methods" entry — the inverse case. The 1-line wrappers stay because they document the public API + provide type signatures + are the import target. The shared helper is private and absorbs the ceremony.

## Keep a 1-line wrapper that carries non-obvious work or has multiple call sites

The "Avoid unnecessary wrapper methods" entry targets pure delegation (`def get_user(): return self._svc.get_user()`). Two situations where a small wrapper *is* worth keeping:

1. **Non-obvious work in the body.** `iso_to_epoch_ms(s)` looks like 1 line but encodes the `tzinfo is None → replace(tzinfo=UTC)` defaulting choice. Inlining duplicates the conditional at every call site or silently drops it (and the next inline copy will).
2. **Multi-call usage of a literal one-liner.** `epoch_ms_to_iso(ms)` is genuinely `datetime.fromtimestamp(ms/1000, tz=UTC).isoformat().replace("+00:00", "Z")`. Used once → inline. Used three times → keep the name; inlining duplicates the formatting choice (`.replace("+00:00", "Z")`) three places, so a future tweak has to be applied three times.

Filter: inline when the wrapper is *both* pure delegation *and* called once. Keep when either condition fails.

## Intent comments (WHY) vs narration comments (WHAT)

When trimming code-narrating comments, distinguish the two:

- **Keep intent.** `# Walk lower-priority source first so higher-priority overwrites on overlap` — explains *why* the loop is structured that way (priority semantics on overlap). The structure isn't obvious from the code alone.
- **Drop narration.** `# Source labels match parameter names so error messages name the offending argument directly` — restates a one-line decision visible from the code. The next reader will see `("new", new)` and `("existing", existing)` and connect the dots.

Filter: if removing the comment leaves the same teaching to a reader who reads the code, drop it. If the structure looks arbitrary without the comment, keep it. Agent-authored code tends to over-narrate the WHAT — this is a high-yield trim pass.

## Asymmetric policies between sibling readers — document once, point from helpers

When two readers of the same file/data shape have different error policies (fail-loud vs log-and-skip; halt-on-corrupt vs degrade-and-continue), don't duplicate the rationale on each helper's docstring — the policy is one invariant. Move the explanation to one shared owner (the public function the helpers are reachable through, or the module docstring of the file that hosts the lookup path), and leave a one-liner pointer on each helper:

```python
def _load_from_perpetual_daily(ticker):
    """Return perpetual candles for `ticker`, or None on miss/empty.

    Fails loud on corrupt JSON — see module docstring for the policy rationale.
    """
```

Same SSOT principle as code/types — the policy is a definition, and definitions have one canonical home. Readers of the public API see the asymmetry once; helper-level doc churn drops; future updates change one paragraph instead of N near-copies.

## Two-ledger divergence — parallel state systems must encode the same domain rules

When two systems track the same domain quantity (analytics ledger + cash ledger; orders DB + payments DB; cache + source-of-truth), they can drift if they encode different domain math. The bug is invisible until a downstream consumer reads the wrong ledger.

Diagnostic: trace which ledger each consumer reads. If sizing/decisions read ledger A and reporting reads ledger B, and A and B disagree, the system has internally inconsistent state. Tests of either ledger in isolation pass — only end-to-end runs that exercise the consumer surface the divergence.

Common shape: one ledger uses a domain multiplier (point_value, FX rate, scale factor), the other doesn't. Whichever side gets read by the *next* sizing decision becomes the rate-limiter on system behavior. Fix at the seam: either teach the dumb ledger the multiplier (couples it to domain), or settle the domain math externally and post the result as a normalized cash delta (keeps the dumb ledger asset-class-agnostic).

## Adding to default-iterated registries: verify before adding

Adding an entry to a list/dict iterated by default (`_DEFAULT_*` maps, ticker tables, plugin registries) makes iteration fail-fast on any failing entry — later entries get skipped. Verify in isolation (probe / dry-run) before adding to the default, or make iteration error-tolerant per-entry (try/except + WARN, continue).

## Respect input validators — survivor-of-rejection is often the worst sample

When a strict input validator rejects vendor data (negative prices, non-finite values, sentinel patterns), the rejection IS the diagnostic. Workarounds that bypass the validator to land the suspect data convert a loud-fail into a silent-correctness-bug downstream.

Two failure modes the validator-bypass pattern hides:

1. **Poisoned data persists in the cache.** A vendor sentinel (`-2³¹/100`, `NaN`, near-zero placeholder) committed to the data layer contaminates every downstream computation — returns, correlations, regression, anything that does arithmetic on the column.
2. **Single-regime survivor bias.** When the only data that passes validation is from a specific rally / crisis / regime, the validator has accidentally selected the worst possible sample for robustness testing — the analysis ends up testing strategies against the anomaly it wanted to stress-test against.

**Decision rule for rejected data:**
- Anchor at the post-rejection boundary if a useful clean window exists (years, not months).
- Omit the symbol/series entirely if the only clean window IS the anomaly.
- Never relax the validator to "let it through" without understanding what exactly is being let through.

The validator's failure is information — honor it.

## Dual-format store: every writer must write the new-format key, not just the legacy one

When a persisted store carries both a legacy shape (`investedPosition`) and a new multi-shape (`investedFuturesPositions`) during a migration, and the writer does a **partial merge** (keys absent from the payload are preserved), a writer that updates only the legacy keys leaves the new-format key holding stale data. A reader on the new key never sees the write. Symptom: a filled close cleared the legacy keys but not the new dict → the allocation reader still saw the position → re-sold it every tick (long→flat→short).

**Audit:** for each writer feeding a dual-format store, confirm it writes *every* format a reader consumes — mirror the completest writer (the equity persister dual-wrote both; the futures per-leg writers didn't). Partial-merge persistence makes the omission silent: no "missing key" error, just a preserved stale value.

## Reusing a named mechanism in a new context — trace its full lifecycle first

A review suggestion that says "just reuse `<existing mechanism>`" can still require a *second* change to make that mechanism work in the new context. A `SYNC_FROM_BROKER = -1` sentinel was a **read-time** marker — produced at parse, resolved before any persist — so reusing it on the *write* path as a "couldn't-confirm, reconcile next tick" marker silently failed: the persist filter kept only `q > 0` and dropped it on the very next write. The fix needed widening the filter too. Before adopting "reuse X," read X's full lifecycle (who writes it, who reads it, which filters/guards it passes) — a mechanism that's load-bearing in one phase can be silently discarded in another. Naming an existing mechanism ≠ it being one line.

## Audit both halves of a deliberately-mirrored function pair together

When two functions are written as mirrors (equity vs futures executors, sync vs async paths, read vs write sides), they drift — one gains a write/guard/branch the other misses, and the second-written half is the usual offender. Worse, a documented "deferred / for now / future schema bump" comment on the missing half makes a live bug look like an intentional TODO: an equity executor's missing `investedAllocation` write (churn every tick) hid behind exactly such a comment while the futures executor wrote its analogous key. Heuristic: when a function mirrors another, diff them line-for-line — every `persist`, every dry-run/`effective_execute` gate, every state write must appear on both sides or have a stated reason not to. A "deferred" comment is not such a reason until you've confirmed the read side tolerates the missing write.

## Cross-Refs

- `~/.claude/learnings/process-conventions.md` — complementary process-level patterns
- `~/.claude/learnings/refactoring-patterns.md` — refactoring methodology
- `~/.claude/learnings/financial/vendor-divergence.md` — vendor-specific validation patterns relocated from this file
- `~/.claude/learnings/financial/continuous-contract-data-quirks.md` — concrete instance of the validator-respect pattern in continuous-contract futures data

## Reviewer-Asserted Invariant → Retire Sibling Defensive Checks in the Same Commit

When a reviewer asserts an invariant (e.g. "make this parameter required, not `Optional`"), honoring it usually means more than the one line they pointed at: grep for existing defensive checks that guard against the now-impossible violation (`if x is not None`, null-coalescing, fallback branches) and retire them in the **same commit** — even when they live in a different file than the comment. A required invariant is only real once every consumer stops guarding against the null that can no longer occur; leaving the guards in place ships a contradiction (the type says "always present," the code says "might be absent"). Likewise, two comments on two files describing one coupled API change should be addressed together so neither half is left half-migrated. Surfaced: PR #232 — a `run_spec: RunSpec` "make required" finding on one file required retiring a now-dead `if output.run_spec is not None` guard in a different script.

## "Reduce the nesting" ≠ collapse resource guards

When flattening a nested `try`/`if` pyramid, separate two kinds of nesting. **Control-flow nesting** (a decision pyramid like `if not None` → `try int()` → `if fresh`) collapses cleanly: extract the whole decision into a `_helper(...) -> bool` that returns early at each non-match branch, then call it as a single guard (`if self._adopt(snapshot): return`). **Resource-management `try`/`finally`** (one block per resource — file handle, advisory lock) is *not* accidental nesting; keep one block per resource, since collapsing them trades a real cleanup guarantee for cosmetic flatness. State the distinction in the method docstring so the next reader doesn't "unnest" the resource guards.

## A zero/positivity guard on an extremum metric silently excludes the extremes

A `if denom > 0:` (div-by-zero) or `if x is not None:` guard wrapped around the update of a worst-case metric (`if util > worst_util: worst_util = util`) drops exactly the cases the metric exists to surface — the wipeout where `equity <= 0` (infinite utilization) skips the `worst_util` update while still counting as a breach in a sibling counter. The headline extremum then reads optimistic and disagrees with the breach count. Fix: map the degenerate input to the extremum's sentinel (`util = float("inf")` when `equity <= 0`) so the metric and the counters agree, instead of excluding it. Review heuristic: when a guard protects an arithmetic op that feeds a min/max, check whether the guarded-out branch *is* the extremum.

## Refreshing a superseded index row: neutralize the stale lead, don't just append

A curated index/TL;DR whose convention is "append a correction, don't rewrite history" still misleads when the **lead** is a bold present-tense claim that is now false (`**X is now the default**`) — a reader sees the prominent stale claim before the correction trail below it. Fix the tense: reframe the original as history (`Original conclusion: **X was made the default**`) and mark the row `SUPERSEDED`, keeping the appended ⚠️/✅ correction. Neutralizing a false present-tense lead isn't "rewriting history" — it stops a stale claim from reading as current.

## Merge-induced parallel-promotion orphan

When a merge pulls in another branch's version of an abstraction you also built (both independently promoted the same boilerplate), conflict resolution usually repoints every consumer to one version — leaving yours an orphan whose *functions* have zero callers while only a thin slice (e.g. constants) stays imported. Collapse to the consumed slice: lift the still-used names into the kept module, repoint, delete the rest. Two traps: (1) a function in the orphan that drifted during its parallel life is a latent bug, not just dead code — e.g. a loader missing a leg/param added meanwhile `KeyError`s on first use; (2) before deleting, `git grep` each orphaned symbol to confirm zero consumers **and** that it's a strict subset of a kept-and-used helper (`mnq_algo == make_mnq_algo(plz_algo_v2)`), so the deletion provably loses nothing. Sibling to "siblings-as-versions" and "generalization of the working case" — the merge is what creates the duplicate here.

## Verify a shared-file single-writer invariant from the deployment artifacts before documenting it

Before writing "assumes single-threaded/single-writer access" on a whole-file read-modify-write (or deciding it needs no file lock), confirm the invariant from the actual deployment — don't assume from the in-process threading model. Two artifacts settle it: (1) the container/orchestration spec (`docker-compose.yaml` volume mounts) — *which* services mount the shared file; (2) the process/iteration model — does one process drive all entities sequentially (`for x in ACCOUNTS`) or is it one-container-per-entity? Single-writer holds only when exactly one process mounts and writes the file. A docstring claim like "one container per account" can be imprecise (it's often one-per-*broker*, looping multiple accounts) — read the compose mounts, not the comment. If a concurrent-writer topology is possible, the RMW needs a file lock + re-read under lock (or atomic rename), not a docstring.

## A module-move "for cleaner deps" drags in the *whole* module its new collaborator lives in

When a review suggests moving function `f` from module A to module B "for a cleaner dependency direction," check what B would actually `import` — the entire module the named collaborator lives in (and its transitive deps), not just the symbol. Moving `f` to B because B owns its output / 2-of-3 collaborators can still be wrong if `f`'s remaining collaborator lives in A: B then imports *all* of A. Worked example — a stdlib-pure spec module (`sizing.py`: only `math`/`Decimal`) was proposed as the home for a `symbol → tick` resolver because it returns `spec.tick_size`; but the resolver also needs `parse_contract` from `roll.py`, which imports `BrokerAdapter`/`Account` — so the move would have dragged the broker/account graph into the foundational module and inverted the single `roll → sizing` edge. Keep `f` where its heaviest-coupling collaborator lives when that preserves one low→high edge and keeps the foundational module import-light. The deciding test is the actual import list, not which module the output "feels like."

## A format-classifier that runs before its validator has only borrowed safety

A pure helper that classifies input by *format* to pick a side-effecting action (wire `TradeAction`, route, dispatch key) and runs *before* the validator that rejects malformed input is correct only because the validator runs downstream — the safety is borrowed, not intrinsic. Implications:

- **Single-source the shared shape.** If the classifier's pattern and the validator's pattern are separate literals encoding the same domain shape, derive both from one sub-pattern. Separate copies desync silently: a one-sided widening of the validator (extra root char, new code, wider year) sends a now-valid input to the classifier's *default* branch — wrong action, not a clean reject. Extraction beats a guard test that pins them equal — it makes desync structurally impossible rather than detecting it after the fact.
- **Document the precondition, don't re-assert it.** State on the helper that callers pass a validator-valid value and which branch is the deliberate default. Don't add a re-validation assert — it's a pure internal helper, not an I/O boundary (defensive-at-boundaries, trusting-inside). If the call order is ever reorganized so it sees unvalidated input, re-validate at *that* new boundary.

## A lossy/derived label used as a lookup-dict key silently selects the wrong object

A `{label: obj}` dict whose key is a *display/truncated/rounded* label collapses two distinct inputs that format to the same string — the second overwrites the first, so a later `dict[label]` re-lookup returns the wrong object with no error. Carry the object alongside its row (`scored.append((row, obj))`, sort/filter the pairs, select `obj` directly) instead of re-keying by the label. Worked example: a grid-sweep holdout keyed `{_grid_label(cell): scenario}` where `_grid_label` does `int(reclaim*100)` — two cells truncating to one label scored the *wrong* cell on the unseen test half. Latent until the lossy fn actually collides, so it survives tests that use a non-colliding grid. The label is fine for *display*; the bug is reusing it as an *identity key*. Sibling to "Already in state X guards must compare full identity" — both are partial-identity-key failures, here on dict insertion rather than equality.

## Reconcile a measured-vs-recommended value by relabeling, not recomputing, when the refined numbers already exist

When a doc's headline figures were computed at a parameter the analysis later refined away (an inherited default the sweep rejects), and the refined value's numbers already live elsewhere in the doc, reconcile by **labeling the headline's provenance + pointing to the refinement** rather than re-running the headline. Recomputing cascades through every cross-reference and can re-introduce the over-pinning the analysis itself warns against; relabeling keeps each number attributed to the config that produced it. Either way, fix the contradictory *conclusion* statements ("X is defensible" when the sweep picked Y) — those are the actual bug, not the headline's existence. Sibling to "Refreshing a superseded index row: neutralize the stale lead."

## Make a sort NaN-safe in the key, but preserve the existing tie-break

A NaN sort key has an *undefined* position (NaN is neither `>` nor `<`), so a
`maxdd==0` / `calmar==nan` cell lands anywhere and differs run-to-run. Fix it in the
key — `key=lambda x: x.k if x.k == x.k else float("-inf")` parks NaN last under
`reverse=True`. **Don't also add a secondary key the original lacked** (`(k, label)`):
a stable sort's equal-key ties hold *insertion order*, which is often a parity
contract — a new key silently reorders genuine ties, and under select-the-first
(`eligible[0]`) changes *which* element is picked on a tie. Document the
insertion-order tie-break rather than changing it. Siblings: "A zero/positivity guard
on an extremum metric silently excludes the extremes" (sentinel-map the degenerate
input); `python-specific.md` → "a NaN value used as a comparison anchor is sticky."

## Verify a degenerate/empty state is reachable before testing or guarding it

Before adding a test or guard for an empty/degenerate state, confirm the system's
own writers can produce it. If every writer skips-on-empty or deletes-on-empty
(`write_candles([])` writes no partition; `replace_partition(…, [])` deletes it),
a hand-built artifact for that state exercises a path production never reaches.
Check too whether an existing test already covers the *reachable* branch via a
different trigger — a `mkdir dir/` + read that returns `[]` already hits the same
`if not rows: raise` branch a zero-row file would, so the "untested branch" is in
fact tested. Sibling to "Adding to default-iterated registries: verify before
adding" and "Respect input validators" — reachability first, then coverage.

## An error/log message string is a soft API surface — grep the literal before rewording

Out-of-band log/alert tooling greps error-message literals, so changing the
wording of a raised or logged message is a soft API change. Passing tests don't
prove safety: they typically substring-match a *stable keyword* (`non-finite`),
not the full phrasing, so a reworded prefix (`Balance.Equity is non-finite` →
`<id>: Equity is non-finite`) slips through green while a downstream grep on the
old literal breaks silently. `git grep` the old phrasing across the repo before
rewording or harmonizing message shapes; if nothing keys on it, the change is
free — but verify, don't assume.

## A guard whose trigger overlaps a legitimate steady state must WARN, not raise — especially in a fan-out loop

When a proposed guard fires on a condition that *also* occurs in normal
operation (an empty fetch is both a vendor-regression signature *and* the
routine idempotent "no new data" outcome), a hard `raise` turns the steady state
into a failure. Worse, inside a per-item fan-out (multi-ticker sweep, batch job)
a raise aborts every remaining item — the per-item-batch-abort anti-pattern.
Scope a WARN to the narrow anomalous slice (`bond + Minute + zero-bars`) so the
regression surfaces in logs without breaking the legitimate path or
false-positiving; reserve `raise` for conditions that are *never* legitimate. A
reviewer asking to "convert silent staleness into a failure" doesn't mean a hard
raise — a loud WARN is the failure-to-notice fix when zero is sometimes normal.

## Required keyword-only vs sentinel-`None` for a param used by only one branch

For a param that feeds only one branch (`interval` only matters when `unit ==
"Minute"`), required keyword-only (`*, interval: int`) makes omission a
`TypeError` at call-binding — caught even in runs that never hit the branch —
whereas a sentinel (`int | None = None` + raise inside the branch) lets
irrelevant-branch callers omit cleanly but only fails at runtime when the branch
executes. Choose required-keyword-only when every caller already holds the value
(the pipeline threads `(unit, interval)` everywhere, so "always state it" costs
nothing and buys the stronger call-time guarantee); choose the sentinel when
forcing a dummy on callers that ignore it would mislead readers into thinking it
matters there. Either way, pair the removed default with a positive
`pytest.raises(TypeError)`/`ValueError` test to lock the contract. Sibling to
"Env-discriminator default args are a footgun" (required vs defaulted) — this is
the next axis: *how* to enforce required-ness.

## A tolerant and a strict restore path must agree on the *safety* invariant, not just tolerate differently

A state machine with two deserializers — a tolerant one (degrade gracefully, never crash the loop) and a strict one (fail loud on a bad blob) — may legitimately differ on *tolerance* (missing keys → pristine vs. raise) but must still agree on every *safety* invariant. A leg/tenant/owner discriminator that `to_dict` **always** co-writes with the state is one: because it's co-written, any blob carrying state *without* it is provenance-unknown (a hand-edit, or a cross-owner blob whose stamp was stripped) — never a genuine record your own code wrote. The tolerant path must therefore fail safe to un-armed (ignore the stateful slice, re-baseline + warn), not silently inherit a money-affecting latch; the strict path raises. Discarding it loses nothing real *because* genuine records always carry the stamp. A blob with no state at all is still a clean first run → pristine, no warning. Sibling to "Dual-format store: every writer must write the new-format key" — both turn on "what does my own writer always emit?"

## A durable commit gated on a coarse success signal records a false state — and the fail-safe drop must still be loud

Before committing durable state on `if f() is True:`, check what that `True` *means*. A submit/orchestrate call (`place_order`, `execute_*`) returns `True` on *submission*, and a "treat a transient empty read as already-flat" path returns `True` with the side-effect never having run — so even "persist-after-confirm" records a false "done" when the confirmation signal is coarser than the side-effect. Closing the gap needs a *verifying* read (position/fill query), not a richer boolean. Separately: when you correctly *don't* persist/act because confirmation failed (safe direction — re-attempt next tick), still alert loudly — a money-moving decision made and not executed is operator-relevant even when it fails safe. Fail-safe ≠ silent. Sibling to "A guard whose trigger overlaps a legitimate steady state must WARN, not raise."

## Making a previously-optional field load-bearing exposes fixtures that omitted it

When a review makes an optional/ignored field required or load-bearing (a discriminator, a now-validated key), the existing tests seeding fixtures *without* it were exercising a shape production can't actually produce — your own writer always co-writes the field. Two-part fix: add the field to those fixtures (production's always-written shape) so they keep hitting the intended reload/validation path, and add a *new* test for the now-explicit behavior on the genuinely-fieldless input. Green tests after the change are necessary but not sufficient — confirm the updated fixtures still reach the branch they were written to cover. Sibling to "Verify a degenerate/empty state is reachable before testing or guarding it."

## Promoting a private value type to public: value tier, not beside its consumer

When a private enum / frozen-dataclass (a pure value type, no behavior) graduates to public, resist the natural pull to co-locate it with the Protocol/module that consumes it — put it in the models/value tier with the other domain value objects. That keeps it import-light, avoids same-layer coupling (the consumer imports *down* to the value), and lets a future second consumer import the canonical type instead of reaching into the first consumer's layer. Sibling to "A module-move 'for cleaner deps' drags in the *whole* module its new collaborator lives in" — both turn on keeping value/foundational modules import-light.

## A "see X for current numbers" staleness banner is a deferred-refresh IOU

A doc carrying a banner like "figures below predate the re-prove — see `results/*.txt`" has *deferred* a refresh, not avoided it. Removing that banner in a later cleanup obligates completing the refresh in the same change — otherwise honestly-flagged-stale silently becomes unflagged-stale, which is strictly worse. Before dropping any "provisional / see source" disclaimer, diff the doc's figures against the source it points to and refresh them.

## Verifying a figures-doc refresh: a numeric diff catches numbers, only a read catches a backwards claim

Two complementary checks after refreshing or tightening a doc full of figures. (1) A numeric-token multiset diff proves no figure changed or appeared: `comm -13 <(git show HEAD:f | grep -oE '[0-9.]+' | sort -u) <(grep -oE '[0-9.]+' f | sort -u)` — empty means no new number. (2) But a regex/numeric sweep is blind to an inverted *qualitative* conclusion ("≥2-rung cuts drawdown" when the data now says 0/9; "PF thin" when it's fat) — read each summary cell. A grep-only sweep reports "clean" while a flipped verdict survives.

## Reconciling figures across several docs in parallel — grep leftovers + cross-doc consistency

When N docs cite the same re-proved numbers and you fan out one agent per doc, two failure modes
the per-doc pass misses: (1) **stale leftovers** — `git grep` each old headline figure (old
capstone $, old PF range) across ALL docs to catch numbers an agent skipped; watch for regex-dot
false positives (`6.1` matches `2026-06-19`, `5/6` matches `35/606`). (2) **cross-doc divergence**
— agents reading the same tables independently round or scope ranges differently (one cites the
recommended slow-TF cells, another the full sweep), so spot-check that the shared headline figures
agree. Extends "Verifying a figures-doc refresh" above — numeric-diff + read-verdicts, now applied
across the whole doc set.

## Duplicated prose of load-bearing config: keep-in-sync pointer, don't always collapse

When N docs restate the same load-bearing config (a signal→symbol map, a status set, an env table) that can't auto-generate the prose, "consolidate to one home" is the *wrong* fix if the copies serve genuinely different purposes — a per-symbol glossary vs. a signal-translation flow — because collapsing one into a pointer kills its standalone value. Add an explicit `single source of truth: <module::SYMBOL> — keep in sync` note under *each* copy instead; reserve true consolidation for verbatim, purpose-less duplication. Cite any load-bearing *figure* (a measured beta, a threshold) in exactly one copy and point the others at it, so the number itself doesn't re-duplicate. Boundary case of "Consolidation: each piece of knowledge in exactly one location" — same family as keeping a 1-line wrapper that has multiple call sites.
