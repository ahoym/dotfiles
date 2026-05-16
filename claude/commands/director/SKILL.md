---
name: director
description: "Orchestrate parallel claude -p sessions — bootstrap, launch, monitor, and converge. Works with any skill that produces manifest.json, item directories, and a runner script."
argument-hint: "[review] [address] [review+address] [custom] [--prs=#47,#46] [--offset=3]"
---

## Context
- CWD: !`pwd`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "(not a git repo)"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "(n/a)"`
- Remote: !`git remote get-url origin 2>/dev/null || echo "(n/a)"`

## Mode Detection

Determine the orchestration mode from context + arguments:

| Signal | Mode | Load |
|--------|------|------|
| `$ARGUMENTS` contains `review`, `address`, or `review+address` | **Sweep** | `sweep-mode.md` from this skill's directory |
| `$ARGUMENTS` contains `custom` or a path to a manifest/plan | **Custom** | `custom-mode.md` from this skill's directory |
| Git root is "(not a git repo)" | **Custom** (forced) | `custom-mode.md` from this skill's directory |
| CWD contains existing `manifest.json` with `"waves"` key | **Custom** (detected) | `custom-mode.md` from this skill's directory |
| None of the above | Ask operator | — |

**Load the mode file before proceeding.** Each mode file contains its own Bootstrap, Assess, and artifact generation phases. Phases 3-5 (Launch, Monitor, Converge) are shared below.

## Prerequisites (all modes)

For prompt-free execution, add these allow patterns to `~/.claude/settings.local.json`:

```json
"Bash(date +*)",
"Bash(bash tmp/**/let-it-rip.sh)",
"Bash(test -x ~/.claude/skill-references/stream-monitor.sh*)",
"Write(tmp/claude-artifacts/director-sessions/**)"
```

## Eager-load at bootstrap

Read **`default:claude-code/multi-agent/director/CLAUDE.md`** before Phase 1 — it indexes the director sub-cluster (process-and-meta, runner-design, watermarks-and-skip, observability, failure-modes). Read process-and-meta.md and runner-design.md eagerly; read others lazily when their domain surfaces (failure-modes on escalation; observability on log inspection; watermarks-and-skip on skip-logic confusion). Together these own the core director contract (director-as-supervisor paradigm, three-channel interface, runner-vs-session state separation, event-driven lifecycle, decision-matrix trust, watermark patterns, rate-limit handling).

**Load decision matrix (eager — always)**: read `~/.claude/skill-references/director-decision-matrix.md`. The matrix gates every Phase 4 action (routine / decide-with-report / escalate). Loading lazily creates a "you have enough already" trap — the playbook's narrative load makes a deferred matrix-read feel optional. Eager load avoids it.

## Reference Files (skill-references — read when needed)

- `~/.claude/skill-references/director-playbook.md` — operationalized director contract (monitoring table, convergence rules, directive templates). Read at Phase 4 start.
- `~/.claude/skill-references/director-decision-matrix.md` — escalation tiers, autonomy boundaries. Read at Phase 4 start.
- `~/.claude/skill-references/artifact-contract.md` — directory structure, manifest schema. Read when generating artifacts.
- `~/.claude/skill-references/parallel-claude-runner-template.sh` — Read when generating runner scripts (sweep mode only).

## Phase 3: Launch (shared)

After each skill completes, read its generated `manifest.json` to get the `run_dir` and eligible items. For each item, append the run_dir to its entry in `session.json`:
```json
{
  "items": {
    "pr-69": [{"run_dir": "<path>", "skill": "sweep:review-prs"}],
    "issue-56": [{"run_dir": "<path>", "skill": "sweep:work-items"}],
    "phase-E1": [{"run_dir": "<path>", "skill": "director-custom:plan-phases"}]
  }
}
```
Item-key conventions: `pr-<N>/`, `issue-<N>/`, `phase-<P>/` (plan-keyed sessions). To check status: take the last entry for an item, read `<run_dir>/<item-dir>/status.md`.

**Plan-keyed sessions (custom shape)**: when no skill exists for the operator's intent — e.g., orchestrating a sequential plan's phases as items without creating GitHub issues — fork the runner template and write per-phase artifacts directly. The runner can carry dependency gates by reading each item's `metadata.json` for `blocked_by` and checking each blocker's `pr_number` via `gh pr view --json state`. Convergence per item = its `pr_number`'s state reaching `MERGED`. Use `phase-<P>/` directory naming so `sweep-status-summary.sh` recognizes the shape.

**Artifact generation batching:** Sweep skills generate artifacts internally. When the director writes supporting files (session.json updates, directives, preflight copies), batch independent writes in parallel.

**Always invoke sweep skills for assessment — never generate artifacts directly.** The director's role is to orchestrate, not to replicate assessment logic. Sweep skills handle platform detection, skip filtering, persona discovery, and the full metadata schema. Direct artifact generation bypasses these and makes sessions harder to debug and predict.

1. For each run in session manifest, launch its runner script via `Bash(run_in_background: true)`:
   ```
   bash <run_dir>/let-it-rip.sh
   ```
2. Mode-specific launch additions (see mode file — compound sweep waits, wave gating for custom).
3. Present the initial monitoring table (full table, per playbook format).
4. **Wait for the background task notification.** Do not poll or sleep-loop — the notification arrives automatically when the runner exits.

## Phase 4: Monitor + React (shared)

**Decision matrix applies to every action in this phase.** The matrix was eager-loaded at bootstrap. Classify before acting: routine → auto-decide and report. Dissent/cost-time → decide and log to `decisions.md`. Irreversible/security/scope-expansion → escalate.

The director is event-driven, not polling. It reads state on-demand: when a background task completes, when the operator asks, or when evaluating convergence.

**Triggers:**

1. **Background task completes** (runner finishes). Read all `<run_dir>/*/state.md` and `<run_dir>/*/status.md`. Build the unified monitoring table per the playbook's Monitoring Table Format. Then execute this checklist — every item, every time:

   **a. Escalations:**
   - `state: errored` + `escalation: needs-director` → read `live.md` tail for diagnostics, investigate root cause, write directive for next launch or escalate to operator.
   - `state: rate-limited` → check `.rate-limited` sentinel, advise operator on retry timing.

   **b. Mode-specific checks** — see mode file (conflicts for sweep, wave dependencies for custom).

   **c. Convergence:** evaluate per the mode file's Convergence Rules.

   **d. Decision gate (before surfacing anything to operator):**
   - For each action about to take: classify its tier (routine / decide-with-report / escalate) using the matrix
   - If routine → execute, log action taken, surface result
   - If decide-with-report → execute, append to `decisions.md` with reasoning, surface result
   - If escalate → present with recommendation
   - **NEVER present a routine decision as a question.** "Should I resolve the conflicts?" when the matrix says "routine — auto-decide" is a failure. Execute and report: "Resolved conflicts on #87 via addresser directive."

2. **Operator asks for status.** Read all `state.md` + `status.md`, present the monitoring table.

3. **Convergence check.** After all items reach a terminal runner state (completed, errored, rate-limited), evaluate domain convergence per the playbook's Convergence Rules. When a runner completes: decide relaunch (not converged) or mark converged.

**Check directive opportunities** per the playbook's Directive Patterns on each trigger. Write directives when triggered — summary-only findings and conflict resolution are the most common.

**Present** the monitoring table and any actions taken. First pass: full table. Subsequent: delta-only with "N unchanged" summary.

**Director responsibilities in Phase 4:**
- Convergence evaluation and relaunch decisions
- Directive writing (summary-only findings, conflict resolution)
- Circular activity detection (via `live.md` when investigating escalations)

Note: process lifecycle (inactivity detection, kill, retry) is owned by the runner, not the director.

## Phase 5: Convergence + Wrap-up

**Never merge PRs and never offer to merge.** Merging is the operator's review checkpoint — the moment they read what agents produced. When a director session reaches a PR-mergeable terminal state, present convergence and stop. Don't propose merge as a "next step" option, even when it's clearly the right move and the PR is in the operator's own repo. The operator merges when they're ready.

1. Check convergence by reading `*/status.md` across all run_dirs listed in `session.json`.
2. Session ends when all runs converge.
3. Write final `director-state.md` per playbook format with terminal state.
4. Present a final summary: per-run retro (read each run's `*/results.md` and `*/learnings.md`).
5. Review `<session_dir>/decisions.md` as part of the retro — surface decide-with-report entries (dissent, cost-time, out-of-scope) so the operator can audit autonomous calls and flag any that should have been escalated.
6. Offer to invoke `/session-retro`. When accepted, the retro skill will read all worker `learnings.md` files before compounding — high-value worker observations are easy to lose otherwise.

## Related Learnings

**Load eagerly at bootstrap for any compound or convergence session.** Friction-triggered loading is too lax — director sessions hit watermark/relaunch/escalation patterns that the linked files cover, and reaching for them only after friction wastes a cycle. Skip eager loading only for trivial single-mode sessions where convergence is already obvious.

- `~/.claude/learnings/claude-code/multi-agent/director/CLAUDE.md` — sub-cluster index (observability, runner-design, watermarks-and-skip, failure-modes, process-and-meta). Read the index plus any focused file matching session shape.
- `~/.claude/learnings/claude-code/sweep-sessions.md` — sweep template limitations (PR-centric runner), watermark logic, ack-without-push gap, confirmer/clarifier lifecycle, template script validation traps
- `~/.claude/learnings/claude-code/multi-agent/orchestration.md` — parallel agents, rerun semantics, append-only artifacts, session-resumable patterns
- `~/.claude/learnings/claude-code/multi-agent/vp-tier-orchestration.md` — VP-tier coordination across repos when this director is itself launched from a higher-tier session
- `~/.claude/learnings/claude-code/multi-agent/background-agent-capabilities.md` — bg Agent vs claude -p decision framework for in-session subagent work
