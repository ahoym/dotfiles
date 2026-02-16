# Claude Code Internals

## Command Resolution Paths

Claude Code skills/commands can exist at two levels:
- **User-level**: ~/.claude/commands/<skill-name>/ — available across all projects
- **Project-level**: .claude/commands/<skill-name>/ — scoped to a specific repo

When both exist, both appear in the skill list.
