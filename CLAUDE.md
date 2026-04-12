# This Repo

This repo (dotfiles) stores Claude Code config under `claude/` (not `.claude/`). Individual items are symlinked into `~/.claude/` via `setup-claude.sh`. The directory is named `claude/` to avoid Claude Code's built-in `.claude/` protection, which triggers permission prompts regardless of permission patterns.

## Tool Path Behavior

| Tool | `~/.claude/...` | CWD-relative (`claude/...`) | Absolute (`/Users/.../dotfiles/...`) |
|------|-----------------|------------------------------|--------------------------------------|
| **Glob/Grep** | ❌ Can't expand `~` or traverse symlinks | ✅ Use this | ✅ Works |
| **Read** | ✅ Works | ✅ Works | ✅ Works |
| **Edit/Write** | ✅ Works, matches tilde or CWD-relative permission patterns | ✅ Works | ✅ Works |

For Glob/Grep use `claude/` CWD-relative paths. For Edit/Write either `~/.claude/` or `claude/` paths work.

## Bash Script Invocation

When invoking generated scripts via `bash`, use the **CWD-relative path** that matches the permission pattern, not an absolute path. Permission patterns are literal-string-matched: `Bash(bash tmp/claude-artifacts/**)` matches `bash tmp/claude-artifacts/.../let-it-rip.sh` but **not** `bash /Users/.../dotfiles/tmp/claude-artifacts/.../let-it-rip.sh`. Absolute paths bypass the pattern and trigger an approval prompt.

## Worktree Path Warning

When running in a git worktree (e.g., via `isolation: "worktree"` agents), **`~/.claude/` and main repo absolute paths bypass worktree isolation**. The `~/.claude/` symlink always points to the main repo's `claude/` directory — it doesn't know about worktrees. Edits using those paths land in the main repo, not the worktree copy.

**In worktrees, always use CWD-relative paths** (`claude/...`) for Edit/Write. CWD-relative paths resolve correctly because the worktree's CWD is the worktree root.

## PR Hygiene

Before creating a PR in this repo, check for unrelated uncommitted changes (learnings, skills, guidelines from other sessions). If present, offer to commit them separately or stash them so the PR only contains the intended work.

