Python/pytest patterns: module-level singleton isolation, UTC datetime conversions, pytest.raises specificity, env-var fixture isolation, MagicMock + DI seams, autospec for routing tests, autouse hermetic fixtures.
- **Keywords:** pytest, pytest.raises, module-level singleton, import side effects, conftest, load_env, UTC datetime, fromtimestamp, monkeypatch, delenv, autouse, MagicMock, spec, autospec, @patch, DI seam, fixture tuple, httpx Client, on-disk lookup, tmp_path
- **Related:** ~/.claude/learnings/python-specific.md, ~/.claude/learnings/dependency-injection-patterns.md

---

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

## `monkeypatch.delenv(KEY, raising=False)` over `patch.dict({}, clear=True)` for env isolation

```python
@pytest.fixture(autouse=True)
def _clear_my_env_var(monkeypatch):
    monkeypatch.delenv("DRY_RUN", raising=False)
```

Surgical: removes only the variable the test cares about. `patch.dict({}, clear=True)` nukes the whole environment including `PATH`, `HOME`, virtualenv pointers, and any inherited shell vars the test indirectly depends on — if a downstream import resolves a binary via `PATH`, you've created a hard-to-debug isolation regression.

Use when:
- Module under test reads an env var at function-call time (not import time)
- Some tests need the var unset (autouse fixture covers them) and others need specific values (those override with `monkeypatch.setenv` or `patch.dict({"VAR": "val"})`)
- Host shell may have the var exported (e.g., a developer running with `DRY_RUN=1` would otherwise see different behavior than CI)

`raising=False` means absent-key isn't an error — fixture is idempotent. See also `python-specific.md` → "configparser stdlib footguns" for the inverse case where `clear=True` is the right tool for explicit env-absence tests.

## Expose injected mocks in the fixture's return tuple

When migrating tests from private-attribute access (`client._http = MagicMock()`) to constructor-injected mocks via a DI seam, return the mock from the fixture so tests assert on it directly:

```python
# BAD — fixture hides the mock; tests reach into private state
def _client(env="sim"):
    client = TradeStationClient(token_manager=MagicMock(), env=env)
    client._http = MagicMock()                  # mutates private attr
    return client

def test_get_balances(self):
    client = _client()
    client.get_balances("ACC1")
    client._http.get.assert_called_once()       # asserts on private attr

# GOOD — fixture surfaces the mock; tests assert on the seam
def _client(env="sim"):
    http = MagicMock(spec=httpx.Client)
    client = TradeStationClient(
        token_manager=MagicMock(), env=env, http_client=http,
    )
    return client, http                          # tuple exposes the mock

def test_get_balances(self):
    client, http = _client()
    client.get_balances("ACC1")
    http.get.assert_called_once()                # asserts on injected mock
```

The DI seam exists precisely so tests don't need private access; if the fixture forces tests back into `client._private`, the seam is wasted. Returning the mock as part of the tuple keeps the encapsulation and makes the seam load-bearing.

For multi-mock fixtures (token manager + http client + clock + ...), return a `(client, *mocks)` tuple or a small dataclass so tests destructure only what they need.

## Mock domain methods, not the HTTP layer, after a client HTTP→SDK refactor

When a client refactors from low-level HTTP (`client.get/post/delete` returning `httpx.Response`) to SDK-style domain methods (`client.get_balances/place_order` returning parsed dicts), adapter tests must follow — drop the response wrapper and mock the domain method directly:

```python
# Before — mock HTTP layer; production code unwraps via .json():
client.get.return_value = MagicMock(json=lambda: {"Bars": [...]})

# After — mock domain method; raw dict, no wrapper:
client.get_barcharts.return_value = {"Bars": [...]}
```

Assertion targets shift too: `client.post.call_args.kwargs["json"]` → `client.place_order.call_args.args[0]`. Side-effect chains for multiple endpoints split per-method: `client.get.side_effect = [resp1, resp2]` becomes `client.get_balances.return_value = ...; client.get_positions.return_value = ...`. The `_mock_response` httpx-shaped helper becomes vestigial — delete it. Symptom of skipped migration: tests pass before the rebase (mocks return MagicMocks, assertions accidentally tolerate them) but the adapter calls into a different code path entirely against a real client.

## `@patch` mocks accept any signature — `autospec=True` for routing tests

A bare `@patch("module.func")` replaces the symbol with `MagicMock()` that has no signature constraint. If the production call site is missing required kwargs of the *real* function, the mock swallows the call silently and `assert_called_once_with(...)` (which checks only the args you list) passes. The bug surfaces only at runtime in the un-mocked deploy.

```python
# Real signature: trigger_position_futures(ticker, account, *, margin: float, notional: float)

# Production code BUG (missing required kwargs):
trigger_position_futures(ticker, account, execute_orders=True)

# Test passes because mock has no signature spec:
@patch("module.trigger_position_futures")
def test_routes(mock_fn):
    let_it_fly("+@MNQ", account, execute_orders=True)
    mock_fn.assert_called_once_with("+@MNQ", account, execute_orders=True)  # ✓ green

# Fix — autospec=True binds the mock to the real signature:
@patch("module.trigger_position_futures", autospec=True)
# Now the production-side call raises TypeError at test time, matching prod.
```

Use `autospec=True` (or `create_autospec(real_fn)`) on routing/integration tests where the test is verifying *that* a function gets called with *what* — exactly the case where signature drift between caller and callee silently regresses. Pure unit tests of the function itself don't need it.

## Autouse hermetic fixture when adding new on-disk lookups

Adding a new filesystem lookup (e.g., a new cache layer) to a function with existing mock-based tests can break test isolation silently: real on-disk files matching the test's ticker / key short-circuit the mocked code path, returning real data before the mock fires. Defense — autouse fixture that points the new lookup at an empty tmp dir for ALL tests in the module. Tests that specifically exercise the new lookup repoint the constant to a populated tmp dir within the test body.

```python
@pytest.fixture(autouse=True)
def _isolate_perpetual_dir(tmp_path, monkeypatch):
    monkeypatch.setattr(my_module, "_PERPETUAL_DIR", tmp_path / "_empty")
```

Symptom that surfaces the leak: an existing test asserting "broker was called" fails because the new lookup found a real file and returned before the broker path. The failing test is high-signal — it tells you which existing tests had implicit assumptions about on-disk state, not just about mocks. Use `monkeypatch.setattr(module, "ATTR", val)` (import-based), not `setattr("pkg.module.ATTR", ...)` (string-based) — the import form is typo-checked and survives renames.

## Cross-Refs

- `~/.claude/learnings/python-specific.md` — Python idioms (sys.modules mocking, configparser env-clear, deferred imports)
- `~/.claude/learnings/dependency-injection-patterns.md` — composition root, DI seams, import-time side effects
