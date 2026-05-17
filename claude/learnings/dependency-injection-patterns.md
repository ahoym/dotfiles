Dependency injection and boundary enforcement patterns for multi-implementation codebases (broker adapters, storage backends, multi-provider clients).
- **Keywords:** composition root, dependency injection, import discipline, protocol, ABC, CI lint, abstraction erosion, multi-adapter, import-time side effects
- **Related:** ~/.claude/learnings/refactoring-patterns.md, ~/.claude/learnings/code-quality-instincts.md, ~/.claude/learnings/testing/testing-patterns.md, ~/.claude/learnings/testing/pytest-patterns.md

---

## Composition root pattern

When introducing a protocol/ABC for multiple implementations, designate exactly ONE file as the composition root — the only file allowed to import concrete implementations. Every other file imports the protocol type only. The composition root reads config/env and constructs wired domain objects; consumers receive them as parameters.

**Why the single-file rule:** abstractions silently erode through "just this once" imports. One PR adds `from <concrete> import ...` inside a supposedly abstract layer, code review misses it, the dependency graph collapses back. The rule "exactly one file imports concretes" is enforceable; "use the abstraction" is not.

Composition root content is wiring, not logic: read env var → import matching concrete → instantiate → bind to domain objects (typically a frozen dataclass like `Account { id, adapter, label }`) → export. Live at `config/accounts.py` or similar — close to other config, with a file-level docstring calling out the composition-root role so the `config/` → `logic/` import direction isn't surprising.

## CI lint for dependency discipline

Pair the composition root with a CI lint that fails the build when forbidden imports appear. Ruff custom rule, a grep script, or an `import-linter` config — any mechanism that runs on every commit.

Example rule shape:

```
Allowed:
  composition_root.py  → concrete_a/*, concrete_b/*
  consumers/*          → protocol.py only
Forbidden:
  consumers/*          → concrete_a/*, concrete_b/*
```

Introduce the lint immediately after the composition root lands, even if nothing violates it yet. Zero-cost guardrail against future drift — a stray `from concrete import X` inside a consumer fails CI on the next push, not at code review N weeks later.

## Testability: move import-time side effects into the adapter constructor

Modules that call `auth.client_from_file()`, `get_secret()`, or similar at import scope break testing: any file that transitively imports them requires real credentials. Move the side effect into the adapter class's `__init__`, invoked from the composition root.

After the move: tests import the module without credentials; missing-credential failures happen at adapter instantiation (in the composition root), which is where they belong. Do this during the same PR that introduces the adapter class — avoiding it later is hard because test files accumulate.

## Why protocols (not ABCs) for Python

Python `Protocol` (PEP 544) is duck-typed — concrete implementations don't need to inherit. This matters when wrapping existing module-level functions as an adapter: you can write a `_SchwabAdapter` class that delegates to existing functions without touching the existing module hierarchy. ABC inheritance would force the concrete to declare inheritance, which couples the adapter to the protocol file permanently.

Use ABC only when you need runtime `isinstance()` checks (rare) or abstract-method enforcement at instantiation (rarer).

## Protocol return types: domain models, not first-implementation dicts

When a protocol method returns data, return typed dataclasses defined in a shared models layer — not dicts shaped like the first implementation's API response. `get_balance() -> AccountBalance` forces every adapter to normalize into the same typed contract. `get_balance() -> dict` with a comment "returns Schwab-shaped dict" makes the "broker-agnostic" protocol secretly Schwab-native, and every future adapter must reverse-engineer and reproduce that shape.

Place return-type models alongside existing domain models (e.g., `logic/models/AccountBalance.py` next to `logic/models/Candle.py`), not co-located with the protocol. Keeps the protocol file small (signatures + imports) and follows existing conventions for cross-boundary data shapes.

## Composition root env-gating and test ergonomics

An env-gated composition root (`BROKER=schwab|tradestation`, raises `RuntimeError` if unset) is safe for tests **when dependency discipline ensures test code never imports it**. If `logic/libs/*` takes `Account` as a parameter, tests construct `Account(broker=FakeBrokerAdapter(), ...)` directly — they never touch `config/accounts.py`, so the env gate never fires. Only entry-point integration tests need the env var. This works precisely because the CI lint (forbidding `logic/libs/* → config/accounts.py`) guarantees the boundary holds.

## Migration ergonomics: env gate vs legacy entry-point scripts

Tests can be solved by the DI boundary, but legacy entry-point scripts (`run__*.py`, scratchpads, ad-hoc REPLs) that import the composition root directly will break the moment a hard `raise RuntimeError("ENV not set")` lands. Every developer running an old script must now know about the new env var.

For migration safety, default to the prior implementation and log the implicit choice:

```python
if BROKER is None:
    logger.warning("BROKER unset; defaulting to %r", _DEFAULT_BROKER)
    BROKER = _DEFAULT_BROKER
```

Backwards compat preserved, intent surfaced in logs (so the migration isn't silently masked), explicit `BROKER=other` still selects deliberately. Drop the default once all entry points are updated and a deprecation window has passed.

## Test-only DI parameters are a smell

If you're tempted to add a constructor parameter whose only purpose is to inject a test double, prefer the alternatives: monkey-patch the underscore attribute in the test, use a factory, or build a fixture. A "DI seam" no production caller ever passes bloats the public API and signals "this knob exists" to readers when it doesn't.

**Why:** the `# noqa: D107`-style `_http: httpx.Client` field is already an internal attribute by convention. Tests writing `client._http = MagicMock()` is idiomatic Python. Adding `http_client: httpx.Client | None = None` to `__init__` to spare tests from the underscore poke trades a real public-surface change for cosmetic test cleanliness.

**How to apply:** before adding a constructor param "for testability," check that at least one production code path will pass it. If not, leave the existing internal attribute and let tests reach in.

## Adapter owns broker-specific identity translation

When a broker uses a different identifier than the human-friendly account number for its API (Schwab: account number → account hash; many APIs: user id → external uid), put the translation **inside the adapter**, not on the domain model. Adapter constructor takes the map: `SchwabAdapter(client, account_hashes={...})`. The model holds the human id; consumers pass `account.id`; the adapter resolves and forwards.

If translation lives on the model (e.g., `Account.id` holds the hash), broker semantics leak into the supposedly broker-agnostic model — every consumer must know which broker it's talking to in order to choose the right id field. The whole point of the adapter is to absorb that knowledge.

## Diagnose incomplete migration via entry-point import chain

Composition root + protocol delivers import-time independence only when no broker-agnostic call site imports legacy concrete modules at the top level. When `BROKER=newbackend` crashes at startup despite the composition root being correctly gated, the gap is at the call sites — not the abstraction.

Diagnostic: trace `from X import Y` from the entry point outward; flag any top-level import of legacy concrete modules. Function-scope imports (`def foo(): from legacy import x`) are import-safe — they only fire on call, so a code path that doesn't reach them stays clean.

Blocker set = union of top-level legacy-concrete imports along the entry point's import graph. CI lint prevents *new* violations; this diagnostic catches *existing* ones inherited from before the lint landed.

Lazy imports (function-scope `from X import Y`) are also a deliberate tool: when you can't yet move a side-effecting import behind the composition root, deferring it inside a getter function is a cheap way to make the module import-safe for env-gated alternatives. Treat as a transitional measure — the cleaner end-state is the side effect inside the adapter constructor.
