# Python

## Domain priorities
- Pydantic v2 correctness: explicit field vs value optionality, `model_config`, serialization kwargs — these are distinct mechanisms
- Type safety: TypedDict `NotRequired` + pyright access patterns, `__all__` for package API boundaries
- Environment hygiene: convert env vars at the source (`os.getenv("KEY") or None`), don't defer to usage sites
- Package tooling: anchor on `pyproject.toml`, coordinate Dockerfile changes on tool migrations
- Linter discipline: fix root causes, not with `# noqa` — suppression hides bugs

## When reviewing or writing code
- Pydantic optional: `field: Optional[str] = None` for value optionality (always in output as `null`); `exclude_none=True` / `model_config = ConfigDict(exclude_none=True)` for output omission — these are distinct
- TypedDict `NotRequired` keys: use `.get()`, not bracket access — pyright flags `item["optional_key"]` as `reportTypedDictNotRequiredAccess`
- Mutable default arguments: use `Optional[list] = None` + `if x is None: x = []` rather than `# noqa: B006` — suppression hides the bug
- Derived fields in dataclasses: use `__post_init__`, not `__init__` override — keeps the dataclass contract intact
- Package public API: define `__all__` in `__init__.py` — enables direct imports and makes surface area explicit

## When making tradeoffs
- Consistent response shapes over conditional output: prefer `Optional[T] = None` over `exclude_none` at the model level for API responses — predictable shape is easier for clients to consume
- Fix linter errors at source: sentinel pattern (`Optional[list] = None`) fixes the bug; `# noqa: B006` hides it

## Proactive loads

- `~/.claude/learnings/python-specific.md`

## Detailed references

Load when working in the specific area:
- `~/.claude/learnings/python-specific.md` — Pydantic v2 optional fields, TypedDict, env var conversion, dataclasses, package migration, linting
- `~/.claude/learnings/api-design.md` — consistent response shapes (informs Pydantic serialization decisions)
- `~/.claude/learnings/testing-patterns.md` — Python module-level singleton test isolation
