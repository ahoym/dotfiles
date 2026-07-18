Cross-language test design patterns: contract tests, fixture origin, translation-layer testing, mock fidelity, and test-existence heuristics.
- **Keywords:** contract tests, fake-drift detection, fixture origin, mock coupling, mock fidelity, translation-layer tests, adapter tests, test isolation, encoded fields, cross-implementation fixtures, recorded fixtures, golden files, production consumers, DI seams, test value vs internals, --update re-bless, golden baseline gate, stability vs correctness
- **Related:** ~/.claude/learnings/code-quality-instincts.md, ~/.claude/learnings/dependency-injection-patterns.md

---

## Cross-Implementation Test Fixtures

When server and client independently implement the same encoding (e.g., server uses `Buffer.from().toString("hex")`, client uses `TextEncoder` + `Array.from`), test both against **shared known input/output pairs** to catch drift.

**Pattern:**
- Define a set of canonical fixtures: `"KYC"` → `"4B5943"`, `"AML Check"` → `"414D4C20436865636B"`
- Server test suite asserts `encodeServerSide("KYC") === "4B5943"`
- Client test suite asserts `encodeClientSide("KYC") === "4B5943"` (same expected value)
- If either implementation drifts, its tests fail independently

**Why not share code?** Server-only APIs (e.g., Node `Buffer`) aren't available in the browser. Separate implementations are correct — but they need to agree on outputs.

**When to use:** Any time you have parallel encode/decode, hash, or serialization logic across server/client boundaries. Common in: credential encoding, currency formatting, signature verification.

## Prefer local payload over API response to reduce mock coupling

When code generates a value (e.g., a reference ID) and sends it in an API request, read it back from the local payload object rather than from the API response. This avoids forcing every test mock to echo back that field.

```typescript
// BAD — reads from API response, every mock must include referenceId
const response = await apiClient.createPayment({ payload: [paymentData] });
const payment = response.payments[0];
return { reference: payment.referenceId };

// GOOD — reads from local payload, mocks don't need to include it
const paymentData = buildPaymentPayload(...);
const response = await apiClient.createPayment({ payload: [paymentData] });
return { reference: paymentData.referenceId };
```

The example is TypeScript but the principle applies to any language: adding a field to the response path requires updating every test mock that returns that response. Integration tests using HTTP-level mocking are especially painful to update. The local payload is deterministic and already in scope — no reason to round-trip through the mock.

## Test Isolation: Mock Data Must Match Runtime Encoding

When mocking responses that contain encoded fields (e.g., hex-encoded currency codes), the mock value must match the encoding the code under test will compare against. If the code encodes `"USD"` as a 3-char passthrough, the mock must also use `"USD"` — not the 40-char hex form.

This causes tests that pass in isolation to fail in the full suite when encoding comparison logic doesn't match mock data. The fix is to derive mock fixtures from the same encoding the production code uses, or to assert in normalized form.

## Contract tests against recorded real responses (fake-drift detection)

When a test suite uses `FakeAdapter`-style mocks for external services, unit tests pass even after the real API adds fields — the fake goes stale silently, and prod fails on the first call that reads the new field. Contract tests close the gap:

1. `scripts/record-fixtures.py` (or equivalent in any language) — a small harness that hits the real API (SIM/staging, never prod without explicit ack) and writes responses to `tests/fixtures/<provider>/<endpoint>.json`
2. A contract test loads each fixture, runs through the **real** adapter's normalization path, and diffs the output against a committed golden file
3. When the real API adds a field: re-record the fixture → golden diff → fake must be updated to match before CI is green again

Invest when: any codebase where a mocked adapter layer hides a real protocol boundary. Cost is one recording script plus committed fixtures; payoff is catching API drift on the next CI run after an upstream change, not three releases later in prod. Especially valuable for trading systems, payment integrations, any adapter whose input shape is externally owned.

## Adapter mocks: don't fabricate the response shape

When the test author writes both the mock fixture *and* the code reading it, an aligned field-name mistake survives every test. Mock returns `{"accountId": "..."}`, reader reads `data["accountId"]`, real API returns `accountNumber` — green test, broken adapter. Contract tests catch this eventually (see "Contract tests against recorded real responses"); fixture origin prevents it.

Ground mock fixtures in real API output: copy from a recorded response, the upstream SDK's own fixtures, or a docstring example pasted from the API docs. Never invent the shape from the code-under-test.

## A self-authored fixture can't close a "does the live API ever emit X?" finding

During review, a fixture you wrote is not evidence about live external behavior — it asserts your own assumption of the shape, so using it to confirm a property like "the 4xx body never echoes the account id" is circular. When a security/correctness finding asks you to confirm what a live service does or doesn't emit and there's no recorded fixture+golden pair, report what the in-repo fixtures show, state the no-recorded-golden caveat explicitly, and escalate the disposition — don't claim "verified clean." The two honest sources are a recorded real response or the vendor's API docs; absent both, it's a hypothesis, not a verification. Sibling to "Adapter mocks: don't fabricate the response shape" — same fixture-origin gap, at review/verification time rather than test-construction time.

## Translation-layer tests must assert post-translation values

When an adapter translates one identifier into another before calling the wrapped client (`account_id` → `account_hash`, `user_id` → `external_uid`), passing the already-translated value to the test makes the translation untestable — `assert_called_once_with("hash_x")` passes whether translation runs or is a no-op. Pass the *pre-translation* value, assert the *post-translation* value reaches the client:

```python
adapter, client = make_adapter(account_hashes={"acct_a": "hash_a"})
adapter.get_balance("acct_a")  # pre-translation input
assert client.get_account.call_args.args[0] == "hash_a"  # post-translation
```

The example is Python but the pattern is generic: any adapter that rewrites identifiers before delegation needs the same test discipline. Add at least one negative test: unregistered id raises a clear error rather than silently passing through.

## Tests against a class with no production consumers test internals, not value

Before extending test coverage on a class, grep for production callers (`rg ClassName\(`). If only tests instantiate it, the tests are validating internals — and the DI seams baked into the constructor encode an imagined shape, not what production wiring will actually need. Symptom: constructor sprouts optional injection params labelled "for testability" while no production call site supplies them. Surface the missing production consumer first; design seams against real call sites.

## Plan Docs Should Specify Mock Expectation Values

When writing plan docs that include integration/router-level tests, explicitly state which env var values mocks should match — default values from the code's env-var reads or values from the test env file. This prevents a debugging round where tests fail because mock expectations use test-env values but the code under test reads module-level singletons initialized with defaults. (See `pytest-patterns.md` for the module-level singleton mechanism that makes this trap acute in Python.)

## Equivalence-test a path migration: drive both paths, compare observable outputs

When production flips from a battle-tested code path to a new one and both stay reachable (refactor, rewrite, dual-dispatch), pin behavior with a test that runs *both* against identical inputs and asserts the same **observable outputs** — the orders placed, API calls made, rows written — not internal/persisted state, which legitimately differs. Catches divergences hand-review misses; an assertion that flips from `==` to `!=` also cleanly pins a *known, intentional* difference so it can't regress silently.

Use a stateful in-memory store, not a static `return_value` mock, whenever either path does read-modify-write across sub-steps (e.g. sell → persist cash → buy, where the buy sizes off *post-sell* state). A static mock feeds every read the initial value and silently misrepresents the second-stage sizing.

## Dispatch-only tests prove routing, not behavior — don't count them toward regression coverage

A test that patches out the unit-under-test and asserts it was invoked (`@patch("mod.execute"); ...; mock.assert_called_once_with(target)`) covers the *router's dispatch decision*, nothing about what `execute` does. When auditing whether a path is safe to refactor, separate dispatch/routing tests from behavior tests — a function can look "covered" by many tests that all mock it away. To find what a function is *actually* exercised against, grep for un-patched call sites and inspect the argument shapes: `rg "execute_futures_allocation\(" tests/ | grep -v patch` revealing only single-leg `{"+@MNQ": 1.0}` calls means multi-leg/close paths are untested despite a high test count.

## A passing suite doesn't prove a new feature is wired into production

An opt-in feature (new optional constructor param, env flag, sidecar lock path) can merge with green tests yet stay **dormant in prod** — the unit tests construct the object *with* the param, the composition root constructs it *without*. The suite passes on a wiring the production code doesn't have. After adding such a feature, grep the production call sites, not just the test run: `rg "OAuthTokenManager\(" --type py | grep -v test` — if the param appears only under `tests/`, the feature is off in prod. Pairs with "Dispatch-only tests prove routing, not behavior" above.

## A routing test is the right tool to pin an overlay↔core shared seam

The "dispatch-only tests don't prove behavior" caveat has a legitimate inverse: when an overlay reuses the core's *exact* dispatch helper (see refactoring "Detach an opt-in feature into a pure core + self-contained overlay"), a routing test is precisely the guard that keeps the two from diverging. Leave the shared seam **un-mocked**, patch the leaf branches as sentinels, and assert the overlay routes the resolved decision through the core's real dispatch (`patch _bullish_branch/_bearish_branch; wrapped(ds); assert result is the bullish sentinel`). Its value is the divergence contract, not regression coverage — don't double-count it as behavior coverage.

## Decouple Test Inputs from Global Constants, Don't Re-baseline Outputs

When a change to a shared constant (leverage, rate, notional, tax bracket) breaks integration tests whose expected values were *incidental* — the test picked an input that happened to produce a round output under the old constant — fix the **input** to reproduce the originally-designed scenario, not the **output** assertions.

Re-baselining outputs silently changes what the test exercises: a "clean single-fill order" test bumped 1→2 units becomes a partial-fill test; a "no-op when unchanged" test becomes a resize. Instead, back-solve the input (`equity`, quantity, seed) so the new formula yields the count the scenario was built around, and leave the constant's own unit tests to cover the new arithmetic. This keeps state-machine/scenario tests decoupled from the formula so the next constant change doesn't break them again.

## Guardrail-test a live/production default: pin the literal once, reference the symbol everywhere else

When a constant encodes a live-config default (the leg that actually trades, a production rate/flag), pin its literal value in **exactly one** test as a review tripwire — comment it "don't DRY this away; it forces review of any live-config change." Every *other* test asserts against the source-of-truth symbol (`default_tlt_target()`, or a value derived from it), so flipping the default touches only the guardrail, not N hardcoded copies. Gives both: a deliberate flip is a one-line, obvious-in-diff change, and an *accidental* flip still trips the guardrail.

## Never use real (or real-looking) data in tests — even when the real value is already committed elsewhere

Test fixtures must use scrub fakes for account numbers, hashes, balances, tokens, PII — *even if* the same real value already sits in a committed config/data file or in pre-existing tests. Rationale: test code is read, copied, and pasted far more than config, so one real id in a test seeds many more; "it's already committed in config" is not a license to repeat it. Reuse the project's documented fake shapes (sequential ids, `FAKE_*` hashes, round balances) rather than inventing a new one per file. Distinct from "replace real UUIDs in committed *docs*" — same principle, but test code is the higher-leakage surface.

## Don't widen a parity/golden oracle's *input* domain into where the new code intentionally diverges

When you add guards/behavior the legacy reference lacks (input validation a closure never had, a clamp the original skipped), feeding the now-rejected inputs through the parity oracle asserts a *by-design* divergence — the new code raises where the reference silently computes. Keep the oracle on the inputs where both genuinely agree, and pin the new behavior with separate dedicated tests. Complements "pin behavior with a both-paths equality test" above: that pins *output* divergence with a flipped `==`→`!=` assertion; this keeps the oracle's *input* domain off the divergent region entirely rather than encoding the divergence into it.

## A bit-identical/parity invariant only validates paths whose triggering inputs appear in the window

"Reproduces the baseline exactly on window W" proves nothing about a changed code path whose *triggering inputs are absent from W*. A study claimed a re-implemented algo was "TEST-window bit-identical" — but the one changed branch (a QQQ dip gate) had its sole triggering day in the TRAIN window, so the invariant validated the date-shift corrections while leaving the formula change completely unexercised. Before trusting a parity claim, enumerate which changed paths the window's inputs actually reach; guard the unreached ones with a separate targeted assertion. Sibling to "Don't widen a parity oracle's input domain" — that trims over-coverage, this catches under-coverage.

## A merge that changes committed inputs voids a pre-merge numeric parity baseline

A committed-number baseline ("128.302% CAGR / 385 trades") is a valid parity gate only while the *inputs* are fixed. A merge that appends committed data (new bars) or touches the engine legitimately moves those numbers — so a post-merge re-run differing from the pre-merge baseline is **not** a regression, and chasing it wastes effort. Re-scope the post-merge check to what the refactor actually claims: algorithm-equivalence (the renamed/moved function is the same code) + input-independent asserts (a fidelity probe asserting `helper == production` each bar), not byte-identical headline numbers. Sibling to "Decouple test inputs from global constants" — there a constant moved under a test; here the data moved under a baseline.

## A parity/equivalence test is vacuous unless the varied dimension is read — at the same cursor

A test that builds two inputs differing in dimension D and asserts equal output proves nothing if no code path reads D: it passes with the inputs nulled, swapped, or made equal. Three shapes + the general tell:

- **Nobody reads the varied field.** A "context-source parity" test fed backtest-shaped vs live-shaped contexts, but every overlay read only `ctx.equity`, never `ctx.datasets` — so it held with `datasets=None`. Fix: put a consumer of D in the path (e.g. a price gate reading the dataset close).
- **Cursor/index misalignment.** Two constructions of the same data can sit at different read positions. plz `DataSets(test_mode=True)` starts at `tick_index=1` (first bar only); `DataSets.from_candle_map` sets `tick_index=len` (all bars) — so a datasets-reading overlay reads *different* closes from each. Align them (`bt_ds.tick_index = len(candles)`) and assert the precondition (both present the same last close) before asserting parity.
- **Inert chain element.** In a 2-element chain where element #2 can't change the outcome (two monotone drawdown guards on one leg — the tightest trips first, masking the looser), a buggy `apply()` that dropped #2 still passes. Fix: make #2 the binding element and add a contrast — `assert chain_result != element1_alone_result` proves #2 is composed.

General tell: ask "would this pass under the exact bug it guards against?" If yes, assert a value reachable *only* when the guarded behavior actually fires. Sibling to the parity-oracle entries above (those trim over/under-coverage of a baseline; this catches a parity assertion that exercises nothing).

## A `--update`-able regression/golden gate verifies stability, not correctness

A gate that diffs current output against a committed baseline (and offers `--update` to re-bless) only proves the output didn't *change* — `--update` makes it pass trivially. After a change shifts the output, confirm the **target metric** actually improved (e.g., the moved fixture's ground-truth still retrieves in the top-K), and prefer fixing the surface (keywords, mapping, the code) over re-blessing a regressed baseline. A blind `--update` silently masks a recall/accuracy loss that the stability diff was never measuring.

## Cross-Refs

- `~/.claude/learnings/code-quality-instincts.md` — test quality instincts
- `~/.claude/learnings/dependency-injection-patterns.md` — DI seams and test boundaries
