Python idioms and gotchas for Pydantic v2, TypedDict, dataclasses, env var handling, and package management.
- **Keywords:** pydantic, optional fields, model_dump, exclude_none, TypedDict, NotRequired, pyright, dataclass, __post_init__, __all__, pyproject.toml, uv, poetry, noqa, linter suppression, Protocol, PEP 544, structural typing, pydocstyle, private module, patch path, from None, exception chain, fchmod, mkstemp, fd leak, bool int subclass, isinstance bool, httpx Timeout, split phases, async blocking, sys.path, PYTHONPATH, package-mode, ModuleNotFoundError, script relocation, Docker CMD, python -m, keyword-only, signature audit, positional-to-keyword, dependency-groups, --no-dev, deferred import, dev-only dep, container venv, pyarrow, np.roll, circular shift, rolling window look-ahead
- **Related:** ~/.claude/learnings/api-design.md, ~/.claude/learnings/testing/pytest-patterns.md, ~/.claude/learnings/testing/testing-patterns.md

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

## Relocating a whole test class orphans `import pytest` in the source file

When you move a test class out of a file wholesale, the file's `import pytest` often goes unused — `pytest` is typically only consumed by `pytest.raises` / `pytest.mark.*` *inside* the moved class. Lint catches it (F401), but only after the move, so an automated address cycle that relocates tests predictably trips one follow-up lint commit. Scan the source file's remaining `pytest.` usages before committing the relocation.

## Extracting a module: route shared calls through the origin module to avoid patch churn

The inverse of the above. When pulling a cohesive block into a *new* module that still reuses the origin module's helpers, reference them via the origin module (`operations.write_x(...)`) rather than re-importing by name (`from operations import write_x`). Tests that `patch("origin.write_x")` keep working unchanged — the new module resolves the name on the origin module at call time, so a single patch point covers both the origin and the extracted code. Only the import-source lines of the *moved* symbols themselves change in tests; the dozens of patches on reused helpers don't.

## `StrEnum.value` vs a stored `.name` silently never compares equal

`TradeDirection.LONG.value` is `"long"`; if state was persisted as the uppercase member *name* (`"LONG"`), `enum_member.value == stored` is always `False`, so any guard keyed on it silently misfires (e.g. closes+reopens every tick). Compare on the form the data was written in — `.name` vs `.name`, or normalize both ends. A test that exercises the "should be equal" branch catches it; a dry-run-only test won't.

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

## `from_dict` stays parse-only; typed-field promotion shifts `to_dict()` output

- Migration/normalization logic belongs in `__post_init__`, not bolted onto a `from_dict` factory after `cls(**kwargs)`. Post-construction mutation in the factory breaks the parse-only contract and creates a hidden init path the plain constructor skips.
- Promoting a bare-string dict key to a typed dataclass field (`x: Dict = field(default_factory=dict)`) is a 3-part change — enum/key + dataclass field + read-site — AND shifts `to_dict()` output: every record now emits the new key (e.g. `"investedAllocation": {}`). Check serialization consumers before promoting; safe only when writes merge (`{**old, **new}`) rather than overwrite.

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
| `sys.path.insert(0, str(PROJECT_ROOT))` shim atop the script | Per-script fix for a repo of standalone CLI scripts (`PROJECT_ROOT = Path(__file__).resolve().parents[N]`). Needs `# noqa: E402` on the now-below-code `logic`/`config` imports. The tell that a script is missing it: its siblings in the same dir all have the shim and import fine, it alone `ModuleNotFoundError`s. |

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

## `timedelta != 0` is silently `True` — ordering ops raise, `!=` doesn't

Cross-type `!=` between `timedelta` and `int` returns `True` silently (verified Python 3.13.2): `timedelta(0) != 0` → `True`. Same for numpy object arrays — `np.array([timedelta(0)], dtype=object) != 0` → `[True]`. This is distinct from ordering (`<`, `>`, `<=`, `>=`), which DO raise `TypeError` on `timedelta` vs `int`. The reason: `timedelta.__ne__(int)` returns `NotImplemented`, and Python's `!=` fallback resolves un-comparable objects to "not equal" by identity; ordering operators have no such fallback.

Consequence for time-series code: a "is this a day boundary?" check written as `(date_a - date_b) != 0` is **always** `True` — every bar reads as a boundary, so per-bar returns get treated as daily returns and annualized Sharpe is wildly off. Use ordinals (`date.toordinal()`) for date-boundary arithmetic on date arrays, not raw `date`/`timedelta` vs int. Before flagging such a comment as "wrong — that raises TypeError," run it in the actual venv: `!=` has the `NotImplemented`→identity fallback that ordering ops lack.

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

## Argparse `default=os.environ.get("KEY")` leaks the value into `--help`

argparse embeds the *resolved* default verbatim in `--help` output. If the env var is set when `--help` runs, a real secret/account id lands in terminal scrollback, screen-share, or CI logs. Use `default=None` in the parser and resolve in the body after `parse_args()`: `account = args.account_id or os.environ.get("KEY")`. Preserves the flag → env → auto-discovery chain and never prints the live value.

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

## `sys.modules` Pre-Mock Unblocks `__init__.py` Singleton Exports

Singletons exported from a package's `__init__.py` (e.g. `schwab_adapter = _SchwabAdapter()`) are normally test-hostile — instantiation runs at import time, hitting credentials/network. The fix in `tests/conftest.py`:

```python
import sys
from unittest.mock import MagicMock
sys.modules["mypkg.client"] = MagicMock()  # BEFORE any test import touches mypkg
```

When tests later do `from mypkg import singleton`, Python finds the pre-mocked client module and `__init__.py`'s constructor runs against the mock. Singleton becomes test-safe without restructuring the production code.

Constraint: the pre-mock must execute before the first import of the affected package — `conftest.py` at the test-root level satisfies this for pytest.

## pydocstyle D417 fires on *partial* Args blocks

D417 ("Missing argument descriptions") triggers only when a Google-style `Args:` block documents *some* parameters but omits others — not when there's no `Args:` block at all. Condensing a docstring by deleting the obvious arg lines while keeping the interesting one breaks the build. Fix: either document every arg, or drop the `Args:` block entirely and fold the one meaningful arg into prose. (Same family as the D101/D102 notes above — you can't shorten by deleting a docstring either.)

## `Path.with_suffix()` swaps only the *last* suffix — test the inputs that distinguish it from `.replace()`

`pathlib.Path("token.bak.json").with_suffix(".lock")` → `token.bak.lock` (only the final suffix changes), and a suffix-less `tokenfile` → `tokenfile.lock`. A naive `str.replace(".json", ".lock")` diverges on both: multi-dot names and names lacking the expected extension. When a derived-path helper uses `.with_suffix()`, the test must assert on exactly those two inputs — otherwise a future refactor to `.replace()` passes the happy-path test and silently mishandles them. Same discipline as "distinguish a helper from its closest sibling" — pick inputs where the two implementations disagree.

## Keep a derived property total; fail loud at the consuming gate, not inside it

A derived `@property`/Optional accessor evaluated over many records (a per-trade
metric in a scan, a per-row field in a sweep) should stay **total** — return
`None`/sentinel on a degenerate input rather than `raise` — so one bad record
can't crash the whole iteration. Put the fail-loud (`raise`/`SystemExit`) at the
*script or gate that consumes the aggregate*, where it can report "cannot proceed"
with context. Pairs the two: the property guards `entry_price <= 0` → `None`; the
script that gates a decision filters those out and `SystemExit`s if nothing
usable remains. Raising inside the hot property instead turns a single bad row
into a total failure and scatters the diagnostic away from the decision point.

## An empty `{}` file is `not None` — use a truthy check to fall through to a fallback source

A file-read helper that returns `None` for a missing file but the parsed value (`{}`, `[]`) for an empty/partial one means `if data is not None:` treats an empty stub as authoritative. When the file is one tier of a fallback chain (per-account → legacy shared, cache → source), an interrupted/partial write leaves `{}` that *shadows* the fallback tier — the exact lost-state bug fallbacks exist to prevent. Use `if data:` (truthy) so empty content falls through, and apply it symmetrically on **both** the read and write side of the pair, or they disagree on how an empty stub is handled.

```python
existing = read_data_from_file(path)   # None if missing, {} if file contains {}
if existing:                           # NOT `is not None` — empty stub falls through
    return merge(existing, update)
return write_to_fallback(...)
```

Distinct from the `dict.get(k) or fb` and `JSON null vs missing key` entries: this is about a *file-existence vs file-content* contract, not a dict value.

## A finiteness check rejects `NaN`/`Inf` but not a *finite* sentinel

`math.isfinite` is necessary-not-sufficient when a vendor's "no data" marker is itself finite — TradeStation emits `INT32_MIN/100` (`-21474836.48`) for missing/halted reads, which passes `isfinite` and every `== 0`/`< 0` domain guard, then flows into sizing as a ~21.4M magnitude. Reject it explicitly by magnitude alongside the finiteness floor (`float("-21474836.48") == -2147483648/100` is exact, so equality works). Two independent floors — pairs with the `float("NaN")` entry above, which only closes the non-finite half.

## `dict.get(key, default)` erases the absent-vs-present-empty distinction

`data.get("Positions", [])` returns `[]` for both an *absent* key (incomplete/degraded API read) and a *present-and-empty* one (genuine flat). When that distinction is load-bearing — a source-of-truth reconcile where empty means "affirmatively nothing" — defaulting conflates a read failure with a real empty result, so an incomplete read drives a destructive decision (wipe config, re-open a still-held position). Use `if key not in payload: raise` to fail loud and retry the tick. Sibling to `dict.get(k) or fb ≠ dict.get(k, fb)` (value-falsiness axis) — this is the key-presence axis.

## A finiteness guard must spare a *legitimate* NaN sentinel — distinguish it from impossible ±inf/negative

When NaN is a valid domain sentinel (an indicator during warm-up, "no reading yet"), a blanket `require math.isfinite(x)` wrongly raises on it. Split the contract: NaN → the documented safe path (skip the decision, no-op), `±inf`/negative/out-of-domain → raise, and gate the computation on `x > 0` so NaN and 0 both fall through without acting (`NaN > 0` and `0 > 0` are both False). Put the guards *after* any pass-through early-return, so off-path ticks carrying dummy `0.0`/NaN values (a non-target branch) aren't validated against the on-path contract. Sibling to "`float("NaN")`/`float("Infinity")` succeed silently" and "A finiteness check rejects NaN/Inf but not a finite sentinel" above — those close the *reject* half; this one stops a guard from over-rejecting a NaN that's load-bearing.

## D205 fires when a docstring is compressed into a single paragraph

pydocstyle wants a one-line **summary**, a blank line, then the body. Collapsing a multi-paragraph docstring into one flowing paragraph (the natural move when tightening for conciseness) trips `D205 "1 blank line required between summary line and description"`. Keep a short summary line + blank line before the detail. Same family as the D403/D417/D101 rules above: *shortening* a docstring can introduce a lint error, so re-run `ruff` after any trim.

## A "last bar / record timestamp" you adopt may be tz-aware while the rows it's subtracted against are naive

Two timestamp producers in one codebase need not agree on tz-awareness — e.g. `Candle.to_readable_time()` → `datetime.fromtimestamp(ts, tz=UTC)` (aware) vs a loop stamping records with bare `datetime.fromtimestamp(ts)` (naive). Adopting the aware accessor as a value subtracted against the naive records raises `TypeError: can't subtract offset-naive and offset-aware datetimes`. Match the representation the *consumer* compares against (here the naive `fromtimestamp` form); don't assume a suggested accessor (`x_axis[-1]`, `.timestamp`, etc.) is type-compatible with what subtracts it.

## `json` round-trips NaN/Infinity by default — a type-only float gate passes a poisoned value

Python's `json.dumps`/`loads` emit and parse `NaN`/`Infinity`/`-Infinity` literally (`allow_nan=True` default), so a deserialized numeric field can be non-finite even from "valid" JSON. A gate that checks type only — `isinstance(x, (int, float)) and not isinstance(x, bool)` — passes `nan`/`inf` (both are `float`). Add `math.isfinite(x)` whenever the value feeds a comparison or accumulator. Failure mode: a non-finite value used as a comparison anchor is *sticky* — `x > nan` is always `False`, so e.g. a NaN high-water mark never updates and every downstream `>`/`>=` test silently no-ops. Reject at the write boundary (`json.dumps(..., allow_nan=False)` raises) or the read boundary (`math.isfinite`).

## `ruff --fix` + `ruff format` don't fix every rule — re-run `ruff check` after

`ruff check --fix` only auto-fixes *fixable* rules; non-autofixable ones (e.g. `D205` "1 blank line required between summary and description") are reported but left in place, and `ruff format` reformats around them without fixing them. So a `--fix` → `format` pass can leave a real lint error that lands in a commit and only surfaces at a later full `ruff check .` (or a PR gate). Re-run `ruff check <file>` after the fix+format pass, and read the `Found N errors (M fixed, K remaining)` line — `K remaining > 0` is the tell that `format` won't clear.

## `x or fallback` is correct for a display label — the value-domain `is not None` rule inverts

The `dict.get(k) or fb` / truthy-vs-`is not None` caution applies to *values used
in logic*, where `0` / `""` / `[]` are legitimate and `or` wrongly collapses them.
For a human-readable diagnostic *label*, the rule flips: `account_id or "balance"`
is the right call — an empty-string id under `is not None` renders a useless empty
prefix (`": Equity is non-finite"`), and an empty id carries no diagnostic value
distinct from a missing one. Pick by whether the value is consumed (use
`is not None`, preserve falsy) or merely displayed (use `or`, fold falsy to the
fallback).

## `ruff check <file>` parses an explicitly-named non-`.py` file as Python

Ruff lints files passed explicitly *by argument* regardless of extension — so a
"check the changed files" loop that includes a `README.md` / `.txt` / `.json`
makes ruff parse prose as Python and emit hundreds of bogus syntax errors (a
markdown README yielded 1343). Filter the file list to `*.py` before passing to
`ruff check`, or pass a directory and let ruff's own include/exclude rules apply.

## `np.searchsorted(days, t, "right") - 1` underflows to -1 — a silent array-TAIL (future) read

The standard "as-of" index (last bar at or before `t`) is `searchsorted(...,'right')-1`, which returns **-1** when `t` precedes the first bar — and `series[-1]` then reads the *last* element, i.e. a future value (look-ahead in a time series). A `max(idx, 0)` clamp hides it as a stale read of bar 0; neither is what you want for a pre-history lookup. Guard at the consumer: `series[idx] if idx >= 0 else float("nan")` (NaN-on-underflow), and for an N-bar lookback guard `idx >= N`. Consolidate multiple as-of helpers onto one core with one documented underflow policy so a reader can't infer the wrong edge behavior from a sibling.

## Temporary module-global rebind: save/restore under try/finally, restore the *saved* value

Code that swaps a sibling module's global for a sweep (`other.KEY = "rsi10"`; run; reset) must wrap set/reset in `try/finally` and restore the value it *read*, not a hardcoded literal — a mid-loop `raise` otherwise skips the reset and silently poisons every later read in the process with the wrong value, and a hardcoded reset (`= "rsi14"`) breaks when the default changes. Document the swap contract at the global's definition site (process-global, not reentrant). The cleaner fix is to thread the value as an argument; try/finally is the proportionate minimum when the call structure is shared.

## `@dataclass(frozen=True)` doesn't freeze a dict/list field's *contents* — wrap in `MappingProxyType`

`frozen=True` blocks attribute *rebinding* (`obj.attr = x` → `AttributeError`), not mutation of a mutable field — `obj.choices['k'] = v` still mutates the shared instance. For a real read-only promise, wrap the field in `__post_init__` (the frozen-init escape hatch is `object.__setattr__`):

```python
@dataclass(frozen=True)
class LegTarget:
    choices: Mapping[str, str]          # not dict[...] — the view isn't a dict
    def __post_init__(self) -> None:
        object.__setattr__(self, "choices", MappingProxyType(dict(self.choices)))
```

`MappingProxyType` raises `TypeError` on item assignment; reads (`in`, `[]`, `.values()`, `sorted()`) are unchanged so call sites don't churn. The plain frozen-rebind test (`obj.attr = ...` → `AttributeError`) does NOT cover this — add a `pytest.raises(TypeError)` on `obj.field['k'] = ...`. `__post_init__` also needs a one-line docstring or ruff D105 fires.

## A stateful instance in a dispatch list: its construction site sets its lifetime

In a `(identity, callable)` dispatch table, *where* a stateful callable is constructed decides whether it's a singleton or rebuilt per call:

```python
DISPATCH = [
    (acct_a, StatefulAlgo(...)),                       # built ONCE at module load
    (acct_b, lambda ds: wrap(StatefulAlgo(...)(ds))),  # built EVERY call → state never accumulates
]
```

Passed directly as the list element it's constructed once (state persists across the loop that iterates `DISPATCH`); constructed *inside* a per-call `lambda` body it's fresh every invocation, silently defeating any across-call state (hysteresis, caches, counters). Hoist to a named var when it must live inside a lambda. A diff-only reviewer can't distinguish the two — the loop that iterates `DISPATCH` isn't in the hunk — so "this resets per poll" is a hypothesis to check against the full file, not a finding.

## `match` over an Enum — `assert_never`, Not a Trailing `raise`, for Static Exhaustiveness

A `match side:` over an enum that ends in `raise ValueError(...)` only catches a missing case at *runtime* — adding a new member without a `case` slips past the type checker until that member is actually dispatched. Make non-exhaustiveness a check-time type error with `assert_never` (`from typing import assert_never`), in either form: **after the match** (a bare `assert_never(side)` on the line after the last `case`) or as a **wildcard arm** (`case _ as x: assert_never(x)`). Prefer the after-match form — a wildcard arm makes the match exhaustive, so any trailing `raise` you keep alongside it becomes unreachable dead code. The bare `raise` alone covers literal method/attr renames *inside* the arms (real references) but **not** new members, so it undercuts any "caught at check-time" claim for the enum itself. No need to keep a separate runtime `raise`: `assert_never` itself raises `AssertionError` at runtime and — being a function call, not an `assert` statement — is **not** stripped by `python -O` (unlike a bare `assert`; see the assert-footgun entry above), so the fail-loud guarantee survives on a hot path.

## "Build once" for a per-iteration-derived object whose source is reassigned externally → property setter

When a hot loop rebuilds a derived wrapper every iteration (`Pipeline((self.x,)).run(...)` per bar) and `self.x` can be reassigned *after* `__init__` (a config factory sets it; a test/research path does `obj.x = ...`), don't build the derived object inline in `__init__` (it goes stale on reassignment) nor cache-and-compare per call (noisy). Make `x` a property whose setter rebuilds the cached derived object once per assignment:

```python
@property
def risk_overlay(self): return self._risk_overlay

@risk_overlay.setter
def risk_overlay(self, overlay) -> None:
    self._risk_overlay = overlay
    self._pipeline = Pipeline((overlay,)) if overlay is not None else None
```

The setter fires on `__init__`'s own assignment *and* any external reassignment, so the loop reuses `self._pipeline` allocation-free while staying correct when the source is swapped.

## `getattr(x, "attr", default)` on a *required* Protocol member silently masks non-conformance

When a Protocol declares `attr` required and every conforming implementer carries it, a consumer reading `getattr(obj, "attr", default)` is self-contradictory: the default can *only* fire for a non-conforming implementer, so it green-lights the contract violation (and a "safe" default like `True` may hide a real bug). Read `obj.attr` directly so a missing attr fails loud (`AttributeError`), and make test fakes declare the attr to conform. Consumer-side mirror of "`@runtime_checkable` Protocol does NOT enforce attributes" above — the contract lives on the Protocol; trust it at the call site instead of re-tolerating its absence.

## A dataclass field-coercion `frozenset(x)`/`set(x)`/`tuple(x)` silently shreds a bare `str`

`str` is iterable, so a `__post_init__` that coerces an iterable field accepts a bare `"TQQQ"` and shreds it into `frozenset({'T', 'Q'})` rather than raising — a single-element value silently becomes a per-character collection. Guard `isinstance(x, str)` *before* the coercion:

```python
if isinstance(self.tickers, str):
    raise TypeError(f"tickers must be an iterable of symbols, not a bare str: {self.tickers!r}")
if not isinstance(self.tickers, frozenset):
    object.__setattr__(self, "tickers", frozenset(self.tickers))
```

Bites hardest where the field's whole purpose is a can't-drift invariant (e.g. a ticker universe pre-fetched from it): the bogus set passes construction and surfaces far downstream as missing-data, not at the call site. Same "implicit type widening" family as `bool` being an `int` subclass above.

## A rename onto a name shadowed by a local var → linter strips the (now-"unused") import

A whole-word rename that lands on a name already used as a *local* binding collides
silently: renaming the imported `_net_r`→`net_r` in a function holding `net_r = []`
makes `net_r(...)` call the list (`'list' object is not callable`). Worse — because the
local shadows the import for the *entire* function (Python's function-scope rule), the
module-level import now looks unused, so `ruff --fix` **deletes** it; fixing the local
then `NameError`s on the missing import. Two rules: before a token-rename, grep the
target files for local bindings of the new name (`^\s*<name>\s*=`, `for <name>`,
`as <name>`); and never run `ruff --fix` between introducing a shadow and resolving it
(autofix strips a genuinely-needed but transiently-shadowed import). Fix = restore the
import and rename the *local* (e.g. `net_r`→`net_rs`), not the import.

## ruff D202: removing a nested def orphans the blank-after-docstring

D202 ("no blank line after function docstring") is exempted when the line after the docstring is a nested `def`/`class` — so `"""…"""\n\n    def seg(...)` passes. Delete that nested function in a refactor (e.g. inlining it to an imported helper) and the now-orphaned blank line in front of the next *statement* trips D202. Drop the blank in the same edit; `ruff check --fix` resolves it.

## `np.roll` is circular — the wrapped front of a rolling-window helper is a latent look-ahead

`np.roll(a, k)` wraps the last `k` elements into the *first* `k` slots, so a rolling
min/max built as `reduce(np.minimum, (np.roll(a, off) for off in range(w)))` contaminates
indices `0..w-2` with end-of-series (future) values, and a shift-1 cross detector
(`np.roll(x, 1)`) wraps the final bar into index `0`. Benign only while every consumer
masks the front (warmup ≥ w); a low-warmup reuse silently leaks future data into the
series. Neutralize at the source — `out[:w-1] = inf`/`-inf` (min/max-neutral), `flag[0] =
False` for the shift — rather than trusting downstream masking. Sibling to the
`np.searchsorted(..., "right") - 1` underflow entry: both are numpy index idioms that
silently read tail/future data in a time series.

## Cross-Refs

- `~/.claude/learnings/api-design.md` — consistent response shapes (the principle behind the Pydantic serialization recommendation)
- `~/.claude/learnings/testing/pytest-patterns.md` — Python module-level singleton test isolation
- `~/.claude/learnings/web-auth-patterns.md` — OAuth bootstrap script error-path credential leakage
- `~/.claude/learnings/infrastructure/docker-image-patterns.md` — WORKDIR + relative path resolution (paired with the dev-dep pattern above)
