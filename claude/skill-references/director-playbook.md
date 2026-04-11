---
description: "Playbook for directing parallel claude -p sessions: observability, monitoring, convergence, directives, intervention, and common patterns."
---

# Director Playbook

Structured guidance for the director (operator + main agent) when orchestrating parallel `claude -p` sessions. See `artifact-contract.md` for the standard structure skills must produce to be director-managed.

## Director Principles

**Agents demonstrate understanding before acting.** Implementation requires passing through a confirm gate — no exceptions. The lifecycle is: clarify (questions/analysis) → confirm (understanding + plan) → implement. This applies to any skill that orchestrates autonomous agents making code changes. Currently implemented in sweep:work-items; other orchestration skills (sweep:review-prs, sweep:address-prs) don't have this lifecycle because they review/address rather than implement changes.

**Directors observe and direct — they don't touch the working tree.** All code changes flow through agents via directives or targeted `Agent(isolation: "worktree")` launches. The director writes only: directives, monitoring state, and sweep artifacts. This eliminates `git stash` friction from mixing local edits with agent-pushed commits on the same branch.

**Standard path: director runs from `main`.** This avoids the active-branch workaround entirely — `git worktree add` works for every PR branch when the director isn't on one of them.

**Review and address must be separate `claude -p` sessions.** Never have the same agent both review and address an MR. A reviewer that knows it will also address goes easy; an addresser that wrote its own findings rubber-stamps them. The director presents review findings to the operator for sign-off before launching the address session. This is not a guideline — it is a structural requirement for review integrity.

## Decision Framework

The director has ceded decision power for routine calls but escalates on high-blast-radius, ambiguous-intent, or external-surface actions. Three tiers:

### Escalate to operator (operator makes the call)
1. **Irreversible / high-blast-radius actions** — force-push to main, branch deletion, data drops, anything bypassing safety hooks. Operator pulls the trigger even when "obviously fine."
2. **Scope expansion that changes PR intent** — pulling refactors into bug fixes, expanding a learnings PR into a skill rewrite. Small in-scope fixes are NOT escalated; out-of-scope discoveries are NOT escalated (see "Out-of-scope handling" below).
3. **Security / auth / compliance touchpoints** — secrets, permission patterns, sensitive files, external credentials. Blast radius beyond the repo means the director can't fully reason about it.
4. **Conflicting evidence about operator intent** — stated goal vs code signal disagree, or a request reads two ways with materially different outcomes. Escalate **with a written report** in `decisions.md` — not just a verbal ask. (Written-report-first variant: log the report at escalation time, then chat.)
5. **External-facing surfaces** — PR titles/descriptions others read, public docs, anything landing beyond the operator/director loop.

### Decide-with-report (director decides, logs rationale to `decisions.md`)
6. **Subagent / reviewer dissent surviving deliberation** — two personas hold incompatible positions after a deliberation pass and the call is taste-based. Director makes the call and logs why.
7. **Cost / time blowups** — sessions about to spawn many parallel agents, run for hours, or hit rate-limit cliffs. Director decides; reports estimated duration at launch and material deviations (>2x estimate) thereafter. No scheduled chatter — only deviation reports. Operator can checkpoint mid-session via chat.

### Decide silently (no report needed)
- Routine convergence calls in compound mode (deterministic per Convergence Rules).
- Small in-scope fixes that match the PR's intent.
- Choosing between equivalent technical paths.
- Body discipline / formatting / template decisions.
- Whether to write a directive for a summary-only finding inside the current scope.

### Out-of-scope handling

When a review surfaces a finding clearly outside the current PR's scope, the director:
1. Files a GitHub issue in the CWD repo (or, in multi-repo sessions, the repo most relevant to the issue). Issue body includes: source PR/session reference, the finding text, suggested fix if any, and the persona that surfaced it.
2. Logs the issue creation in `decisions.md` so the operator can audit what got punted.
3. Optionally spawns `/sweep:work-items` to address immediately, **only if context window allows** (director discretion based on remaining tokens).

### `decisions.md` schema

Lives at `<session_dir>/decisions.md` alongside `session.json`. Append-only dated sections:

```markdown
## <ISO timestamp> — <one-line title>

**Category**: <dissent | cost-time | out-of-scope | irreversible | scope-expansion | security | intent-conflict | external-surface>
**Decision**: <what was decided>
**Why**: <rationale, including what was weighed>
**Reversal cost**: <how easy is this to undo>
**Reported to operator**: <yes/no — yes for escalated categories, no for decide-with-report categories>
```

Write to `decisions.md` at decision time for categories 4, 6, 7. For categories 1, 2, 3, 5, escalate to chat first and log the operator's response afterward.

## Prerequisites Checklist

Before starting any sweep session:
1. `glab auth status` succeeds (or `gh auth status` for GitHub repos)
2. `~/.claude/settings.json` has all required permission patterns (see sweep skill prerequisites sections)
3. `tmp/claude-artifacts/change-request-replies/` write access — address sessions write reply payloads here. Verify the Write permission pattern matches at runtime (known friction point: tilde-path patterns may not resolve)
4. `tmp/claude-artifacts/sweep-reviews/` and `tmp/claude-artifacts/sweep-address/` exist or can be created
5. `~/.claude/skill-references/stream-monitor.sh` exists and is executable — the runner falls back to plain `claude -p` if missing, but `live.md` observability requires it

## Loop Setup: Offset Cadence

Run review and address sweeps on offset schedules:
- Review: :00, :05, :10, ...
- Address: :03, :08, :13, ...

The 3-minute offset ensures review findings are posted before the address sweep reads them. Same-time firing wastes a full cycle on handoff.

**Cycle 0 launch sequence:**
1. Assess review candidates and generate review artifacts
2. Launch review runner immediately (in background)
3. Assess address candidates and generate address artifacts (while review runs)
4. After review reaches `posted`/`done`, launch address runner

Launching review before address assessment parallelizes address artifact generation with review execution, reducing total wall-clock time. The address assessment may show "no comments" if review hasn't posted yet — this is expected. Address sessions handle no-op gracefully and pick up comments on the next cycle.

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
| `prompt.txt` | Sweep skill | Runner -> `claude -p` | Assessment |
| `state.md` | Runner | Director | During session (overwritten per state change) |
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

The runner handles inactivity detection and single-retry recovery automatically. The director only intervenes after the runner exhausts retries and escalates via `state.md`.

| Detection (from state.md) | Action |
|---------------------------|--------|
| `state: errored` + `escalation: needs-director` | Read `live.md` tail for context, investigate root cause, write directive for next launch |
| `state: rate-limited` | Check `.rate-limited` sentinel, advise operator on retry timing |
| `escalation: permission_denial` (in live.md, surfaced during investigation) | Fix permission in settings, write directive |
| `escalation: repeated_errors` (in live.md, surfaced during investigation) | Investigate root cause, write directive or escalate to operator |

The director does not poll `live.md` as a primary monitoring channel. It reads `live.md` only when investigating an escalation from `state.md` to understand what went wrong.

## Monitoring Table Format

Read all `pr-*/state.md` (runner lifecycle) and `pr-*/status.md` (session domain state) and present:

| PR | State | Mergeable | Milestone | Runner State | Attempt | Directives |
|----|-------|-----------|-----------|--------------|---------|------------|
| #51 | OPEN | MERGEABLE | done | completed | 1/2 | -- |
| #50 | OPEN | CONFLICTING | running | running | 1/2 | conflict resolution |
| #49 | MERGED | -- | skipped | -- | -- | -- |
| #48 | OPEN | MERGEABLE | errored | errored | 2/2 | needs-director |

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

### Compound Mode Relaunch Sequence

After every runner completion in compound mode, the director executes this decision tree automatically — no operator prompt needed:

1. **Address runner completes** → read review `result.md`. If findings > 0 this cycle → relaunch review to verify resolution. If all resolved → check address convergence (all PRs terminal?).
2. **Review runner completes** → read `result.md`. If findings posted (inline comments > 0 OR thread replies > 0) → relaunch address. If skipped or 0 findings → review converging, start 30m skip window.
3. **Both converged** → proceed to Phase 5.

"Runner completed" ≠ "converged." A completed runner means one cycle finished — convergence requires the domain rules above to be satisfied.

### What Is NOT Convergence
- "All sessions skipped" alone — if any open PR has `mergeable: CONFLICTING`, the loop must continue
- A single cycle of skips — wait for the convergence window (30m for review, all-terminal for address)
- A single cycle completing — convergence requires evaluating the domain rules, not just the runner state

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

## Worker Learnings Triage

During convergence wrap-up (Phase 5), the director must triage worker learnings before closing the session:

1. **Read** each completed run's `*/learnings.md` files.
2. **Assess** each observation for promotion:
   - Does it encode reusable knowledge (pattern, gotcha, convention)? → candidate for persistent learning
   - Is it project-specific or broadly applicable? → determines scope (project-local vs global/learnings-team)
   - Is it verified or a hypothesis? → frame accordingly
   - Is it a one-off observation (dead code, missing route)? → skip
3. **Present** candidates to the operator in a table with Type/Scope/Utility columns (same format as `/learnings:compound`).
4. **Save** approved learnings to the appropriate location.

Workers generate domain-specific insights that the director wouldn't independently discover — particularly when workers load learnings-team learnings that connect to their findings (e.g., a precision learning predicting a parseFloat bug). These insights are lost if not promoted during the session.

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
| Process lifecycle (running, retry, timeout) | runner (`state.md`) | director (reads, doesn't write) |
| Session observability | `stream-monitor.sh` + this playbook | runner template (just wires the pipeline) |
| Stream-json event schema | `stream-monitor.sh` (parses events) | learnings (learnings capture discovery) |
| Artifact contract (directory structure, manifest schema) | `artifact-contract.md` | this playbook, learnings, sweep-scaffold |
