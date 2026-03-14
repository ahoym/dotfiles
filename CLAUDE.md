# This Repo

This repo (dotfiles) is symlinked to `~/.claude` — the user's Claude Code settings directory. Subdirectories (`commands/`, `guidelines/`, `learnings/`, `lab/`) are directory-level symlinks; `CLAUDE.md` and `settings.json` are individually symlinked.

## Glob and Grep

Glob/Grep `path` parameters don't expand `~` and can't traverse symlinks. Since `~/.claude` is a symlink, use `.claude/` (CWD-relative) paths for Glob/Grep in this repo — not `~/.claude/...` or absolute paths through the symlink.

