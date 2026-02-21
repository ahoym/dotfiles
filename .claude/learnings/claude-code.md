# Claude Code

## Task Tool: `isolation: "worktree"` Limitations

The `isolation: "worktree"` parameter on the Task tool creates a git worktree from HEAD of the current branch with an auto-generated branch name (e.g., `worktree-agent-a41c89bc`). There is no way to:

- Specify a base ref (e.g., branch from another agent's branch instead of HEAD)
- Control the branch name (e.g., `feat/plan-slug/agent-name`)

**Implication for parallel plans:** DAG-based workflows where dependent agents need worktrees based on a predecessor's branch require manual `git worktree add <path> -b <branch-name> <base-ref>`. This is why `execute-parallel-plan` uses manual worktree commands in Step 5 rather than `isolation: "worktree"`.

## Skill Discovery: Sibling vs Subdirectory `.md` Files

`.md` files **next to** a `SKILL.md` (siblings) are treated as reference data — they are not discovered as separate skills. Only `.md` files in **subdirectories** of a skill folder get discovered as sub-skills (e.g., `set-persona:personas:java-backend`).

**Use this to keep data files co-located with a skill** without polluting the skill list. For example, persona definitions or template files can live as siblings of `SKILL.md` and be read by the skill at runtime without appearing as individual invocable skills.

Verified empirically: moving `personas/*.md` up to sit next to `SKILL.md` removed them from the skill list while keeping the main `set-persona` skill functional.

## Permission Rules: `Read()` Covers Glob and Grep

The permission system's tool names don't match the display names shown in prompts. When Claude Code asks permission for a Glob or Grep operation, the prompt shows `Search(pattern: "**/*.md", path: "~/.claude/learnings")` — but the correct allow rule uses **`Read`**, not `Search` or `Glob`.

From the [docs](https://code.claude.com/docs/en/permissions): *"Claude makes a best-effort attempt to apply `Read` rules to all built-in tools that read files like Grep and Glob."*

**Path syntax** follows gitignore conventions with four types:
- `Read(~/path)` — relative to home directory
- `Read(//absolute/path)` — absolute filesystem path (note the double slash)
- `Read(/relative/path)` — relative to settings file location
- `Read(path)` — relative to current working directory

**Example** — auto-allow Glob/Grep under `~/.claude/`:
```json
"permissions": {
  "allow": [
    "Read(~/.claude/learnings/**)",
    "Read(~/.claude/guidelines/**)",
    "Read(~/.claude/commands/**)"
  ]
}
```

**What didn't work** (tried in sequence before finding the correct format):
- `Glob(path:~/.claude/learnings)` — wrong tool name
- `Glob(path:/Users/user/.claude/learnings)` — wrong tool name, absolute path
- `Search(path:~/.claude/learnings)` — matched display name but still wrong tool name

## Background Bash Agents Lack Permissions for File Operations

When using `Task` with `subagent_type: "Bash"` and `run_in_background: true`, the agent typically cannot execute file-writing commands (cp, mkdir, heredoc redirects) because Bash permissions aren't pre-configured for those patterns.

**Workaround:** For file copy/create operations, do them directly in the main thread using Bash, Write, or Edit tools instead of delegating to background Bash agents. Background agents are better suited for long-running processes where the specific Bash commands have pre-configured allow patterns.
