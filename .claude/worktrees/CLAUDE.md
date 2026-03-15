# Worktree Constraints

Operations targeting the project root repo from a worktree session hit permission friction:

1. **CWD is pinned** — Claude Code resets CWD to the worktree after every Bash call. `cd` to the main repo doesn't persist.
2. **Compound commands don't match patterns** — `cd /path && git add` doesn't match `Bash(git add:*)` permissions, so each compound command triggers a prompt.
3. **No friction-free path exists** — both `git -C` and `cd &&` chains have the same problem. There is no workaround within the current permission system.

When an operation needs to target the main repo, surface this constraint before attempting it. Let your partner decide: run the commands themselves, approve a compound command, or defer until they're on main.
