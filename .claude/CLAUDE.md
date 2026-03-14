# Guidelines

@./guidelines/communication.md
@./guidelines/skill-invocation.md
@./guidelines/context-aware-learnings.md
@./guidelines/path-resolution.md

# Bash Tool

Avoid quoted strings in Bash commands (e.g., `echo "---"`, `echo "DONE"`). Quoted characters trigger permission prompts, forcing the user to manually approve. Use unquoted alternatives or separate tool calls instead.

Check `pwd` before assuming you need to change directories. Don't `cd` or `git -C` into CWD — permission patterns match `git status`, not `cd /path && git status` or `git -C /path status`, so either forces manual approval. Only use `cd`/`git -C` when targeting a different directory.

# Read Tool

Prefer offset + limit over full re-reads. After reading a file once, note line numbers for sections you'll need later. Don't re-read to verify an Edit — trust the success message or use a 5-line targeted read. Avoid reading a file in full right before a Write when you already have the content in context.

Edit requires a recent Read of the target file — having the content in context from a prior skill invocation or earlier conversation turn is not enough. When batching edits across multiple files, issue a quick Read (offset + limit) on each file immediately before its Edit call.

# Path Resolution

| Context | `~/.claude/...` | Relative paths |
|---------|-----------------|----------------|
| **Permission patterns** (settings.json) | ✅ Required | ❌ Won't match |
| **Read** (file_path) | ✅ | ✅ CWD-relative |
| **`@` references** (CLAUDE.md/SKILL.md) | ✅ | ✅ file-relative |

`@` references in CLAUDE.md files resolve relative to the file's directory, not the project root. See `path-resolution.md` guideline for details.

# Sync

sync-source: ~/WORKSPACE/mahoy-claude-stuff
