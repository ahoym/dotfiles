# Skill Authoring

## Skill-Reference Pattern

**Utility: High**

Files under `.claude/commands/` are automatically registered as invocable skills — including `_shared/` directories intended as internal references. To keep shared reference files referenceable (via `@` or path includes) without polluting the skill list, place them in `.claude/skill-reference/` instead.

- Skills reference them with `@~/.claude/skill-reference/<file>.md` (for `@`-style includes) or `` `~/.claude/skill-reference/<file>.md` `` (for bare path references)
- The `skill-reference/` directory is not scanned by the skill loader, so files there never appear in the skill list

## Preserve Reference Style During Migrations

**Utility: Medium**

When migrating file paths (e.g., relocating shared references), preserve each skill's original reference style rather than normalizing all references to a single style:

- If a skill used `@_shared/file.md` (auto-include directive), update to `@~/.claude/skill-reference/file.md`
- If a skill used `` `~/.claude/commands/.../file.md` `` (bare path in backticks), update to `` `~/.claude/skill-reference/file.md` ``

Adding `@` to files that previously used bare paths changes behavior (auto-include vs manual read instruction). Only update the path portion, not the reference mechanism.
