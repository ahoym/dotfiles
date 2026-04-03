# dotfiles

macOS dotfiles and [Claude Code](https://docs.anthropic.com/en/docs/claude-code) configuration.

## Setup

```bash
# Clone
git clone git@github.com:ahoym/dotfiles.git ~/WORKSPACE/dotfiles
cd ~/WORKSPACE/dotfiles

# Bootstrap the system (git, vim, xcode, homebrew, mise)
./main.sh

# Symlink Claude Code config into ~/.claude
./setup-claude.sh
```

`main.sh` is idempotent — safe to re-run. It:
- Creates `~/WORKSPACE` if missing
- Adds an `[include]` to `~/.gitconfig` for the repo's git aliases
- Copies vim config (backs up existing files first)
- Installs Xcode CLI tools, Homebrew, and [mise](https://mise.run)

`setup-claude.sh` symlinks items from `claude/` into `~/.claude/`. Existing files are backed up with a timestamp before linking.

## What's in here

### Shell

| File | Purpose |
|------|---------|
| `.bash_profile` | Sources exports/aliases, sets up Homebrew + mise |
| `.exports` | `PATH_TO_WORKSPACE` and other env vars |
| `.aliases` | Shell shortcuts (`g`=git, `work`=cd to workspace, etc.) |
| `.gitconfig` | Git aliases (`br`, `cm`, `co`, `df`, `pushcurrent`, etc.) |

### Claude Code (`claude/`)

The `claude/` directory is the source of truth for Claude Code configuration. `setup-claude.sh` symlinks it into `~/.claude/` so Claude Code picks it up. The directory is named `claude/` (not `.claude/`) to avoid Claude Code's built-in directory protection.

**Skills** (`claude/commands/`) — custom slash commands for code review, PR workflows, multi-agent orchestration, security audits, refactoring, and more. Git-specific skills live under `commands/git/`.

**Other config**:
- `guidelines/` — behavioral guidelines (communication style, learnings protocol)
- `learnings/` — accumulated knowledge base organized by domain
- `settings.json` / `settings.local.json` — Claude Code tool permissions and hooks
- `skill-references/` — reference docs loaded by skills at runtime

### Other

- `vim_related/` — `.vimrc` and vim config
- `vscode_related/` — VS Code settings and keybindings
- `iTerm2/` — iTerm2 profile
- `scripts/` — batch import/export utilities
