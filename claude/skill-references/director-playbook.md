---
description: "Playbook for directing parallel claude -p sessions: observability, monitoring, convergence, directives, intervention, and common patterns."
---

# Director Playbook

Structured guidance for the director (operator + main agent) when orchestrating parallel `claude -p` sessions. See `artifact-contract.md` for the standard structure skills must produce to be director-managed.

## Director Principles

**Directors observe and direct — they don't touch the working tree.** All code changes flow through agents via directives or targeted `Agent(isolation: "worktree")` launches. The director writes only: directives, monitoring state, and sweep artifacts. This eliminates `git stash` friction from mixing local edits with agent-pushed commits on the same branch.

**Standard path: director runs from `main`.** This avoids the active-branch workaround entirely — `git worktree add` works for every PR branch when the director isn't on one of them.

## Prerequisites Checklist

Before starting any sweep session:
1. `gh auth status` succeeds
2. `~/.claude/settings.json` has all required permission patterns (see sweep skill prerequisites sections)
3. `tmp/change-request-replies/` write access — address sessions write reply payloads here. Verify the Write permission pattern matches at runtime (known friction point: tilde-path patterns may not resolve)
4. `tmp/sweep-reviews/` and `tmp/sweep-address/` exist or can be created
5. `~/.claude/skill-references/stream-monitor.sh` exists and is executable — the runner falls back to plain `claude -p` if missing, but `live.md` observability requires it

## Loop Setup: Offset Cadence

Run review and address sweeps on offset schedules:
- Review: :00, :05, :10, ...
- Address: :03, :08, :13, ...

The 3-minute offset ensures review findings are posted before the address sweep reads them. Same-time firing wastes a full cycle on handoff.

**Cycle 0 launch sequence:**
1. Assess both review and address candidates (generate both artifact sets)
2. Launch review runner immediately
3. After the offset interval, launch address runner/agent

Assess both upfront so artifacts are ready. The address assessment may show "no comments" if review hasn't posted yet — this is expected. Address sessions handle no-op gracefully and pick up comments on the next cycle.

## Session Observability

`claude -p` sessions are fire-and-forget — the director is blind until the process exits. The runner template pipes through `stream-monitor.sh` to fill this gap:

```
cat prompt.txt \
  | sh -c 'echo $$ > $PR_DIR/session.pid; exec claude -p --verbose --output-format stream-json' \
  | stream-monitor.sh $PR_DIR \
  | tee $PR_DIR/raw.jsonl
```

`stream-monitor.sh` is a pass-through filter: every event flows to stdout unchanged, but as a side effect it appends typed entries to `live.md`. The `sh -c`/`exec` wrapper captures the real `claude -p` PID to `session.pid` (the monitor reads it with a brief retry for pipeline race).

### Stream-JSON Events

`--output-format stream-json` (requires `--verbose`) emits newline-delimited JSON. Key event types:

| Event | What it reveals |
|-------|-----------------|
| `system/init` | Model, tools, CWD |
| `assistant` (tool_use) | Tool name, inputs. Subagent calls carry `parent_tool_use_id` |
| `user` (tool_result) | Success/failure content, permission denials |
| `rate_limit_event` | Throttling |
| `result/success` | Duration, cost, turns, permission_denials[] |

### Per-PR File Inventory

| File | Writer | Reader | Lifecycle |
|------|--------|--------|-----------|
| `prompt.txt` | Sweep skill | Runner → `claude -p` | Assessment |
| `status.md` | Agent | Director, next agent | End of session |
| `result.md` | Agent | Director | End of session (appended) |
| `learnings.md` | Agent | Director, future sessions | End of session (appended) |
| `directives.md` | Director | Agent (next session) | Append-only |
| `session.pid` | Runner | Monitor, director | Launch |
| `live.md` | `stream-monitor.sh` | Director | During session (appended) |
| `raw.jsonl` | `tee` | Post-hoc debugging | During session |

### live.md Entry Types

Append-only log. Entry types: `started` (pid), `init` (model), `tool_call` (name, input, subagent tag), `escalation` (permission denials, repeated errors), `rate_limit`, `completed` (cost, duration, turns), `terminated` (pipe closed without result — crash or kill).

### Director Intervention

The director cannot send input to a running session. Interventions use kill + directive:

| Detection (from live.md) | Action |
|--------------------------|--------|
| No entries for >5min | `kill $(cat session.pid)`, directive for retry |
| `escalation: permission_denial` | Kill, fix permission, directive |
| `escalation: repeated_errors` | Kill, investigate root cause |
| Recent `tool_call` entries | No action — working normally |

## Monitoring Table Format

After each cycle, read all `pr-*/status.md` (for completed sessions) and `pr-*/live.md` (for in-progress sessions) and present:

| PR | State | Mergeable | Milestone | Last Activity | Live Status | Directives |
|----|-------|-----------|-----------|---------------|-------------|------------|
| #51 | OPEN | MERGEABLE | done | 2m ago | — | — |
| #50 | OPEN | CONFLICTING | running | now | tool: gh (subagent) | conflict resolution |
| #49 | MERGED | — | skipped | — | — | — |
| #48 | OPEN | MERGEABLE | running | 6m ago | ⚠ stale | — |

First cycle: full table. Subsequent cycles: delta-only (changed rows), with a one-line "N unchanged" summary.

## Convergence Rules

### Review Loop
- **Converged**: all sessions skip (no new activity) for 30m wall-clock
- **Not converged**: any session produced findings this cycle
- **Auto-cancel**: after 30m of all-skip inactivity — reviews are reactive to changes

### Address Loop
- **Converged**: all PRs terminal (MERGED or CLOSED)
- **Not converged**: any open PR exists, even if all sessions skipped — main can advance and create conflicts at any time
- **Conflict watch**: each cycle, check `mergeable` in status.md. If CONFLICTING on an open PR, write a conflict resolution directive
- **Auto-cancel**: only when all PRs terminal

### What Is NOT Convergence
- "All sessions skipped" alone — if any open PR has `mergeable: CONFLICTING`, the loop must continue
- A single cycle of skips — wait for the convergence window (30m for review, all-terminal for address)

## Directive Patterns

### Conflict Resolution
**When:** `mergeable: CONFLICTING` on an open PR in address sweep.
**Write to:** `<ADDRESS_RUN_DIR>/pr-<N>/directives.md`

```markdown
## <ISO timestamp>
PR has merge conflicts with base branch. Invoke `/git:resolve-conflicts <base-branch>` before addressing comments.
```

### Conciseness / Focus Review
**When:** review findings indicate verbose or unfocused content.
**Write to:** `<REVIEW_RUN_DIR>/pr-<N>/directives.md` or global `directives.md`

```markdown
## <ISO timestamp>
Review for conciseness: identify verbose prose, duplication, and extraction candidates. Post findings as inline comments.
```

### Summary-Only Review Finding
**When:** latest review result.md section has `findings > 0` AND `inline_comments == 0` (finding on unchanged lines, documented in summary only).
**Why:** the address loop can't pick this up — no inline comment means no comment ID change, so the address agent's watermark matches and it skips.
**Write to:** `<ADDRESS_RUN_DIR>/pr-<N>/directives.md`

```markdown
## <ISO timestamp>
Review found a summary-only finding (no inline comment). Finding: <description from review summary>. Expected fix: <what to change and where>. This directive overrides skip logic.
```

### Sensitive File Escalation
**When:** addresser escalates a finding on a protected/sensitive file.
**Write to:** per-PR directives, after operator reviews and approves.

```markdown
## <ISO timestamp>
Director-approved fix for <file>. <description of approved change>. Post a top-level PR comment flagging the sensitive file edit after committing.
```

### Directive Lifecycle
- Directives are append-only (dated sections, never overwrite)
- To mark a directive as satisfied, append a new section:
  ```markdown
  ## <ISO timestamp>
  Directive from <original timestamp> satisfied. No further action needed.
  ```
- Sessions should check whether directives are already satisfied before acting — prevents redundant invocations

## Re-Assessment Triggers

Re-run the sweep skill (not just the runner) when:
- New PRs opened since last assessment
- PRs closed/merged that need cleanup from the eligible set
- Fundamental scope change (different PR filter, new repo)

Do NOT re-assess just because a cycle skipped — that is normal convergence behavior. Re-running the runner script is sufficient for ongoing cycles.

## Active-Branch Workaround (ad-hoc only)

When running ad-hoc from a branch that is also a PR target, `git worktree add` fails ("branch already checked out"). The address sweep skill detects and reuses existing worktrees. For PRs on the director's active branch where no worktree exists, use `Agent(isolation: "worktree")` to work from an isolated context.

The standard path (director on `main`) avoids this entirely. This section applies only to ad-hoc sessions where the director happens to be on a PR branch.

## Director State

After each cycle, update `<RUN_DIR>/director-state.md`:

```yaml
cycle: <N>
review_cycles: <N>
address_cycles: <N>
convergence:
  review: converged | not-converged | auto-cancelled
  address: converged | not-converged
context_tokens_approx: <estimate from task outputs>
last_updated: <ISO timestamp>
```

Followed by the current monitoring table snapshot. This persists the director's view across cycles — useful for handoff to a fresh session if context runs low. The `context_tokens_approx` field signals when to consider compounding learnings and handing off.

## Single Source of Truth

| Concern | Lives in | Not duplicated in |
|---------|----------|-------------------|
| Classification logic (skip/process) | `sweep-scaffold.md` + sweep skill files | runner template, this playbook |
| Watermark comparison | `sweep-scaffold.md` (prompt steps 1-4) | runner template (only does cheap pre-flight) |
| Reaction targets & emoji | `review-comment-classification.md` | re-review-mode.md files |
| Convergence rules | this playbook | individual sessions (they don't decide convergence) |
| Directive patterns | this playbook | learnings (learnings capture discovery, playbook operationalizes) |
| Session observability | `stream-monitor.sh` + this playbook | runner template (just wires the pipeline) |
| Stream-json event schema | `stream-monitor.sh` (parses events) | learnings (learnings capture discovery) |
| Artifact contract (directory structure, manifest schema) | `artifact-contract.md` | this playbook, learnings, sweep-scaffold |
