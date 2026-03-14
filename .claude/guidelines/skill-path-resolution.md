# Skill Path Resolution

## Resolve relative paths against the skill's base directory

When a skill references a file using a relative path (e.g., `../../learnings/foo.md` or `sibling.md`), resolve it against the skill's base directory — shown in the "Base directory for this skill" header injected by the CLI — before passing to the Read tool.

The Read tool only natively resolves CWD-relative and tilde (`~`) paths. Relative traversal (`../../`) and bare filenames fail with "File does not exist." But the base directory header provides enough context to expand any relative path to an absolute one.

**Steps:**
1. Note the base directory from the skill header (e.g., `/Users/<user>/.claude/commands/my-skill`)
2. Resolve the relative path against it (e.g., `../../learnings/foo.md` → `/Users/<user>/.claude/learnings/foo.md`)
3. Pass the absolute path to Read

This applies to lazy-loaded references (plain paths without `@`). For eager loading, use `@` with CWD-relative or tilde paths instead — those are resolved by the CLI deterministically at load time.
