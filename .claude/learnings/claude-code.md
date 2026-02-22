# Claude Code

## Task Tool: `isolation: "worktree"` Limitations

The `isolation: "worktree"` parameter on the Task tool creates a git worktree from the **HEAD commit** of the current branch with an auto-generated branch name (e.g., `worktree-agent-a41c89bc`). There is no way to:

- Specify a base ref (e.g., branch from another agent's branch instead of HEAD)
- Control the branch name (e.g., `feat/plan-slug/agent-name`)

**Critical distinction:** The worktree is created from the HEAD **commit**, not the working directory state. Unstaged/uncommitted files in the working tree are NOT included in the isolated worktree. If Agent A writes files to the shared working tree and Agent B launches with `isolation: "worktree"`, B's worktree won't have A's files unless A's work was committed first.

**Workaround for dependency files:** Agents can cherry-pick from a dependency's pushed branch as their first step: `git cherry-pick main..<dep-branch>`. This brings the dependency's commits into the isolated worktree. The agent can then rename its branch (`git branch -m <desired-name>`), commit its own work, and push.

## No Mid-Flight Messaging to Background Agents

There is no mechanism to send messages, corrections, or updates to a running background agent. The only interaction points are:

- **Before launch:** The prompt (all context must be provided upfront)
- **During execution:** `TaskOutput` is read-only (status check only)
- **After completion:** `resume` parameter on Task tool continues from where the agent left off

**Implication for discovery propagation:** In fan-out DAGs where all agents launch simultaneously, discoveries from early completers cannot be injected into still-running agents. Treat discoveries as post-execution documentation, not runtime corrections. The only way to act on a discovery mid-execution is to wait for the affected agent to complete, then resume it with corrective instructions.

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

## Bash Permission Prefix Matching Gotchas

Bash permission patterns match on the **literal command prefix**. Three common ways this breaks:

**1. `cd &&` prefix:** `cd /tmp/worktree && git add .` starts with `cd`, not `git`, so `Bash(git add:*)` won't match. **Fix:** Use `git -C <dir>` instead of `cd <dir> && git`.

```bash
# BAD — starts with "cd", won't match git permission patterns
cd /tmp/worktree-123 && git add . && git commit -m "msg"

# GOOD — starts with "git", matches Bash(git -C:*) or Bash(git:*)
git -C /tmp/worktree-123 add .
git -C /tmp/worktree-123 commit -m "msg"
```

**2. `git -C` prefix:** `git -C ../worktree push origin branch` does NOT match `Bash(git push:*)` because `-C ../worktree` comes before `push`. **Workaround:** From the main repo, `git push origin <branch>` pushes commits made in any worktree (shared object database).

**3. Tilde expansion:** If a background agent expands `~` to `/Users/foo/.claude/...`, the command won't match `Bash(bash ~/.claude/commands/...:*)`. Always pass `~` literally — the shell expands it at runtime, but the permission check happens on the literal text.

## Scoping Bash Permissions: Helper Scripts

When a skill needs Bash commands that don't match existing patterns, wrap them in a helper script and pre-approve just that script:

```bash
#!/usr/bin/env bash
# worktree-commit.sh
WORKTREE_PATH="$1"
COMMIT_MSG="$2"
git -C "$WORKTREE_PATH" add -A
git -C "$WORKTREE_PATH" commit -m "$COMMIT_MSG"
```

Permission entry: `Bash(bash ~/.claude/commands/compound-learnings/worktree-commit.sh:*)` — grants permission with any arguments, without exposing broad `git -C` permissions.

**Anti-pattern: `Bash(bash:*)`** — this matches ANY command starting with `bash`, including `bash -c '<anything>'`. Agents can bypass every other permission by wrapping denied commands in `bash -c`. Background agents self-discover this workaround when commands are auto-denied. Always scope with enough path: `Bash(bash scripts/:*)` or `Bash(bash ~/.claude/commands/<skill>/lifecycle.sh:*)`.

## Use TaskOutput, Not Bash, to Check Background Agent Progress

When monitoring background agents launched via `Task` with `run_in_background: true`, always use the `TaskOutput` tool — never fall back to ad-hoc Bash commands (like `tail`, `grep`, or `cat` on agent output files under `/private/tmp/`).

**Why:**
- `TaskOutput` with `block: false` gives a non-blocking status check — no Bash permissions needed
- `TaskOutput` with `block: true` and a timeout waits for completion cleanly
- Ad-hoc Bash commands on output files require Bash permission patterns that aren't typically pre-configured, causing repeated permission prompts

## Glob/Grep Tools Don't Resolve `~` in Path Parameters

The Glob and Grep tools do not expand `~` to the home directory in the `path` parameter. Patterns like `Glob(pattern: "learnings/**/*.md", path: "~/.claude")` return "No files found" even when matching files exist.

**Workaround:** Use absolute paths (`/Users/<user>/.claude`) in the `path` parameter, or use Bash `ls` to discover file listings and then Read with absolute paths.

**Note:** The `~` syntax works in *permission rules* (e.g., `Read(~/.claude/learnings/**)`), but not in tool invocation parameters. Don't confuse the two — permission rules use gitignore-style path matching, while tool parameters need real filesystem paths.

## AskUserQuestion Multi-Select Limit

`AskUserQuestion` with `multiSelect: true` is limited to **4 options** maximum. When presenting more than 4 items for selection, group them by action type or category to fit within the limit.

## `git -C` Is Unnecessary When CWD Is the Repo Root

When the current working directory is already the repository root (which it almost always is in a Claude Code session), plain `git` commands work directly. The "avoid cd" instruction is about not changing the shell's CWD (which resets between bash calls anyway) — it is not about qualifying every command with an absolute path. Only use `git -C` when operating on a **different repository** than CWD (e.g., a worktree in another location).
