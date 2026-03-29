Worktree mechanics and Task tool isolation — CWD pinning, subagent context, mid-flight messaging limitations, and cross-repo operations.
- **Keywords:** worktree, Task tool, isolation, CWD pinning, subagent, context continuation, skill discovery, persisted tool output
- **Related:** none

---

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

## Context Continuation Loses File Contents

When a session is continued from a compacted conversation (context overflow), **all file contents read in the prior session are lost**. The conversation summary preserves metadata (file paths, line numbers, key findings) but not the actual file text. Budget time for re-reading source files after continuation.

**Mitigation:** Capture critical landmarks explicitly in conversation (e.g., "txFailureResponse is at line 200-209 in lib/api.ts") so continuation reduces re-reading to verification rather than discovery.

## Worktree CWD Pinning

Claude Code resets CWD to the worktree root after every Bash call — `cd` to another directory doesn't persist between calls. Within a single Bash call, `cd /path && git status` works, but the next Bash call starts back at the worktree root.

**Impact:** Cross-repo operations (e.g., committing to main from a worktree session) require either `cd && <cmd>` chains (don't match permission patterns) or `git -C` (same problem). There is no friction-free path.

**Mitigations:**
- Surface the constraint to the operator before attempting cross-repo operations. See `claude/worktrees/CLAUDE.md` for the documented constraint and recommended approach.
- **Split across sessions:** Make file edits in the worktree session (Edit/Write land on disk at the main repo path), then handle git operations from a separate session rooted in the main repo — no CWD pinning, no permission friction.

## Multi-Step Git Ops Across Repos Require `cd` on Every Call

CWD resets to the session's working directory after every Bash call — a `cd` in one call does not persist to the next. For multi-step git operations targeting a different repo (e.g., cherry-picking onto a worktree branch while CWD is the main repo), either:

1. **Chain all steps in one call**: `cd <path> && git cherry-pick <hash> && git push ...`
2. **Prefix every call with `cd <path>`**: if steps must be separate, start each Bash call with `cd <path>` — never assume CWD carried over

Failing to do this causes commands to silently run against the wrong repo. The symptom is a successful git operation on the wrong branch (e.g., cherry-pick lands on `main` instead of a feature branch).

## Subagents Receive Full CLAUDE.md Context

Subagents launched via the Agent tool receive CLAUDE.md and all `@`-referenced guidelines — including the learnings search protocol. They can search and load learnings independently via gate #1 (session start). However, persona gates (#2–3) only fire at plan mode entry and implementation start — phases subagents rarely enter. The orchestrator has better context for persona selection and should include a persona assignment in the subagent prompt for domain-specific work.

## Persisted Tool Output Nests Line-Number Prefixes

When Bash output exceeds the inline limit, it's saved to a persisted file under `tool-results/`. Reading that file via Read adds a `N→` line-number prefix. If the Read result itself exceeds the limit and is persisted again, the next Read adds another prefix layer — producing `N→  N→  N→ ...` nesting that's unreadable. Always read the **original** persisted file with `offset` + `limit` parameters rather than re-reading a persisted copy of a persisted copy.

## Cross-Refs

No cross-cluster references.
