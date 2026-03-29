# Restructure: `.claude/` → `claude/` with Symlinks

## Problem

Claude Code has a project-scoped guard that prompts for all direct Write/Edit calls to paths containing `.claude/` when CWD is inside that directory. This affects ad-hoc edits during dotfiles sessions. Skills with `allowed-tools` bypass this guard, so the impact is narrow — but a restructuring would eliminate it entirely and simplify permission patterns.

## Context

- `~/.claude` is a symlink → `~/WORKSPACE/dotfiles`
- Subdirectories (`commands/`, `guidelines/`, `learnings/`) are directory-level symlinks → `dotfiles/.claude/<dir>`
- `CLAUDE.md` and `settings.json` are individually symlinked
- The guard triggers on the `.claude/` substring in the path, not the symlink itself
- Paths without `.claude/` (e.g., `dotfiles/claude/learnings/...`) auto-allow

## Proposed Structure

```
dotfiles/
  claude/                          ← actual files (no dot)
    commands/
    guidelines/
    learnings/
    learnings-private/
    skill-references/
    skills/
    CLAUDE.md
    settings.json
  .claude/                         ← thin symlink layer
    commands → ../claude/commands
    guidelines → ../claude/guidelines
    learnings → ../claude/learnings
    learnings-private → ../claude/learnings-private
    skill-references → ../claude/skill-references
    skills → ../claude/skills
    CLAUDE.md → ../claude/CLAUDE.md
    settings.json → ../claude/settings.json
```

`~/.claude` still symlinks to `dotfiles/` as before. Claude Code resolves `~/.claude/learnings/foo.md` → `dotfiles/.claude/learnings` → `dotfiles/claude/learnings/foo.md`.

## Migration Steps

### 1. Create `claude/` and move content

```bash
mkdir -p claude
git mv .claude/commands claude/commands
git mv .claude/guidelines claude/guidelines
git mv .claude/learnings claude/learnings
git mv .claude/learnings-private claude/learnings-private
git mv .claude/skill-references claude/skill-references
git mv .claude/skills claude/skills
git mv .claude/CLAUDE.md claude/CLAUDE.md
git mv .claude/settings.json claude/settings.json
```

### 2. Create `.claude/` symlinks

```bash
mkdir -p .claude
ln -s ../claude/commands .claude/commands
ln -s ../claude/guidelines .claude/guidelines
ln -s ../claude/learnings .claude/learnings
ln -s ../claude/learnings-private .claude/learnings-private
ln -s ../claude/skill-references .claude/skill-references
ln -s ../claude/skills .claude/skills
ln -s ../claude/CLAUDE.md .claude/CLAUDE.md
ln -s ../claude/settings.json .claude/settings.json
```

### 3. Update setup script

The install script creates symlinks from `~/.claude/` → `dotfiles/.claude/`. The chain becomes: `~/.claude/<dir>` → `dotfiles/.claude/<dir>` → `dotfiles/claude/<dir>`. Verify the double-symlink resolves correctly. If not, update the install script to point `~/.claude/<dir>` directly at `dotfiles/claude/<dir>`.

### 4. Update path references

- **CLAUDE.md**: Update any `@.claude/...` references to `@claude/...` or verify `.claude/` refs still resolve through symlinks
- **Permission patterns in `settings.json`**: CWD-relative patterns like `Edit(.claude/**)` may need `Edit(claude/**)` companions
- **Glob/Grep paths**: Already need CWD-relative; update from `.claude/` to `claude/`
- **Skills**: Any skill hardcoding `.claude/` write paths can optionally switch to `claude/` for consistency, though the `allowed-tools` bypass means this isn't required

### 5. Verify

| Operation | Path | Expected |
|-----------|------|----------|
| Read | `~/.claude/learnings/foo.md` | Resolves through double symlink |
| Write | `dotfiles/claude/learnings/foo.md` | Auto-allowed (no `.claude/` in path) |
| Edit | `dotfiles/claude/learnings/foo.md` | Auto-allowed |
| Glob | `claude/learnings/*.md` | Finds files (real directory) |
| Glob | `.claude/learnings/*.md` | May not traverse symlinks — test |
| Skill Write | `~/.claude/learnings/foo.md` | Auto-allowed (via `allowed-tools`) |

## Risks

- **Double symlink resolution**: `~/.claude/learnings` → `dotfiles/.claude/learnings` → `dotfiles/claude/learnings`. Most tools handle this but worth testing edge cases.
- **Git tracking**: Git tracks content, not symlinks-to-symlinks. Verify `git status` shows changes in `claude/` not `.claude/`.
- **`@` references**: CLI resolves `@` at load time. Need to verify `@.claude/guidelines/foo.md` still works through the symlink, or update to `@claude/guidelines/foo.md`.
- **Other repos**: Projects using `@~/.claude/learnings/foo.md` should be unaffected — the `~/.claude` entry point is unchanged.

## Decision Factors

**Do it if:** Ad-hoc direct edits in dotfiles sessions are frequent enough that the per-session prompt tax is annoying, or you want cleaner Glob/Grep paths.

**Skip it if:** Most `.claude/` writes happen through skills (which already bypass the guard), and the occasional direct-edit prompt is tolerable.
