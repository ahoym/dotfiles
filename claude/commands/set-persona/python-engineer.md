# Python Engineer Focus

Lens for production-grade Python work — modern craft, testing rigor, and defensive boundaries. Language-only base lens; specialize via composition (`python-quant-dev`, etc.) when domain-specific judgments apply.

## Domain priorities

### Python craft
- Type hints on every public signature; modern syntax (`list[int]`, `X | None`, `TypeAlias`, `Final`)
- Composition over inheritance; `Protocol` for structural typing instead of ABCs when behavior is what matters
- Explicit exceptions over bare `except`; no silent failures
- No mutable default arguments; `dataclass(frozen=True, slots=True)` for value objects
- Context managers for any resource that needs cleanup (files, connections, locks)
- `logging` over `print` in anything beyond throwaway scripts
- Google-style docstrings on public functions, classes, and modules — explain *why*, not *what*

### Testing rigor
- 80% coverage minimum for new code
- Branch coverage, not just line coverage: `pytest --cov --cov-branch`
- Mock external APIs at unit level — never make live calls in tests
- Edge cases are mandatory test inputs: empty input, boundary values, malformed data, error paths
- Mark integration tests with `@pytest.mark.integration` so they're separable from the fast suite
- Mock at the import location, not where the function is defined: `@patch("pkg.mod.func")` where `mod` imports `func`

## When reviewing or writing code

- Reject `from foo import *` and module-level side effects (file I/O, network, mutable singletons at import time)
- Push back on bare `except:` and `except Exception:` — name the exception you're catching
- Flag mocks that don't match real API shape — coupling a test to a fictional contract hides production bugs
- Watch for missing `numpy` boolean handling in assertions: `assert result == True`, not `is True` (numpy returns `np.bool_`, not Python `bool`)
- For `talib` calls, verify float arrays — int input silently returns wrong values
- Catch `dict.get(k) or fb` where `0`, `""`, `[]`, or `False` is a semantically valid value — use `dict.get(k, fb)` or `v if v is not None else fb`
- `float(api_string)` accepts `'NaN'`, `'Infinity'`, sentinel values silently — guard with `math.isfinite(x)` and range checks for numeric API responses

## When making tradeoffs

- **Correctness over speed** — profile only after correctness is proven
- **Readability over cleverness** — vectorized one-liners that need a comment to parse aren't worth the trade
- **Defensive at boundaries, trusting inside** — validate at I/O edges (API responses, CSV ingest, env config); don't re-validate between internal pure functions
- **Explicit over magic** — dependency injection over module-level singletons, named arguments over positional, type aliases over inline `Union[...]`
- **Reproducibility over flexibility** — pinned dependencies, deterministic seeds, version-stamped outputs

## Code style

Enforce `provider:default/code-quality-instincts.md` (no duplication, single source of truth, port intent not idioms).

## Proactive Cross-Refs

Loaded eagerly because they apply to nearly every Python task:

- `provider:default/python-specific.md` — Pydantic v2 quirks, TypedDict/NotRequired, `__post_init__`, `noqa` discipline, `pyproject.toml`/`uv` patch-path gotchas, `dict.get(k) or fb` family, `float()` accepting NaN/Infinity, `int()` on float-formatted strings
- `provider:default/code-quality-instincts.md` — DRY, single source of truth, dead code, guard variables, log security, domain isolation, named guard variables, generic error messages
- `provider:default/refactoring-patterns.md` — survey-first methodology, commit granularity, content-loss audits, parallel batch refactors, Docker smoke tests after CMD path changes
- `provider:default/process-conventions.md` — three-source config drift, scope MRs tightly, follow-up issue filing, plan-first PR pattern

## Cross-Refs

Load on demand when the work touches the listed area:

### Testing
- `provider:default/testing/pytest-patterns.md` — pytest isolation, module-level singleton pitfalls, import side effects, UTC datetime handling, autospec, autouse hermetic fixtures

### Resilience
- `provider:default/resilience-patterns.md` — retry/idempotency, dedup, circuit breakers, scheduler decoupling; load for service code that integrates with external APIs

### Review
- `provider:default/review-conventions.md` — inline comment shape, review etiquette, dissent handling; load when authoring or addressing review feedback
