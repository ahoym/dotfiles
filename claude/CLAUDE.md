# Guidelines

@./guidelines/communication.md
@./guidelines/path-resolution.md

When the user writes `/skill-name`, always invoke it via the Skill tool — never perform the skill's actions manually inline. This applies even when combined with other instructions. When the Skill tool rejects with `disable-model-invocation`, tell the user it can only be run as a slash command; do NOT read the SKILL.md and follow its steps manually.

## Procedural References (load when needed)

| File | When to read |
|------|-------------|
| guidelines/skill-invocation.md | When executing inside a skill (permission to chain skills, loading reference files) |

# Bash Tool

Avoid quoted strings in Bash commands (e.g., `echo "---"`, `echo "DONE"`). Quoted characters trigger permission prompts, forcing the user to manually approve. Use unquoted alternatives or separate tool calls instead.

Check `pwd` before assuming you need to change directories. Don't `cd` or `git -C` into CWD — permission patterns match `git status`, not `cd /path && git status` or `git -C /path status`, so either forces manual approval. When targeting a different directory, prefer a single `cd` over repeated `git -C` — `cd` prompts once, `-C` prompts on every command.

# Read Tool

Prefer offset + limit over full re-reads. After reading a file once, note line numbers for sections you'll need later. Don't re-read to verify an Edit — trust the success message or use a 5-line targeted read. Avoid reading a file in full right before a Write when you already have the content in context. Every unnecessary Read costs ~200-500 tokens; across a multi-file refactor with multiple passes, that compounds to 2-5k+ wasted tokens.

Edit requires a recent Read of the target file — having the content in context from a prior skill invocation or earlier conversation turn is not enough. When batching edits across multiple files, issue a quick Read (offset + limit) on each file immediately before its Edit call.

# Path Resolution

| Context | `~/.claude/...` | Relative paths |
|---------|-----------------|----------------|
| **Permission patterns** (settings.json) | ✅ Required | ❌ Won't match |
| **Read** (file_path) | ✅ | ✅ CWD-relative |
| **`@` references** (CLAUDE.md/SKILL.md) | ✅ | ✅ file-relative |