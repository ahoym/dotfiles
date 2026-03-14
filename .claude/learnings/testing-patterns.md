# Testing Patterns

## Vitest + React Testing Library Stack

- **Vitest** with `jsdom` environment (`vitest.config.ts`)
- **@testing-library/react** v16 — includes `renderHook` natively. Do NOT install `@testing-library/react-hooks` (incompatible with React 19)
- **@testing-library/jest-dom** via `vitest.setup.ts`

**What to test:** Pure functions (easiest, highest value) → custom hooks via `renderHook` (state transitions, fetch, cleanup) → factory functions (test returned hook). Don't unit-test trivial wrappers or JSX-heavy components — use E2E for those.

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

### Example

```typescript
// BAD - reads from API response, every mock must include referenceId
const response = await apiClient.createPayment({ payload: [paymentData] });
const payment = response.payments[0];
return { reference: payment.referenceId };

// GOOD - reads from local payload, mocks don't need to include it
const paymentData = buildPaymentPayload(...);
const response = await apiClient.createPayment({ payload: [paymentData] });
return { reference: paymentData.referenceId };
```

### Why it matters

- Adding a field to the response path requires updating every test mock that returns that response
- Integration tests using HTTP-level mocking are especially painful to update
- The local payload is deterministic and already in scope — no reason to round-trip through the mock

## Testing Response-Returning Validators

When testing Next.js API validator functions that return `Response | null`:

```typescript
// Assert success (null = valid)
expect(validateAddress("rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh", "addr")).toBeNull();

// Assert failure (Response with status and JSON body)
const resp = validateAddress("invalid", "addr");
expect(resp).not.toBeNull();
expect(resp!.status).toBe(400);
const body = await resp!.json();
expect(body.error).toContain("Invalid");
```

The `!` non-null assertion is safe after the `not.toBeNull()` check. The `await resp!.json()` is needed because `Response.json()` returns a Promise.

## Invalid Date in jsdom/Node

`new Date("not-a-date").toLocaleTimeString()` does **not** throw in jsdom or Node.js — it returns the string `"Invalid Date"`. This means `try/catch` is insufficient to handle invalid date inputs in formatting functions.

**Fix:** Add an explicit validity check before calling locale methods:

```ts
const d = new Date(iso);
if (isNaN(d.getTime())) return fallback;
return d.toLocaleTimeString(...);
```

## jsdom Provides localStorage

No need to mock `localStorage` in jsdom — it's available natively. Just call `localStorage.clear()` in `beforeEach`.

## vi.mock() Hoisting and vi.hoisted()

`vi.mock()` factory functions are **hoisted above all imports and variable declarations**. A mock factory cannot reference variables declared at module scope.

**Fix — use `vi.hoisted()`:**
```ts
const mockClient = vi.hoisted(() => ({
  request: vi.fn(),
  submitAndWait: vi.fn(),
}));

vi.mock("@/lib/some-module", () => ({
  getClient: vi.fn().mockResolvedValue(mockClient),
}));
```

`vi.hoisted()` runs its callback at the hoisted level (before imports), so the variable is available inside `vi.mock()` factories.

## Route Handler Test Structure (Next.js App Router)

Pattern for testing Next.js route handlers that depend on external service singletons:

```ts
// 1. Hoist the mock BEFORE vi.mock
const mockClient = vi.hoisted(() => ({ request: vi.fn(), submitAndWait: vi.fn() }));

// 2. Mock the module
vi.mock("@/lib/client", () => ({ getClient: vi.fn().mockResolvedValue(mockClient) }));

// 3. Import handler AFTER mocks
import { POST } from "./route";

describe("POST /api/...", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns 201 on success", async () => {
    const res = await POST(postRequest("/api/...", { /* body */ }));
    expect(res.status).toBe(201);
  });
});
```

For dynamic routes, wrap params in a resolved Promise: `{ params: Promise.resolve({ address: "..." }) }`.

## Shared Test Helpers Design

A single `test-helpers.ts` file should provide:
- **Stable test fixtures**: Generated once at module level (not per test)
- **Mock factory**: Returns object matching the service interface with all methods as `vi.fn()`
- **Request factories**: `postRequest(path, body)` and `getRequest(path, params?)` wrapping framework request objects
- **Response factories**: `successResult()` and `failedResult(code)` for mock returns
- **Route param helper**: For framework-specific param wrapping

Note: Factory functions from test-helpers can't be used inside `vi.hoisted()` (circular issues). Inline the mock object in `vi.hoisted()` and use factories only in non-hoisted contexts.

## Test Isolation: Mock Data Must Match Runtime Encoding

When mocking responses that contain encoded fields (e.g., hex-encoded currency codes), the mock value must match the encoding the code under test will compare against. If the code encodes `"USD"` as a 3-char passthrough, the mock must also use `"USD"` — not the 40-char hex form.

This causes tests that pass in isolation to fail in the full suite when encoding comparison logic doesn't match mock data.

## Python Module-Level Singletons Poison Test Suite via Import Side Effects

When a Python module creates singletons at import time (e.g., `coordinators.py` instantiating coordinator objects using env vars), and a test file imports modules in that chain at collection time, the singletons get initialized with unpatched env var values. Later tests that patch env vars via fixtures see the cached module — not fresh values.

**Symptoms:** Tests pass in isolation but fail in the full suite. The failure pattern depends on test collection order (alphabetical by file).

**Root cause chain:**
1. pytest collects `test_foo.py` → imports `SomeClass` from `some_module.py`
2. `some_module.py` imports from `client.py` which has module-level `os.getenv()` calls
3. `conftest.py::load_env` (session-scoped autouse fixture) hasn't run yet → defaults used
4. Module is cached with default values; `load_dotenv()` runs later but doesn't re-execute the module

**Fix — defer heavy imports:**
```python
# BAD — triggers import chain at collection time
from app.orchestrator import Orchestrator

@pytest.fixture
def orch():
    return Orchestrator(coordinator=MagicMock(spec=Coordinator))

# GOOD — defers import to fixture execution (after load_env)
@pytest.fixture
def orch():
    from app.orchestrator import Orchestrator
    return Orchestrator(coordinator=MagicMock())
```

**Corollary:** Router/integration tests that use `TestClient(app)` should use default env var values (e.g., `"local_fireblocks_source_vault"`) in mock expectations — not `.env.tests` values — because module-level singletons may already be initialized with defaults by the time the test runs.

## UTC-Explicit Datetime Conversions

`datetime.fromtimestamp()` without a timezone returns local time, making tests fail across timezones (local dev vs CI runners). Always use `datetime.fromtimestamp(ts, tz=UTC)`. This applies to any timestamp-to-datetime conversion in test assertions.

- **Takeaway**: Always pass `tz=UTC` for timezone-stable datetime conversions in tests.

## Use Specific Exception Types in pytest.raises

Replace `pytest.raises(Exception)` with specific exception types. Catching broad `Exception` masks bugs — if a different exception type is raised (e.g., `TypeError` from bad arguments), the test still passes. Validates the actual error path, not just "something failed."

- **Takeaway**: Specific exception types in `pytest.raises` prevent false positives from wrong error paths.

## Plan Docs Should Specify Mock Expectation Values

When writing plan docs that include integration/router-level tests, explicitly state which env var values mocks should match — default values from `os.getenv("X", "default")` or values from `.env.tests`. This prevents a debugging round where tests fail because mock expectations use `.env.tests` values but the code under test reads module-level singletons initialized with defaults.
