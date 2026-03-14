# Claude Code

## Task Tool: `isolation: "worktree"` Limitations

The `isolation: "worktree"` parameter on the Task tool creates a git worktree from the **HEAD commit** of the current branch with an auto-generated branch name (e.g., `worktree-agent-a41c89bc`). There is no way to:

- Specify a base ref (e.g., branch from another agent's branch instead of HEAD)
- Control the branch name (e.g., `feat/plan-slug/agent-name`)

**Critical distinction:** The worktree is created from the HEAD **commit**, not the working directory state. Unstaged/uncommitted files in the working tree are NOT included in the isolated worktree. If Agent A writes files to the shared working tree and Agent B launches with `isolation: "worktree"`, B's worktree won't have A's files unless A's work was committed first.

**Workaround for dependency files:** Agents can cherry-pick from a dependency's pushed branch as their first step: `git cherry-pick main..<dep-branch>`. This brings the dependency's commits into the isolated worktree. The agent can then rename its branch (`git branch -m <desired-name>`), commit its own work, and push.

**Implication for parallel plans:** DAG-based workflows where dependent agents need worktrees based on a predecessor's branch require manual `git worktree add <path> -b <branch-name> <base-ref>`. This is why `parallel-plan/execute` uses manual worktree commands in Step 5 rather than `isolation: "worktree"`.

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

## Permissions Are Cached at Session Start

Changes to `settings.json` or `settings.local.json` mid-session are **not picked up** by background agents or the current session. This applies to both project-level and local settings files.

**Impact:** Adding a permission mid-session then launching background agents → agents silently fail with "Permission denied."

**Fix:** Add all required permissions **before** starting the session. If you discover missing permissions mid-execution, add them and restart the session.

## Worktree Isolation Creates Permission Mismatches

Edit/Write permission patterns like `Edit(~/.claude/commands/**)` resolve to absolute paths. Agents in worktrees edit files at `<worktree>/commands/...` — a different path that doesn't match.

**When to skip worktrees:** Agents have disjoint file scopes (no conflict risk) and no build/test isolation needed. Especially mechanical edits (YAML, markdown).

**When worktrees are needed:** Code tasks with `tsc --noEmit` or build steps where parallel agents would see each other's half-written files.

**Skill tool in worktrees:** Skills write to `~/.claude/` paths by convention, which resolves to the main repo — not the worktree. Autonomous agents in worktrees that need compound-style behavior should inline the methodology (Read/Edit/Write directly) rather than invoke the Skill tool. This also avoids: hook restrictions on the Skill tool, AskUserQuestion calls with no user present, and ~120 lines of skill context loaded per invocation.

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

## Always `Read` Before `Write`

The Write tool requires a prior `Read` attempt on the target file — `Glob` doesn't satisfy this prerequisite. For new files: `Read` (gets "file does not exist" error) → `Write`. For existing files: `Read` → `Edit`.

## Subagent Reads Don't Satisfy Main-Thread Edit Prerequisites

When a Task subagent reads a file, that Read does NOT count for the main thread's Edit/Write prerequisite check. The main thread must `Read` the file itself before calling `Edit` — even if a subagent already read and analyzed the file's contents. This commonly surfaces when subagents evaluate skills/files in parallel and the orchestrator then tries to bulk-edit based on their findings.

**Recovery:** After subagent analysis, batch the required `Read` calls for files you need to edit, then proceed with edits.

## Parallel Tool Call Error Cascade

When multiple tool calls are sent in a single batch and one fails, all sibling calls in the same batch fail with `"Sibling tool call errored"` — regardless of whether they would have succeeded independently. The failing call's error is reported normally; the siblings get a generic cascade error.

**Recovery:** Identify which calls actually failed vs which were cascade victims. Retry the valid calls individually or in a new batch (without the failing call).

## `~/.claude` Symlink Structure

`~/.claude` is a real directory on disk. Key subdirectories (`commands/`, `guidelines/`, `learnings/`, `lab/`) are **directory-level symlinks** to the dotfiles repo (e.g., `commands -> /Users/<user>/WORKSPACE/dotfiles/.claude/commands`). Edits to files under these paths land in the repo automatically — no separate copy step needed.

Other entries (e.g., `CLAUDE.md`, `settings.json`) are individually symlinked. Non-dotfiles content (`history.jsonl`, `debug/`, `cache/`) lives directly in `~/.claude/` as real files.

## Glob Can Miss Files — Verify with ls/Bash

Glob tool may silently return empty for files that exist (observed with untracked files in `docs/learnings/`). When making claims about file existence/absence, verify with `ls` or `Bash` before stating files don't exist. Getting this wrong (claiming a directory is empty when it has 5 files) erodes trust quickly.

## Glob Fails Through Symlinked Directories

Glob cannot traverse directory symlinks — even with absolute paths. `~/.claude` is symlinked, so `Glob(pattern: "commands/set-persona/*.md", path: "/Users/<user>/.claude")` returns empty while `ls /Users/<user>/.claude/commands/set-persona/*.md` finds files. Fall back to `Bash` `ls` when searching inside symlinked directory trees like `~/.claude/commands/` or `~/.claude/learnings/`.

## Sanitizing Examples: Preserve Pedagogical Intent

When scrubbing personal details from learning examples, use generic placeholders (`/Users/<user>/`) rather than replacing with the "correct" form (`~/.claude`). If the learning demonstrates that absolute paths fail, replacing the example with a tilde path removes the demonstration of the failure. Match the placeholder to the role the value plays in the example.

## @ References Only Resolve in CLAUDE.md and SKILL.md

`@path/to/file.md` references are resolved by the CLI at load time — not by the agent or the Read tool. They work in CLAUDE.md (expanded at session start) and SKILL.md (expanded when the skill is invoked). They do NOT resolve in arbitrary `.md` files read via the Read tool at runtime. This means data files (personas, reference docs, learnings) cannot use `@` to pull in other files — the agent must explicitly read them.

**Path resolution styles** (empirically verified 2026-03-13):

| Style | Example | Works? |
|-------|---------|--------|
| CWD/project-root relative | `@.claude/learnings/foo.md` | ✅ Yes |
| Tilde expansion | `@~/.claude/learnings/foo.md` | ✅ Yes |
| Relative traversal | `@../../learnings/foo.md` | ❌ No |
| Skill-directory relative | `@sibling.md` (from SKILL.md) | ❌ No |

**Cross-project verification:** All four styles tested from both the dotfiles repo (same-repo) and algo-trading (cross-repo). Results are consistent: CWD-relative and tilde work in both contexts; `../../` and sibling fail in both. CWD-relative fails cross-repo when the target file doesn't exist relative to the other project's root.

**Three-layer path resolution model:**

| Layer | CWD-relative | Tilde | `../../` | Sibling |
|-------|-------------|-------|----------|---------|
| **`@` reference (CLI)** | ✅ | ✅ | ❌ | ❌ |
| **Read tool (direct)** | ✅ | ✅ | ❌ | ❌ |
| **Agent (manual expansion)** | ✅ | ✅ | ✅ | ✅ |

The agent layer works because the CLI injects a "Base directory for this skill: /absolute/path" header when loading skills. Agents can resolve `../../` and sibling paths against this base directory, then pass the absolute path to Read. This was verified cross-repo — the expanded absolute path matches existing `Read(~/.claude/learnings/**)` permission patterns. A guideline instructing agents to always expand relative paths against the skill's base directory would make this layer reliably deterministic rather than dependent on agent initiative.

**Session-level dedup:** The CLI deduplicates `@` references within a session. If the same file is referenced by multiple `@` paths (even different path forms resolving to the same file), only the first triggers a Read. This can cause false negatives when testing — always use a file not yet loaded in the session.

**Format flexibility:** The `@` reference parser doesn't require any specific surrounding syntax. All of these resolve identically: `- @path — description`, `@path — description`, `- @path`, and bare `@path`. The `- ` list prefix and description text are formatting conventions for human readability — they don't affect resolution.

## GitHub API: Edit PR Review Comment Endpoint

The endpoint for editing a pull request review comment is `pulls/comments/{comment_id}` — NOT `pulls/{number}/comments/{comment_id}`. The PR number is not in the path.

```bash
gh api repos/{owner}/{repo}/pulls/comments/<comment_id> -X PATCH -F body=@.gh-reply.tmp
```

Using the wrong path (`pulls/<number>/comments/<id>`) returns a 404.
