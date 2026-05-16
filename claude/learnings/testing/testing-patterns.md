Cross-language test design patterns: contract tests, fixture origin, translation-layer testing, mock fidelity, and test-existence heuristics.
- **Keywords:** contract tests, fake-drift detection, fixture origin, mock coupling, mock fidelity, translation-layer tests, adapter tests, test isolation, encoded fields, cross-implementation fixtures, recorded fixtures, golden files, production consumers, DI seams, test value vs internals
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

## Cross-Refs

- `~/.claude/learnings/code-quality-instincts.md` — test quality instincts
- `~/.claude/learnings/dependency-injection-patterns.md` — DI seams and test boundaries
