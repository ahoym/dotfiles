# Guidelines

@.claude/guidelines/communication.md

# Bash Tool

Avoid quoted strings in Bash commands (e.g., `echo "---"`, `echo "DONE"`). Quoted characters trigger permission prompts, forcing the user to manually approve. Use unquoted alternatives or separate tool calls instead.

Don't use `git -C <path>` when already in the working directory. Permission patterns match `git status`, not `git -C /path status`. Using `-C` forces manual approval for commands that would otherwise be auto-permitted.

# Repo Context

This repo is symlinked to `~/.claude` (the user's Claude settings directory). When referencing paths in this repo, always use `~/.claude/...` rather than absolute paths (e.g. `/home/user/.claude/...`). This is required for permission patterns in settings files to match correctly.

# Sync

sync-source: ~/WORKSPACE/mahoy-claude-stuff

