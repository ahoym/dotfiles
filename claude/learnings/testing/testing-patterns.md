Testing recipes for Vitest/React Testing Library, Next.js route handlers, cross-implementation fixtures, Python test isolation, and mock design.
- **Keywords:** Vitest, React Testing Library, renderHook, vi.mock, vi.hoisted, jsdom, localStorage, pytest, pytest.raises, module-level singleton, import side effects, UTC, datetime, cross-implementation fixtures, mock coupling, test helpers, mockClear, mockReset, mockResolvedValue, beforeEach, afterEach, call history, cross-test leakage
- **Related:** ~/.claude/learnings/frontend/nextjs.md, ~/.claude/learnings/playwright-patterns.md, ~/.claude/learnings/code-quality-instincts.md, ~/.claude/learnings/frontend/react-frontend-gotchas.md

---

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

**Corollary:** Router/integration tests that use `TestClient(app)` should use default env var values (e.g., `"local_vendor_source_vault"`) in mock expectations — not `.env.tests` values — because module-level singletons may already be initialized with defaults by the time the test runs.

## UTC-Explicit Datetime Conversions

`datetime.fromtimestamp()` without a timezone returns local time, making tests fail across timezones (local dev vs CI runners). Always pass `tz=UTC` for timezone-stable datetime conversions in tests.

## Use Specific Exception Types in pytest.raises

Replace `pytest.raises(Exception)` with specific exception types. Catching broad `Exception` masks bugs — if a different exception type is raised (e.g., `TypeError` from bad arguments), the test still passes. Specific exception types in `pytest.raises` prevent false positives from wrong error paths.

## Plan Docs Should Specify Mock Expectation Values

When writing plan docs that include integration/router-level tests, explicitly state which env var values mocks should match — default values from `os.getenv("X", "default")` or values from `.env.tests`. This prevents a debugging round where tests fail because mock expectations use `.env.tests` values but the code under test reads module-level singletons initialized with defaults.

## Testing axios interceptors

Capture the interceptor function via the `use` mock, then call it directly — no real HTTP involved.

```typescript
const mockGet = vi.hoisted(() => vi.fn());
let capturedInterceptor: ((c: InternalAxiosRequestConfig) => Promise<InternalAxiosRequestConfig>) | null = null;

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({
      get: mockGet,
      interceptors: {
        request: {
          use: vi.fn((fn) => { capturedInterceptor = fn; }),
        },
      },
    })),
  },
}));

import { _resetCsrfTokenForTesting } from '../client';

beforeEach(() => {
  _resetCsrfTokenForTesting();
  mockGet.mockResolvedValue({ data: { token: 'test-token' } });
});

it('attaches token to POST', async () => {
  const config = { method: 'post', headers: {} } as unknown as InternalAxiosRequestConfig;
  const result = await capturedInterceptor!(config);
  expect(result.headers['x-csrf-token']).toBe('test-token');
});
```

Key points:
- `vi.hoisted` makes `mockGet` available inside the `vi.mock` factory
- **`interceptorHolder` must also be hoisted** — a plain `let` variable is in the temporal dead zone when the factory runs, causing `ReferenceError: Cannot access '...' before initialization`. Use `vi.hoisted()` for any variable the mock factory writes to.
- `interceptorHolder.fn` is set when the module registers via `interceptors.request.use`
- Call the interceptor directly rather than making real requests through the client

## Lazy module-level Promise for testability

A Promise initialized at module load time is untestable — the mock can't be set up before the module imports and fires the fetch. Switch to lazy init:

```typescript
// BAD — fires on import, mock can't intercept
const tokenPromise = apiClient.get('/token').then(r => r.data.token);

// GOOD — fires on first use, mock can be set up first
let tokenPromise: Promise<string> | null = null;
const getToken = () => {
  if (!tokenPromise) tokenPromise = apiClient.get('/token').then(r => r.data.token);
  return tokenPromise;
};

// Export for test reset between cases
export const _resetTokenForTesting = () => { tokenPromise = null; };
```

Benefits beyond testability: avoids wasted fetches for users immediately redirected away (e.g. unauthenticated users hitting a protected route before login redirect).

## Mock call history vs implementation state

`mockResolvedValue(...)` sets the return value but does **not** clear call history. Without an explicit `mockClear()`, call counts accumulate across tests and assertions like `not.toHaveBeenCalled()` or `toHaveBeenCalledTimes(1)` fail on later tests.

```ts
beforeEach(() => {
  mockGet.mockClear();             // reset call count/args — must come first
  _resetModuleCacheForTesting();   // reset any module-level cached state
  mockGet.mockResolvedValue(...);  // set return value
});
```

**`beforeEach` not `afterEach`** — `afterEach` leaves dirty state when a test throws or is skipped; the next test starts with stale call counts. `beforeEach` guarantees a clean slate unconditionally.

`mockClear()` vs `mockReset()`:
- `mockClear()` — clears calls/instances/results, keeps implementation
- `mockReset()` — clears calls AND resets implementation to `undefined`

When re-assigning the implementation in the same `beforeEach`, either works — prefer `mockClear()` as it's more explicit about intent.

## Contract tests against recorded real responses (fake-drift detection)

When a test suite uses `FakeAdapter`-style mocks for external services, unit tests pass even after the real API adds fields — the fake goes stale silently, and prod fails on the first call that reads the new field. Contract tests close the gap:

1. `scripts/record-fixtures.py` — small harness that hits the real API (SIM/staging, never prod without explicit ack) and writes responses to `tests/fixtures/<provider>/<endpoint>.json`
2. Pytest contract test loads each fixture, runs through the **real** adapter's normalization path, and diffs the output against a committed golden file
3. When the real API adds a field: re-record the fixture → golden diff → fake must be updated to match before CI is green again

Invest when: any codebase where a mocked adapter layer hides a real protocol boundary. Cost is one recording script plus committed fixtures; payoff is catching API drift on the next CI run after an upstream change, not three releases later in prod. Especially valuable for trading systems, payment integrations, any adapter whose input shape is externally owned.

## Cross-Refs

- `~/.claude/learnings/frontend/nextjs.md` — route handler test structure
- `~/.claude/learnings/playwright-patterns.md` — E2E test recipes
- `~/.claude/learnings/code-quality-instincts.md` — test quality instincts
- `~/.claude/learnings/frontend/react-frontend-gotchas.md` — Vitest stack context
