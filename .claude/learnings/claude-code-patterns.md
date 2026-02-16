# Claude Code Patterns

## Bash script as sandbox bypass for ~/.claude/ writes

Background agents (Task tool with `run_in_background: true`) may not be able to use the Write/Edit tools for paths outside the project sandbox (e.g., `~/.claude/`). The workaround is a simple bash script that handles file I/O:

- Create a script (e.g., `file-io.sh`) with `read`, `write`, `append`, and `list` commands that operate relative to a base directory (`$HOME/.claude/`)
- Add a single permission pattern in `settings.local.json`: `Bash(bash ~/.claude/commands/<skill>/file-io.sh:*)`
- Background agents use heredoc-based bash commands to write through the script instead of Write/Edit tools
- Use `~` literally in commands (not expanded absolute paths) so they match the permission pattern
- This replaces more complex approaches like git worktrees when you just need to write files outside the project directory

This pattern is generalizable to any skill that needs background agents to write outside the project sandbox.

## Background agents need file-io.sh in permissions allow list

The `/compound-learnings` skill launches a background Task agent to write learning files via `file-io.sh`. Background agents (subagents) inherit the parent's permission settings but still need explicit allow-list entries. Without `Bash(bash ~/.claude/commands/compound-learnings/file-io.sh:*)` in `~/.claude/settings.local.json`, the background agent will be denied permission to run the file-io script and silently fail. This must be added to the `permissions.allow` array alongside other allowed commands. The key insight is that even though the parent session can run the script, the spawned background agent checks permissions independently and will block on unapproved commands.
