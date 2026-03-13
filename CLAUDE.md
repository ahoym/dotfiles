# Guidelines

@.claude/guidelines/communication.md
@.claude/guidelines/skill-invocation.md
@.claude/guidelines/context-aware-learnings.md

# Bash Tool

Avoid quoted strings in Bash commands (e.g., `echo "---"`, `echo "DONE"`). Quoted characters trigger permission prompts, forcing the user to manually approve. Use unquoted alternatives or separate tool calls instead.

Check `pwd` before assuming you need to change directories. Don't `cd` or `git -C` into CWD — permission patterns match `git status`, not `cd /path && git status` or `git -C /path status`, so either forces manual approval. Only use `cd`/`git -C` when targeting a different directory.

# Read Tool

Prefer offset + limit over full re-reads. After reading a file once, note line numbers for sections you'll need later. Don't re-read to verify an Edit — trust the success message or use a 5-line targeted read. Avoid reading a file in full right before a Write when you already have the content in context.

# Glob and Grep Tools

The `path` parameter does not resolve `~`. Always use the actual filesystem path (e.g. from CWD or absolute). Since this repo is symlinked to `~/.claude/`, use `.claude/` relative paths (e.g., `.claude/learnings/foo.md`) for Read/Glob — not `~/.claude/learnings/foo.md`. Note: permission rules DO support `~` — these are different contexts.

# Repo Context

This repo is symlinked to `~/.claude` (the user's Claude settings directory). When referencing paths in this repo, always use `~/.claude/...` rather than absolute paths (e.g. `/home/user/.claude/...`). This is required for permission patterns in settings files to match correctly.

# Sync

sync-source: ~/WORKSPACE/mahoy-claude-stuff

