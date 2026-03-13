# Python-Specific Patterns

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

- **Takeaway**: Derived dataclass fields belong in `__post_init__`, not a custom `__init__`.

## pyproject.toml as stable anchor across package manager migrations

`pyproject.toml` is the stable artifact across Python package manager changes (requirements.txt -> Poetry -> uv). Lock files and tooling-specific configs are the disposable parts. When migrating, `pyproject.toml` persists while everything else gets replaced.

- **Takeaway**: Build migration plans around pyproject.toml as the anchor file.

## Dockerfile updates alongside package manager changes

Package manager migrations require coordinated Dockerfile updates. The build layer that installs dependencies changes when the tool changes.

- **Takeaway**: Package manager change = Dockerfile change. Always.

## Migration scripts committed alongside the migration

Commit a dedicated migration script (e.g., `scripts/migrate-poetry-to-uv.sh`) alongside the migration PR. Captures the exact steps used, serves as documentation and a reproducible recipe for similar migrations.

- **Takeaway**: Non-trivial tooling migrations deserve a committed migration script.

## Fix Root Causes, Don't Suppress Linter Warnings

When a linter flags a real issue (e.g., B006 mutable default arguments), fix the underlying problem rather than adding `# noqa`. The sentinel pattern (`Optional[list] = None` + `if x is None: x = []`) fixes the bug; `# noqa: B006` hides it. Suppression is appropriate only when the linter is genuinely wrong, not when the fix is straightforward.

- **Takeaway**: `# noqa` is for false positives, not shortcuts — fix the underlying issue when the linter is right.

## Use `__all__` to Define Explicit Public APIs

In `__init__.py` files, define `__all__` to control what a package exposes. This lets users import directly from the package (`from pkg import Class`) instead of reaching into submodules, signals the intended public API to tooling and linters, and makes the package's surface area explicit and reviewable.

- **Takeaway**: Every `__init__.py` that re-exports should have an `__all__` defining the public API.

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
