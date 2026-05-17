Vitest + React Testing Library patterns: stack setup, jsdom gotchas, vi.mock hoisting, Next.js route handlers, shared test helpers, axios interceptors, lazy module-level Promises, mockClear vs mockReset.
- **Keywords:** Vitest, React Testing Library, renderHook, vi.mock, vi.hoisted, jsdom, localStorage, Invalid Date, Next.js route handler, app router, Response, validator, test-helpers, postRequest, axios interceptors, InternalAxiosRequestConfig, lazy module-level Promise, mockClear, mockReset, mockResolvedValue, beforeEach, call history, cross-test leakage
- **Related:** ~/.claude/learnings/frontend/nextjs.md, ~/.claude/learnings/frontend/react-state-effects.md

---

## Vitest + React Testing Library Stack

- **Vitest** with `jsdom` environment (`vitest.config.ts`)
- **@testing-library/react** v16 — includes `renderHook` natively. Do NOT install `@testing-library/react-hooks` (incompatible with React 19)
- **@testing-library/jest-dom** via `vitest.setup.ts`

**What to test:** Pure functions (easiest, highest value) → custom hooks via `renderHook` (state transitions, fetch, cleanup) → factory functions (test returned hook). Don't unit-test trivial wrappers or JSX-heavy components — use E2E for those.

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

## Cross-Refs

- `~/.claude/learnings/frontend/nextjs.md` — route handler patterns and middleware
- `~/.claude/learnings/frontend/react-state-effects.md` — React state/hydration patterns relevant when testing components
