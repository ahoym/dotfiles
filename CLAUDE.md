# This Repo

This repo (dotfiles) stores Claude Code config under `claude/` (not `.claude/`). Individual items are symlinked into `~/.claude/` via `setup-claude.sh`. The directory is named `claude/` to avoid Claude Code's built-in `.claude/` protection, which triggers permission prompts regardless of permission patterns.

## Tool Path Behavior

| Tool | `~/.claude/...` | CWD-relative (`claude/...`) | Absolute (`/Users/.../dotfiles/...`) |
|------|-----------------|------------------------------|--------------------------------------|
| **Glob/Grep** | ❌ Can't expand `~` or traverse symlinks | ✅ Use this | ✅ Works |
| **Read** | ✅ Works | ✅ Works | ✅ Works |
| **Edit/Write** | ✅ Works, matches tilde or CWD-relative permission patterns | ✅ Works | ✅ Works |

For Glob/Grep use `claude/` CWD-relative paths. For Edit/Write either `~/.claude/` or `claude/` paths work.

## PR Hygiene

Before creating a PR in this repo, check for unrelated uncommitted changes (learnings, skills, guidelines from other sessions). If present, offer to commit them separately or stash them so the PR only contains the intended work.

