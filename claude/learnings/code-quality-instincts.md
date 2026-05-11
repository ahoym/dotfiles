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
merged = merge_candles(finalized_existing, fetched, prefer="existing")
```

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

## Cross-Refs

- `~/.claude/learnings/process-conventions.md` — complementary process-level patterns
- `~/.claude/learnings/refactoring-patterns.md` — refactoring methodology
- `~/.claude/learnings/financial/vendor-divergence.md` — vendor-specific validation patterns relocated from this file
