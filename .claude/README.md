# Claude Code Dotfiles

Shared Claude Code configuration: skills, guidelines, learnings, and settings.

## Setup

Clone this repo and run the setup script:

```sh
git clone <repo-url>
cd dotfiles
./setup-claude.sh
```

This symlinks everything in `.claude/` into `~/.claude/`, making it available globally across all projects. Existing files are backed up before being replaced.

## What's included

| Path | Purpose |
|------|---------|
| `commands/` | Custom skills (slash commands) |
| `guidelines/` | Shared guidelines referenced by CLAUDE.md |
| `learnings/` | Accumulated learnings and reference docs |
| `lab/` | Experimental/research projects |
| `settings.local.json` | Permission rules for dotfile skills |
