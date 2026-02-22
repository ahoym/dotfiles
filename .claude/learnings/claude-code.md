# Claude Code

## Task Tool: `isolation: "worktree"` Limitations

The `isolation: "worktree"` parameter on the Task tool creates a git worktree from HEAD of the current branch with an auto-generated branch name (e.g., `worktree-agent-a41c89bc`). There is no way to:

- Specify a base ref (e.g., branch from another agent's branch instead of HEAD)
- Control the branch name (e.g., `feat/plan-slug/agent-name`)

**Implication for parallel plans:** DAG-based workflows where dependent agents need worktrees based on a predecessor's branch require manual `git worktree add <path> -b <branch-name> <base-ref>`. This is why `parallel-plan:execute` uses manual worktree commands in Step 5 rather than `isolation: "worktree"`.

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

## Bash Permission Prefix Matching: `cd &&` Breaks Git Patterns

Bash permission patterns match on the **command prefix**. A compound command like `cd /tmp/worktree && git add .` starts with `cd`, not `git`, so `Bash(git add:*)` won't match — causing a silent failure in background agents or a permission prompt for the coordinator.

**Fix:** Use `git -C <dir>` instead of `cd <dir> && git` for all operations in alternate directories (worktrees, clones, etc.). This keeps `git` as the command prefix and matches existing `Bash(git -C:*)` or `Bash(git:*)` patterns.

```bash
# BAD — starts with "cd", won't match git permission patterns
cd /tmp/worktree-123 && git add . && git commit -m "msg"

# GOOD — starts with "git", matches Bash(git -C:*) or Bash(git:*)
git -C /tmp/worktree-123 add .
git -C /tmp/worktree-123 commit -m "msg"
```

**Discovered from:** parallel-plan:execute session where worktree git operations triggered repeated permission prompts because commands were prefixed with `cd`.

## Use TaskOutput, Not Bash, to Check Background Agent Progress

When monitoring background agents launched via `Task` with `run_in_background: true`, always use the `TaskOutput` tool — never fall back to ad-hoc Bash commands (like `tail`, `grep`, or `cat` on agent output files under `/private/tmp/`).

**Why:**
- `TaskOutput` with `block: false` gives a non-blocking status check — no Bash permissions needed
- `TaskOutput` with `block: true` and a timeout waits for completion cleanly
- Ad-hoc Bash commands on output files require Bash permission patterns that aren't typically pre-configured, causing repeated permission prompts

**Discovered from:** parallel-plan:execute session where checking agent progress via Bash scripts triggered permission prompts that interrupted the user.

## Glob/Grep Tools Don't Resolve `~` in Path Parameters

The Glob and Grep tools do not expand `~` to the home directory in the `path` parameter. Patterns like `Glob(pattern: "learnings/**/*.md", path: "~/.claude")` return "No files found" even when matching files exist.

**Workaround:** Use absolute paths (`/Users/<user>/.claude`) in the `path` parameter, or use Bash `ls` to discover file listings and then Read with absolute paths.

**Note:** The `~` syntax works in *permission rules* (e.g., `Read(~/.claude/learnings/**)`), but not in tool invocation parameters. Don't confuse the two — permission rules use gitignore-style path matching, while tool parameters need real filesystem paths.
