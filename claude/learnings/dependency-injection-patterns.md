Dependency injection and boundary enforcement patterns for multi-implementation codebases (broker adapters, storage backends, multi-provider clients).
- **Keywords:** composition root, dependency injection, import discipline, protocol, ABC, CI lint, abstraction erosion, multi-adapter, import-time side effects
- **Related:** ~/.claude/learnings/refactoring-patterns.md, ~/.claude/learnings/code-quality-instincts.md, ~/.claude/learnings/testing/testing-patterns.md

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
