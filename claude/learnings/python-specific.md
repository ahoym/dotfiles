Python idioms and gotchas for Pydantic v2, TypedDict, dataclasses, env var handling, and package management.
- **Keywords:** pydantic, optional fields, model_dump, exclude_none, TypedDict, NotRequired, pyright, dataclass, __post_init__, __all__, pyproject.toml, uv, poetry, noqa, linter suppression, Protocol, PEP 544, structural typing, pydocstyle, private module, patch path, from None, exception chain, fchmod, mkstemp, fd leak, bool int subclass, isinstance bool, httpx Timeout, split phases, async blocking, sys.path, PYTHONPATH, package-mode, ModuleNotFoundError, script relocation, Docker CMD, python -m, keyword-only, signature audit, positional-to-keyword, dependency-groups, --no-dev, deferred import, dev-only dep, container venv, pyarrow
- **Related:** ~/.claude/learnings/api-design.md, ~/.claude/learnings/testing-patterns.md

---

## Pydantic v2: Optional Fields and Serialization

In Pydantic v2, there are two distinct concepts for "optional":

### Value optionality (value can be None)
```python
reference: Optional[str] = None
# or equivalently:
reference: str | None = None
```
The field always appears in `.model_dump()` and JSON responses as `"reference": null`.

### Field optionality (field omitted from output when None)
```python
# Per-model: omits ALL None-valued fields
class MyModel(BaseModel):
    model_config = ConfigDict(exclude_none=True)

# Per-serialization call:
model.model_dump(exclude_none=True)
model.model_dump(exclude_unset=True)  # only omits fields not explicitly set

# Per-FastAPI route:
@router.get("/", response_model_exclude_none=True)
```

### Recommendation
For API response models, prefer value optionality (consistent shape). See `learnings/api-design.md`.

## TypedDict: NotRequired fields and pyright

When a `TypedDict` field is marked `NotRequired`, pyright will error on direct bracket access:

```python
class PaymentRequest(TypedDict):
    amount: int
    referenceId: NotRequired[str]

payment: PaymentRequest = {...}
payment["referenceId"]      # pyright error: reportTypedDictNotRequiredAccess
payment.get("referenceId")  # OK - returns str | None
```

Even if you know the key was set, pyright can't verify it. Use `.get()` for `NotRequired` keys.

## Env Var Empty-String-to-None Conversion

When an env var semantically represents "absent" via empty string, convert at the source with `os.getenv("KEY") or None` rather than relying on downstream `or None` at usage sites. This avoids implicit contracts where multiple consumers must each remember to handle `""`:

```python
# GOOD — single conversion point
DESTINATION_TAG = os.getenv("DESTINATION_TAG") or None

# BAD — implicit contract at every usage site
DESTINATION_TAG = os.getenv("DESTINATION_TAG", "")
# ... later in wiring code:
config = Config(destination_tag=DESTINATION_TAG or None)  # easy to forget
```

## Use `__post_init__` for derived fields in dataclasses

Dataclasses auto-generate `__init__`, so `__post_init__` is the standard hook for computing derived/calculated fields from the initialized values. Don't override `__init__` — use `__post_init__` to keep the dataclass contract intact.

`__post_init__` works on `@dataclass(frozen=True)`. `frozen` blocks attribute assignment *after* construction, but `__post_init__` runs *during* construction — so cross-field invariant checks (raise `ValueError` on misconfig) execute and fail at module-import time. Useful for config-as-code: a misconfigured constant fails fast rather than at first use.

## Package Manager Migration

- **Anchor on `pyproject.toml`** — the stable artifact across tool changes (requirements.txt → Poetry → uv). Lock files and tooling configs are disposable.
- **Coordinate Dockerfile updates** — the dependency-install build layer changes when the tool changes. Package manager change = Dockerfile change.
- **Commit a migration script** (e.g., `scripts/migrate-poetry-to-uv.sh`) alongside the PR. Captures exact steps, serves as documentation and reproducible recipe.

## Fix Root Causes, Don't Suppress Linter Warnings

When a linter flags a real issue (e.g., B006 mutable default arguments), fix the underlying problem rather than adding `# noqa`. The sentinel pattern (`Optional[list] = None` + `if x is None: x = []`) fixes the bug; `# noqa: B006` hides it. Suppression is appropriate only when the linter is genuinely wrong, not when the fix is straightforward.

## Use `__all__` to Define Explicit Public APIs

In `__init__.py` files, define `__all__` to control what a package exposes. This lets users import directly from the package (`from pkg import Class`) instead of reaching into submodules, signals the intended public API to tooling and linters, and makes the package's surface area explicit and reviewable.

## Custom matcher objects can't be used as Pydantic model field values

Custom test matcher objects (e.g., `IsInstanceOf(str)`, `AnyString()`) cannot be passed as Pydantic model field values — Pydantic validates the input and rejects non-matching types for typed fields. Use `response.<field>` instead:

```python
# BAD - Pydantic rejects matcher object as a string field
assert response == MyResponseModel(
    reference=IsInstanceOf(str),  # ValidationError!
)

# GOOD - use the actual value from the response
assert response == MyResponseModel(
    reference=response.reference,  # works, still verifies other fields
)
```

## uv for Local Python Tooling

Prefer `uv` over `pyenv` + `pyenv-virtualenv` for local Python version and environment management. uv handles both in a single tool and is significantly faster.

Install via homebrew: `brew install uv`

Add to `~/.zshrc`:
```zsh
eval "$(uv generate-shell-completion zsh)"
```

Common commands:
- `uv python install 3.12` — install a Python version
- `uv venv` — create `.venv` in current dir
- `uv add <pkg>` — add dependency (manages `pyproject.toml` + lockfile)
- `uv run script.py` — run with project environment
- `uv sync` — install all deps from lockfile

**Gotcha:** `pyenv virtualenv-init init -` (extra `init` arg) hangs on every shell open — if migrating away from pyenv, fully remove it rather than leaving broken init hooks in `.zshrc`.

## `assert` for production guards is a silent-failure footgun

Two independent bugs, both fire in trading / security-critical code:

1. **`python -O` strips `assert`.** Any `assert x, "msg"` used as a runtime guard (path sanitization, account-number validation, invariant check) vanishes under `-O`. Use `if not x: raise ValueError(...)` for anything protecting data integrity or security.
2. **Message expression is eagerly evaluated.** `assert response.status_code == 200, response.raise_for_status()` calls `raise_for_status()` on every assertion check — success or failure — because Python evaluates the message arg before deciding whether to assert. The message must be a bare string or `f"..."`, never a call.

Heuristic: `assert` is for debug invariants only. For anything a reviewer might want to hold in production, use explicit `if/raise`.

## `@runtime_checkable` on Protocol *subclasses* raises TypeError (Python 3.13+)

```python
# BROKEN on 3.13:
@runtime_checkable
class _RuntimeBrokerAdapter(BrokerAdapter): ...

# CORRECT:
@runtime_checkable
class BrokerAdapter(Protocol): ...
```

The decorator must be applied to the `Protocol` class itself, not to a subclass. Earlier Python versions tolerated the subclass form; 3.13 hard-errors.

## D101/D102 fires on Protocol methods with `...` body

```python
class BrokerAdapter(Protocol):
    def get_price(self, ticker: str) -> float: ...  # D102: Missing docstring
```

Ellipsis-body is the idiomatic Protocol form but pydocstyle requires a docstring anyway. Add a one-liner:

```python
def get_price(self, ticker: str) -> float:
    """Return the latest price for a ticker."""
    ...
```

## pydocstyle D-rules skip `_`-prefixed modules

Renaming `_foo.py` → `Foo.py` (or `foo.py`) exposes D101/D102/D107 on classes/methods that were silently skipped. pydocstyle treats a module as private when the filename starts with `_` and doesn't enforce public-API docstring rules on its contents.

Consequences on file moves:
- Move `logic/foo/_adapter.py` → `logic/adapters/Adapter.py` and ruff will flag every undocumented public method that was fine before.
- Fix by adding concise docstrings in the *same* commit — don't leave the lint broken.
- Alternative if docstrings aren't wanted: keep the leading underscore, or add per-file ignore in pyproject.toml.

Also explains why private helper modules (`_utils.py`, `_internal.py`) don't require docstrings on their public-looking methods.

## Explicit Protocol inheritance is valid (PEP 544)

```python
class BrokerAdapter(Protocol):
    def get_price(self, ticker: str) -> float: ...

# Both of these satisfy the protocol:
class A(BrokerAdapter):           # explicit — declares intent
    def get_price(self, t): ...

class B:                           # structural — ducks the type
    def get_price(self, t): ...
```

Explicit inheritance does **not** break structural typing for other implementors — duck-typed classes still conform. It buys you:
- Discoverability: readers see the contract at class definition, not only at call sites.
- Type-checker verification at class definition (mypy/pyright flags missing methods immediately, not only at call sites).
- Zero cost to other implementors (mocks, third-party classes, test fakes still satisfy via structural match).

Use when *your* class should declare intent but you don't want to force inheritance on anyone else. The common "must I inherit from Protocol?" tension resolves as: no for others, optional-but-recommended for your own implementations.

## Moving a source file: grep `patch("old.path…")` too

When relocating a Python source file that's patched in tests, `patch("old.module.Symbol")` strings are invisible to import-rename tooling. Grep every test file for the old module path and update the patch targets alongside the `from` imports — otherwise tests run against the wrong namespace (or silently no-op if the symbol exists at both paths during a transitional re-export).

```bash
rg 'patch\("logic\.plz\._adapter\.' tests/
```

Applies to any string-based reference to the old path: `patch()`, `patch.object()` string forms, `importlib.import_module()`, monkeypatch fixtures.

## Subclass Stdlib Exceptions for Backwards-Compat Migration

When introducing a domain-specific exception that replaces a standard one, subclass the original: `class DomainError(StdlibError): ...`. Existing callers' `except StdlibError` catches keep working during migration, and new code can catch the more specific domain type. Critical in systems where error handling is load-bearing (hot loops, retry logic, signal handlers) — a silent type change can break error paths in production.

```python
class LimitsFileNotFoundError(FileNotFoundError):
    """Raised when no per-account or shared limits file is readable."""
```

## Dict-Unpack Guard: `isinstance` Before `{**x}`

`{**None}` and `{**non_mapping}` raise `TypeError` with an unhelpful message. Key-presence checks (`if key in obj`) don't guard against `None` or non-dict values at that key — JSON decoding can produce `{"acct": null}`. Use `.get()` + `isinstance(_, dict)` before unpack:

```python
entry = shared.get(account_number)
if not isinstance(entry, dict):
    raise DomainError(f"expected dict, got {type(entry).__name__}")
merged = {**entry, "account_number": account_number}
```

## `urlencode(params, safe=':/')` to keep URL chars unencoded in query values

`urllib.parse.urlencode` percent-encodes `:` and `/` by default, which mangles readable URL values like OAuth `redirect_uri=https://localhost:8080` or `audience=https://api.example.com` into `https%3A%2F%2F...`. Pass `safe=':/'` to preserve them:

```python
urlencode({"redirect_uri": "http://localhost:8080", ...}, safe=':/')
```

Most OAuth providers accept either form (RFC 3986), but some are strict. Use only when the unencoded form is semantically equivalent and you want readable URLs (e.g., authorize URLs the operator pastes into a browser).

## Python HTTP clients require explicit timeouts

`httpx`, `requests`, and `urllib3` all default to no timeout — a hung remote hangs the call indefinitely. Pass explicit `timeout=N` (or `httpx.Timeout(...)`) to every request. This is the kind of gotcha that three independent reviewers will flag from independent first principles when missed — treat the absence of a timeout as a defect, not a style nit.

Also: `httpx.post(...).status_code == 200` does not guarantee a JSON body. WAFs/proxies can return `200 OK + HTML`, and `.json()` then raises `JSONDecodeError`. Wrap `.json()` in a try/except for any external endpoint sitting behind infrastructure layers.

**Prefer split-phase `httpx.Timeout` over scalar timeout when sync HTTP runs inside an async loop.** A scalar `timeout=30.0` lets the read phase consume the full budget during an IdP/upstream brownout, blocking the asyncio event loop for the whole window. Split phases bound the worst case to the read budget alone:

```python
_HTTP_TIMEOUT = httpx.Timeout(connect=5.0, read=10.0, write=5.0, pool=5.0)
httpx.post(url, ..., timeout=_HTTP_TIMEOUT)
```

Worst-case loop stall drops from `total` to `~connect+read` (~10-15s vs 30s), and connect failures surface fast instead of hiding behind the read budget. Cheap mitigation that doesn't fix the underlying sync-in-async issue (the right fix is `AsyncClient` or `asyncio.to_thread`), but bounds the symptom.

## `httpx.Client` in `__init__` needs explicit cleanup

A class that constructs `httpx.Client(...)` in `__init__` and never exposes `close()` / `__enter__` / `__exit__` leaks the connection pool whenever the wrapper is reconstructed (env switch, reconnect-on-error, repeated test setup, factory called per-request). Long-running processes accumulate sockets and transport threads.

```python
def close(self) -> None:
    self._http.close()

def __enter__(self): return self
def __exit__(self, exc_type, exc, tb): self.close()
```

Cheap to add at construction time, painful to retrofit once callers exist.

## `os.open(mode=0o600)` only enforces permissions at creation

`os.open(path, O_CREAT | O_WRONLY | O_TRUNC, 0o600)` masks the mode by umask and applies it only when the file is newly created. An existing file is truncated (`O_TRUNC`) but permissions are unchanged — re-runs silently inherit the prior permissions.

For credential files, follow up with `os.chmod(path, 0o600)` after the write. The "looks correct on first run, fails silently on rerun" failure mode is easy to miss in code review unless you specifically ask "what if this file already exists?"

## `sys.modules` mocking in `conftest.py` doesn't stub the package hierarchy

`sys.modules["pkg.sub.mod"] = MagicMock()` registers the leaf, but Python's import system doesn't synthesize `pkg` or `pkg.sub`. `import pkg.sub.mod` then `pkg.sub.mod.attr` fails with `AttributeError: module 'pkg' has no attribute 'sub'`.

Access mocked attributes via `sys.modules["pkg.sub.mod"].attr` directly. For modules that own a singleton (`_client = None` initialized at import), test isolation needs both the module-cache reset AND the singleton-state reset — clearing one without the other leaks state across tests.

## `# noqa: F401` on side-effect imports hides import-order safety contracts

When a module imports another for its side effect (composition root, plugin registration), `# noqa: F401` is the correct lint suppression — but it also makes the import invisible to refactor/reorder tooling. Future contributors won't see the ordering contract.

Make intent explicit in the import name: `import config.accounts as _composition_root  # noqa: F401`. The `_purpose` alias documents *why* the import exists; the leading underscore signals "intentional unused."

## `DRY_RUN`-style observation-mode env var: enforce at the boundary

For "observe without side-effecting" toggles (dry-run, suppress-emails, no-deploy), enforce at TWO layers:

- **Boundary** (the contract): inside the function that drives the side effect, collapse the flag with the env check. `effective_execute = execute_orders and not _dry_run_enabled()`. Any caller — including ad-hoc scripts and future entry points — gets blocked.
- **Entry point** (operator visibility): read once at startup, log the mode, pass `execute=True` normally. Operators see what mode the run is in.

If you only check at the entry point, future callers bypass the gate. If you only check at the boundary, operators can't tell from logs whether observation mode is active.

```python
def _dry_run_enabled() -> bool:
    return (os.environ.get("DRY_RUN") or "").strip().lower() in {"1", "true", "yes", "on"}
```

Truthy parsing: case-insensitive, trimmed, set-based. `or ""` handles `None` from absent vars without an `is not None` check. Empty string and `"0"` go to falsy.

## `asyncio.gather(return_exceptions=True)` + `any()` — exception objects are truthy

```python
results = await asyncio.gather(*coros, return_exceptions=True)
flag = any(results)              # BUG: exception instances are truthy
flag = any(r is True for r in results)  # CORRECT: identity, not truthiness
```

`return_exceptions=True` means `results` mixes return values and `BaseException` instances. Python treats `BaseException` instances as truthy under normal `bool()` semantics, so a naive `any(results)` silently flips a flag based on raised exceptions — exactly the opposite of the boolean's intended meaning. Use `r is True` (identity comparison) when the contract requires "did it actually return True."

This pairs with the auditability fix: split exception vs. truthy results in a `for` loop with `isinstance(result, BaseException)` and log per-element separately, so operators see *which* element raised vs. returned.

## D403 fires on docstrings whose leading word is a code identifier

```python
# ruff D403: Capitalize `investedCash` to `InvestedCash`
def test_x(self):
    """investedCash == 0 must not crash the loop."""
```

Pydocstyle's "First word should be capitalized" rule reads the first word literally — code identifiers like `investedCash`, `httpx`, or `kwargs` look uncapitalized. Fix by rephrasing so the leading word is normal English (`"Zero \`investedCash\` must not..."`) or backtick-wrap and reword. `# noqa: D403` is acceptable when the identifier genuinely belongs at the start.

## `zip(..., strict=True)` enforces length parity at runtime (3.10+)

When parallel iterables MUST be the same length (dispatch list ↔ async results, headers ↔ rows, keys ↔ values), pass `strict=True`:

```python
for (account, _), result in zip(DISPATCH, results, strict=True):
    ...
```

Default `zip` silently truncates to the shorter iterable, hiding length-mismatch bugs (a missing entry in one collection silently drops the corresponding entry from the other). `strict=True` raises `ValueError` on mismatch — fail-fast at the iteration site rather than down the call chain where the symptom is a missing log line or wrong-account attribution.

## `any(r is True ...)` after `asyncio.gather(return_exceptions=True)`

When `gather(*coros, return_exceptions=True)` returns mixed `(bool, Exception)` results, naive `any(results)` includes exception objects — they're truthy under Python's normal semantics. `all([True, ConnectionError(...)])` is also `True`. Use identity comparison:

```python
results = await asyncio.gather(*coros, return_exceptions=True)
any_succeeded = any(r is True for r in results)
all_succeeded = all(r is True for r in results)
```

Or filter out exceptions first: `successes = [r for r in results if not isinstance(r, BaseException)]`. The trap bites hardest in flag-setting code (`did_execute_today = any(results)`) where an exception result silently flips the flag.

## `@runtime_checkable` Protocol does NOT enforce attributes at `isinstance`

`typing.Protocol` + `@runtime_checkable` only verifies methods at `isinstance(obj, MyProtocol)`. Class/instance *attributes* declared on the Protocol are ignored. Adding `broker_name: str` to a Protocol gives a false sense of contract enforcement — duck-typed implementations missing the attribute pass `isinstance` and only fail at first attribute access.

Fixes: drop the attribute and use a single source of truth on the consumer (e.g., `Account.broker`); or switch to `abc.ABC` with abstract properties for genuine enforcement.

## `dataclass` `_field` is not private — use `init=False`

Underscore prefix on a `dataclass` field signals intent but the field still appears in `__init__`. Callers can pass `_order_counter=999` and corrupt invariants. Use `field(init=False, default=0)` (or `default_factory=...`) to actually exclude from the generated constructor.

## `traceback.print_exc()` returns None and writes to stderr

`logger.warning(traceback.print_exc())` logs `'None'` while the actual stack trace bypasses the primary log stream. Use `traceback.format_exc()` — returns the trace as a string. Common bug in adapter/operations code where exceptions need to land in structured logs, not stderr.

## API string-to-int: `int()` crashes on float-formatted strings

`int("2.0")` raises `ValueError`, but `int(float("2.0"))` works. REST APIs return numeric fields as JSON numbers (Python float, safe) on happy paths but as strings (`"2"` or `"2.0"`) on error paths or text/plain endpoints. Use `int(float(value))` whenever the source is an external API string.

## `dict.get(k) or fallback` ≠ `dict.get(k, fallback)` for falsy values

`d.get(k, fb)` falls back only on absent key. `d.get(k) or fb` falls back on any falsy value — `0`, `""`, `False`, `[]`. For numeric count fields where `0` is a legitimate value (day-trade count, queue depth, retry remaining), `or` introduces a silent wrong-fallback bug. Use `(k, fb)` or `v if v is not None else fb` when only absent-key should trigger.

## `float(large_int_string)` IEEE 754 precision trap

`float("10000000000000001") == float("10000000000000000")` — the float type can't represent adjacent large integers. Any guard claiming integer-precision validation that uses `float` as an intermediate (e.g., `float(qty) != int(float(qty))` for whole-shares enforcement) silently passes invalid input at scale. Use `Decimal(str)` as the intermediate for precision-critical guards.

## `StrEnum` preserves equality with raw strings — incremental adoption

`class Status(StrEnum): FILLED = "FLL"`. `Status("FLL") == "FLL"` is `True`, and `Status.FILLED in {"FLL", "OPN"}` works. JSON dumps the string value, JSON loads constructs the member. Existing consumers checking `obj["Status"] == "FLL"` continue to work — adopt one call-site at a time without big-bang refactor.

## TOCTOU on `os.chmod` after `os.fdopen` write

`fd, path = tempfile.mkstemp(); os.fdopen(fd, "w").write(data); os.chmod(path, 0o600); os.replace(path, target)` leaves the file world-readable between write and chmod. Apply chmod before write: `os.chmod(path, 0o600)` then `os.fdopen(fd, "w").write(data)` — file is created with restrictive perms before any sensitive content lands.

## `os.fdopen` should own `mkstemp` fd from acquisition (close fchmod-leak window)

`tempfile.mkstemp()` returns a raw fd. Running any operation on it (`os.fchmod`, `os.fstat`) before transferring ownership to a context manager opens a leak window — if the operation raises, the fd is never closed. Restructure so `os.fdopen` takes ownership at the `with`-statement entry, then run other fd ops inside:

```python
tmp_fd, tmp_path = tempfile.mkstemp(...)
try:
    with os.fdopen(tmp_fd, "w") as f:
        os.fchmod(f.fileno(), 0o600)  # context manager owns fd; raises here close it
        json.dump(data, f, indent=2)
    os.replace(tmp_path, target)
except BaseException:
    os.unlink(tmp_path)
    raise
```

Naive `os.fchmod(tmp_fd, ...)` *before* the `with` leaks the fd on exotic filesystems (SELinux/AppArmor confinement, NFS, mode rejection). The unlink in `except` cleans up the path but not the descriptor.

## `from None` chain-drop must be symmetric across paired exception wrappers

If exception class A is raised with `from None` to scrub a credential-bearing exception chain (e.g., httpx form body), every paired wrapper in the same module wrapping a *different* source must also drop the chain — even if today's source is benign. Reasoning:

1. The asymmetry is invisible to a future implementer who swaps the benign source for one that carries credentials in its exception body.
2. Downstream defenses (`__repr__` scrubbing on the caller, message-only logging) are undone by `traceback.format_exc()` printing `__cause__`.
3. The `{type(exc).__name__}: {exc}` message-body inline pattern preserves enough debugging signal that dropping `__cause__` loses nothing in practice.

```python
# WRONG — asymmetric
raise OAuthRefreshError(...) from None         # scrubs httpx body
raise OAuthPersistenceError(...) from exc      # leaves __cause__ for future store

# RIGHT — symmetric
raise OAuthPersistenceError(
    f"persist failed: {type(exc).__name__}: {exc}"  # message inlines what matters
) from None
```

Pair the runtime fix with a Protocol-docstring contract on the pluggable surface: "implementations MUST NOT include credential material in exception messages." (See `code-quality-instincts.md` → "Document non-leakage contracts on pluggable Protocol surfaces".)

## `bool` is an `int` subclass — exclude explicitly in numeric `isinstance` validation

`isinstance(True, int)` is `True`. Range checks meant to validate "an integer in [60, 86400]" silently accept `True` (becomes `1`, fails the range) and `False` (becomes `0`, fails the range) — which is correct semantically here, but if the range *includes* the bool's int-coercion (e.g., 0 ≤ x ≤ 100), a `True` passes type+range and lands somewhere the contract didn't intend. Reject explicitly:

```python
if isinstance(expires_in, bool) or not isinstance(expires_in, int):
    raise ValueError(...)
if not _MIN <= expires_in <= _MAX:
    raise ValueError(...)
```

Order matters: `isinstance(x, bool)` before `not isinstance(x, int)` so a bool fails the first guard. Single-line `isinstance(x, int) and not isinstance(x, bool)` is also valid; pick whichever reads better in context.

Pairs with the related quirk in this file: `any(results)` after `asyncio.gather(return_exceptions=True)` treats exception instances as truthy — different mechanism (truthiness, not subclassing), same family of "implicit type widening" bugs.

## Lazy-load tenant credentials in a sibling module, not the composition root

Multi-tenant composition root that gates `BROKER=A` from needing `[B]` config sections: lazy-import each tenant's credentials inside the tenant branch.

```python
# myapp/composition.py — composition root
if BROKER == "schwab":
    from myapp._schwab import account_hashes, account_number, token_path
    schwab_adapter = SchwabAdapter(...)
```

Credentials must NOT live inside the composition root file itself when a bootstrap script needs them. A token-generation script imports the credentials to mint the token, but importing the composition root transitively constructs the broker client (`client_from_token_file()`) which requires the token to *already* exist — chicken-and-egg. Sibling private module (`myapp/_schwab.py`) for parsing; composition root for wiring. Top-level eager reads of any tenant's credentials section break the gate at import time regardless of `BROKER`.

## `...`-bodied test stubs pass vacuously in pytest

`...` (the Ellipsis literal) is a valid expression evaluating to nothing — not `pass`, but behaves identically. New test classes with `def test_x(self): ...` provide false coverage signals: tests "pass" with zero assertions. Use `raise NotImplementedError` or `pytest.skip("not yet implemented")` for placeholders. Distinct from D101/D102 (docstring linting) — those don't catch zero-assertion test bodies.

## `configparser` stdlib footguns

- **`config.read(path)` returns `[]` on missing file** instead of raising. Always check the return value or `config.has_section()` immediately after. Especially dangerous with Docker volume mounts where path misconfig produces a confusing `KeyError: 'SECTION'` later, with no diagnostic about the missing file.
- **`__contains__` (the `in` operator) delegates to internal `_proxies`, not `__getitem__`.** Tests that mock only `ConfigParser.__getitem__` will fail when production code uses `"SECTION" in config`. Patch `__contains__` (or `has_section`) explicitly, or split validation into separate file-exists and section-exists checks with distinct patches.
- **`patch.dict(os.environ, {...}, clear=True)` for env-absence tests.** Without `clear=True`, an env var leaking from the dev shell silently passes a test that should be testing absence (e.g., `test_raises_if_TS_ENV_unset` passes for the wrong reason).

## `from M import name` snapshots — patch the module attr BEFORE the from-import

`from M import name` is roughly `import M; name = M.name`. Replacing `M.name` AFTER this binding has no effect on the importer's `name`. To monkey-patch a function for a one-shot test wrapper without editing source, mutate the module attribute first, then run the script as `__main__` via `runpy`:

```python
# WRONG — too late, run__lose_money already snapshotted is_it_time_to_lose_money
import run__lose_money
import logic.utils.timing
logic.utils.timing.is_it_time_to_lose_money = lambda: True

# RIGHT — patch first, then run as __main__
import logic.utils.timing
logic.utils.timing.is_it_time_to_lose_money = lambda: True
import runpy
runpy.run_path("run__lose_money.py", run_name="__main__")
```

`runpy.run_path(..., run_name="__main__")` executes the file with `__name__ == "__main__"`, so `if __name__ == "__main__":` blocks (and top-level `asyncio.run(...)` invocations) fire.

## `python ./path/script.py` puts only the script's dir on `sys.path`

Direct script invocation adds the **script's parent directory** to `sys.path` — not cwd. Under `package-mode = false` (uv/poetry — project not installed into site-packages), repo-root packages only resolve when the repo root is on `sys.path`. Moving a script from `/workspace/run.py` → `/workspace/scripts/sub/run.py` silently breaks every top-level `import config.X` / `import logic.Y` that worked at the root. Symptom: `ModuleNotFoundError` at the first import line, fires only at production-style invocation (Docker `CMD`, systemd `ExecStart`, cron) — pytest hides it because pytest auto-adds rootdir to `sys.path`.

Three fixes:

| Fix | When |
|-----|------|
| `ENV PYTHONPATH=/workspace` | Dockerfile / env-driven runners. Broadest — also covers `docker exec ... python ...`. |
| `python -m pkg.sub.script` | Shell invocation when CWD is the repo root. `-m` adds CWD to `sys.path`. |
| `package-mode = true` + entry-point | Most invasive; project becomes pip-installable, paths irrelevant. |

Pairs with `refactoring-patterns.md` → "Smoke-test Docker import after `CMD` path changes" for the verification recipe.

## `float("NaN")` and `float("Infinity")` succeed silently

`float("NaN")`, `float("Infinity")`, `float("-Infinity")` all return non-finite floats without raising — unlike `int("NaN")` which raises `ValueError`. APIs returning numeric fields as JSON strings (TradeStation balances, some quote feeds) propagate non-finite values straight through downstream math. Guard immediately after the conversion:

```python
val = float(raw_value)
if not math.isfinite(val):
    raise ValueError(f"Non-finite {field_name}: {raw_value!r}")
```

Pairs with the null guard below — strings that fail to parse and explicit `null` values have different exception types (`ValueError` vs `TypeError`).

## JSON null vs missing key — `key in dict` doesn't catch `null`

`if "key" not in dict` catches absent keys but passes for `{"key": null}` (Python: `{"key": None}`). `float(None)` raises `TypeError`, not `ValueError` — different from the missing-key path. Each failure mode needs its own guard:

```python
if "equity" not in payload:
    raise ValueError("missing equity")
val = payload["equity"]
if val is None:
    raise ValueError("equity is null")
return float(val)
```

Common in broker/payment APIs where a documented field is occasionally returned as `null` (stale balances, transient account states). Presence-only checks let `None` flow into downstream `float()`/`int()`/string ops with cryptic stack traces.

## Protocol docstring as contract boundary for non-obvious invariants

When a Protocol method's return value has a non-obvious invariant (e.g., "must be broker MTM, not local reconstruction or `0.0`"), put it in the method docstring on the Protocol — not in a caller comment. Implementers and type-checker hovers surface the contract at the right level.

```python
class BrokerAdapter(Protocol):
    def get_balance(self) -> AccountBalance:
        """Return account balance. `equity` MUST be broker MTM (cash + unrealized
        P/L). NOT cash_at_hand, NOT 0.0 — 0.0 silently corrupts P/L computation."""
        ...
```

Underused because the invariant feels like consumer concern. The Protocol is the contract surface — that's where the rule belongs. Pairs with `code-quality-instincts.md` → "Document non-leakage contracts on pluggable Protocol surfaces".

## Keyword-only enforcement: audit external callers, not just the changed module

When adding `*` to a signature to make a parameter keyword-only (`def f(x, *, datasets):`), commits typically update internal callers in the same file but skip external ones. Positional callers now `TypeError` at runtime — invisible to lint, only caught by tests that actually hit the path.

Grep every callsite of every changed function across the repo before considering the refactor complete:

```bash
grep -rn -E "(fn1|fn2|fn3)\(" --include="*.py" -l | grep -v <changed-file>
```

For each hit, verify the now-keyword param is passed as `name=value`. CI passes if test coverage is thin — runtime is where it bites. Same audit discipline as renames/removals (`git-workflow.md` → "API Changes").

## DST drift in `datetime + timedelta(days=N)` vs epoch math

`datetime.fromtimestamp(t) + timedelta(days=85)` adds 85 calendar days in **local time**; `datetime.fromtimestamp(t + 85 * 86_400)` adds 85 × 86,400 seconds in **UTC**. Across a DST transition these differ by an hour. For tests asserting against system computation that uses epoch arithmetic, mirror the system's math — don't reconstruct via wall-clock `timedelta`.

```python
# system computes:  expiry_ts = creation_ts + lifetime_seconds
# wrong (drifts across DST):
assert expiry == datetime.fromtimestamp(creation_ts) + timedelta(days=85)
# right (mirrors the underlying invariant):
assert expiry == datetime.fromtimestamp(creation_ts + 85 * 86_400)
```

Same hazard in any "deadline" / "expiry" / "bucket boundary" code that mixes `timedelta(days=...)` with epoch-based persistence.

## Concurrent-writer race on deterministic `<target>.tmp` filename

`tmp = target.with_suffix(target.suffix + ".tmp"); write(tmp); os.replace(tmp, target)` is atomic vs crash and concurrent readers, **not** vs concurrent writers. Two overlapping writers race on the same `.tmp`; both `os.replace` it; whichever loses has its bytes silently overwritten. Use `tempfile.mkstemp(prefix=target.name + ".", suffix=".tmp", dir=target.parent)` per writer + `try/finally` cleanup so each writer renames its own bytes.

```python
fd, tmp_path = tempfile.mkstemp(prefix=target.name + ".", suffix=".tmp", dir=str(target.parent))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        write_fn(f)
    os.replace(tmp_path, target)
except BaseException:
    try: os.unlink(tmp_path)
    except FileNotFoundError: pass
    raise
```

Common in shared atomic-write helpers reused by multiple call sites (fetcher + standalone regen script, parallel agents writing per-key files). Pairs with the `os.fdopen` ownership pattern above — each writer owns its fd from acquisition.

## Argparse: validate the resolved value, not the raw `args.x or []`

Parse-time gates that read `args.flag` before `main()` defaults it can miss combinations that materialize after defaulting. Symptom: `--ts-symbol @MNQ` (no `--ticker`) passes a `len(tickers) > 1` check (raw `args.ticker is None` → `[]`), then `main()` defaults `tickers = ["NQ", "QQQ"]` and `tickers[0]` silently swallows the override into one ticker only — partial-application bug.

Two fixes (pick by intent):
1. **Move validation to `main()`** after defaulting: `if args.flag and len(resolved_list) != 1: parser.error(...)`.
2. **Require the explicit form** in `_parse_args`: `if args.flag and not args.x: parser.error("--flag requires --x to be set explicitly")`. Cleaner when "operate on all defaults" doesn't compose with the flag's semantics anyway.

Family: `dict.get(k) or fb` ≠ `dict.get(k, fb)` — both are "fallback collapsed silently" gotchas, but the argparse one bites at the resolved-vs-raw layering boundary, not the falsy-value one.

## Headless matplotlib default for CLI scripts

CLI / CI / web sessions need matplotlib headless. `plt.show()` blocks indefinitely without a display server, masquerading as a hung process — the script appears to print metrics then "stops" forever. Fix at the entry point: default `show_plot=False`, expose `--show-plot` to opt back in. Charts still write to disk via `savefig` — only the GUI window is gated.

```python
parser.add_argument("--show-plot", action="store_true",
    help="Open chart interactively. Default off so process exits in CI/web.")
```

`MPLBACKEND=Agg` (env var) is the alternative when the script can't be changed — Agg backend turns `plt.show()` into a no-op. Either path; the flag is more discoverable than the env var in long-lived projects.

## Keep optional/heavy deps out of the production image via `[dependency-groups].dev` + deferred imports

Three-part combo for excluding optional deps (`pyarrow`, `matplotlib`, `jupyter`, etc.) from production containers while keeping them available for dev/research:

1. **`pyproject.toml`** — declare under `[dependency-groups].dev`, not main `dependencies`.
2. **Dockerfile** — `uv sync --frozen --no-install-project --no-dev` excludes dev-group deps from the image's venv.
3. **Shared modules that ship in the image but only conditionally need the dep** — defer the import to function scope:

   ```python
   def regenerate_catalog(...):
       from logic.utils.candle_store import read_candles  # noqa: PLC0415 — dev-only dep
       ...
   ```

Verify the boundary holds before relying on it: grep production entry points' transitive imports to confirm nothing reaches the dev-only module. The deferred import is a tripwire — an accidental future production import fails loud with `ImportError`, not silently mid-call.

`uv.lock` still pins the dep (`--frozen` respects it), so dev builds are reproducible; only the image venv stays clean.

## Cross-Refs

- `~/.claude/learnings/api-design.md` — consistent response shapes (the principle behind the Pydantic serialization recommendation)
- `~/.claude/learnings/testing-patterns.md` — Python module-level singleton test isolation
- `~/.claude/learnings/web-auth-patterns.md` — OAuth bootstrap script error-path credential leakage
- `~/.claude/learnings/docker-image-patterns.md` — WORKDIR + relative path resolution (paired with the dev-dep pattern above)
