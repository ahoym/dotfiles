# This Repo

This repo (dotfiles) is symlinked to `~/.claude` — the user's Claude Code settings directory. Subdirectories (`commands/`, `guidelines/`, `learnings/`, `lab/`) are directory-level symlinks; `CLAUDE.md` and `settings.json` are individually symlinked.

## Tool Path Behavior

| Tool | `~/.claude/...` | CWD-relative (`.claude/...`) | Absolute (`/Users/.../dotfiles/...`) |
|------|-----------------|------------------------------|--------------------------------------|
| **Glob/Grep** | ❌ Can't expand `~` or traverse symlinks | ✅ Use this | ✅ Works |
| **Read** | ✅ Works | ✅ Works | ✅ Works |
| **Edit/Write** | ✅ Works, matches tilde permission patterns | ⚠️ May trigger permission prompts | ⚠️ May trigger permission prompts |

Since `~/.claude` is a symlink to this repo, prefer `~/.claude/` paths for Edit/Write (matches permission patterns) and `.claude/` CWD-relative paths for Glob/Grep (can't traverse symlinks).

