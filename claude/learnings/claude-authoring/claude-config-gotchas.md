Condensed tripwires for authoring Claude Code config: skills, personas, learnings, guidelines, CLAUDE.md, memory.
- **Keywords:** Glob symlink, tilde in path, persona @ references, AskUserQuestion 4-option, skill discovery cache, allowed-tools frontmatter, gotchas file separation
- **Related:** ~/.claude/learnings/claude-code/platform-tools-and-automation.md, ~/.claude/learnings/claude-authoring/skill-design.md, ~/.claude/learnings/claude-authoring/personas.md

---

## Tool surface

- `Glob` doesn't resolve paths through `~/.claude/` symlinks — verify existence with `Read` or fall back to `ls` (see `platform-tools-and-automation.md` § "Glob Limitations with Symlinks")
- `~` doesn't expand in `Glob`/`Grep` `path` parameter — use actual filesystem paths or CWD-relative
- `@` references in persona files don't resolve — personas are data files read at runtime via Read tool, not SKILL.md/CLAUDE.md processed by the CLI (see `personas.md` § "Proactive Cross-Refs Require Agent Behavior")
- `AskUserQuestion` enforces a 4-option maximum — skills offering choices must respect this (see `skill-design.md` § "AskUserQuestion Has a 4-Option Maximum")

## Skill/persona lifecycle

- Skill discovery cache populates at session start — mid-session additions aren't found until restart (see `skill-lifecycle.md`)
- `allowed-tools` frontmatter is functional — restricts tool access during skill execution (confirmed 2026-03-16)

## File placement

- `*-gotchas.md` files stay separate from parent domain files — never merge `xrpl-gotchas.md` into `xrpl-patterns.md`. Small dedicated files keep proactive loading cheap (see `personas.md` § "*-gotchas.md Companion File Convention")

## Cross-Refs

- `~/.claude/learnings/claude-code/platform-tools-and-automation.md` — Glob/Read/Write tool behavior, symlink resolution
- `~/.claude/learnings/claude-authoring/skill-design.md` — AskUserQuestion limits, skill composition
- `~/.claude/learnings/claude-authoring/personas.md` — gotchas file convention, persona authoring patterns
- `~/.claude/learnings/claude-authoring/skill-lifecycle.md` — skill discovery cache, mid-session additions
