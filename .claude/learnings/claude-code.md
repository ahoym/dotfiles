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

Glob/Grep operations show as `Search(...)` in prompts but the correct allow rule uses **`Read`**, not `Search` or `Glob`.

**Path syntax** (gitignore conventions): `Read(~/path)` (home-relative), `Read(//absolute/path)` (absolute, note double slash), `Read(/relative/path)` (settings-file-relative), `Read(path)` (CWD-relative).

**Example** — auto-allow Glob/Grep under `~/.claude/`:
```json
"permissions": {
  "allow": [
    "Read(~/.claude/learnings/**)",
    "Read(~/.claude/commands/**)"
  ]
}
```

## Background Bash Agents Lack Permissions for File Operations

When using `Task` with `subagent_type: "Bash"` and `run_in_background: true`, the agent typically cannot execute file-writing commands (cp, mkdir, heredoc redirects) because Bash permissions aren't pre-configured for those patterns.

**Workaround:** For file copy/create operations, do them directly in the main thread using Bash, Write, or Edit tools instead of delegating to background Bash agents. Background agents are better suited for long-running processes where the specific Bash commands have pre-configured allow patterns.

## Bash Permission Prefix Matching Gotchas

Bash permission patterns match on the **literal command prefix**. Three common breaks:

1. **`cd &&` prefix:** `cd /tmp/worktree && git add .` starts with `cd`, not `git` — won't match `Bash(git add:*)`. Fix: use `git -C <dir>` instead.
2. **`git -C` prefix:** `git -C ../worktree push` doesn't match `Bash(git push:*)` because `-C` comes before `push`. Workaround: push from main repo — `git push origin <branch>` works for worktree commits (shared object database).
3. **Tilde expansion:** Background agents may expand `~` to `/Users/...`, breaking `Bash(bash ~/.claude/...:*)`. Always pass `~` literally — the shell expands at runtime, permission checks the literal text.

## Scoping Bash Permissions: Helper Scripts

When a skill needs Bash commands that don't match existing patterns, wrap them in a helper script and pre-approve just that script:

```bash
#!/usr/bin/env bash
# worktree-commit.sh — wraps git operations for permission scoping
git -C "$1" add -A && git -C "$1" commit -m "$2"
```

Permission: `Bash(bash ~/.claude/commands/<skill>/worktree-commit.sh:*)` — any arguments, without exposing broad `git -C` permissions.

**Anti-pattern: `Bash(bash:*)`** matches ANY `bash` command including `bash -c '<anything>'` — agents discover this bypass when commands are auto-denied. Always scope with path: `Bash(bash ~/.claude/commands/<skill>/lifecycle.sh:*)`.

## Use TaskOutput, Not Bash, to Check Background Agent Progress

When monitoring background agents launched via `Task` with `run_in_background: true`, always use the `TaskOutput` tool — never fall back to ad-hoc Bash commands (like `tail`, `grep`, or `cat` on agent output files under `/private/tmp/`).

**Why:**
- `TaskOutput` with `block: false` gives a non-blocking status check — no Bash permissions needed
- `TaskOutput` with `block: true` and a timeout waits for completion cleanly
- Ad-hoc Bash commands on output files require Bash permission patterns that aren't typically pre-configured, causing repeated permission prompts

## Context Continuation Loses File Contents

When a session is continued from a compacted conversation (context overflow), **all file contents read in the prior session are lost**. The conversation summary preserves metadata (file paths, line numbers, key findings) but not the actual file text. Budget time for re-reading source files after continuation.

**Mitigation:** Capture critical landmarks explicitly in conversation (e.g., "txFailureResponse is at line 200-209 in lib/api.ts") so continuation reduces re-reading to verification rather than discovery.

## WebFetch Cannot Parse PDF Files

`WebFetch` returns raw binary for PDFs — it can't extract text. The `Read` tool supports PDFs natively but requires `poppler-utils` (`brew install poppler`). If poppler isn't available, find text conversions via web search (gists, blog summaries, markdown conversions) as a fallback.

## `~/.claude` Symlink Structure

`~/.claude` is a real directory on disk. Key subdirectories (`commands/`, `guidelines/`, `learnings/`, `lab/`) are **directory-level symlinks** to the dotfiles repo (e.g., `commands -> /Users/<user>/WORKSPACE/dotfiles/.claude/commands`). Edits to files under these paths land in the repo automatically — no separate copy step needed.

Other entries (e.g., `CLAUDE.md`, `settings.json`) are individually symlinked. Non-dotfiles content (`history.jsonl`, `debug/`, `cache/`) lives directly in `~/.claude/` as real files.

## PreToolUse Hooks Survive `--dangerously-skip-permissions`

`PreToolUse` hooks fire regardless of permission mode — they're the one enforcement layer that works even with `--dangerously-skip-permissions`. Use exit 2 + stderr message to block (message is shown to Claude as feedback). Exit 0 to allow. This makes hooks the right layer for security guards on unattended loops.

Note: `PermissionRequest` hooks do NOT fire in non-interactive mode (`--print`). Only `PreToolUse`/`PostToolUse` fire.

## Hook Performance: Process Spawn Overhead

Each hook spawns a process (~1-2ms on macOS) on every matching tool call. For high-frequency tools (Bash, Write/Edit), permanent hooks cause aggregate latency even with early-exit checks. Scope hooks to contexts where they're needed — e.g., inject into worktree-level `settings.local.json` instead of user-level settings, so hooks only exist during the scoped operation.

## Multiple PreToolUse Hooks Act as AND Gates

When multiple `PreToolUse` hooks match the same tool, **all** must allow for the call to proceed. If Hook A allows and Hook B denies, the call is blocked. This means concurrent write-scope guards for different directories are fundamentally incompatible on shared settings — each guard blocks the other's allowed directory. Solve with isolated settings (worktrees) rather than shared settings with multiple guards.


