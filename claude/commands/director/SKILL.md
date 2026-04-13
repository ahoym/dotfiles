---
name: director
description: "Orchestrate parallel claude -p sessions — bootstrap, launch, monitor, and converge. Works with any skill that produces manifest.json, item directories, and a runner script."
argument-hint: "[review] [address] [review+address] [--prs=#47,#46] [--offset=3]"
---

## Context
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`
- Current branch: !`git branch --show-current 2>/dev/null`
- Remote: !`git remote get-url origin 2>/dev/null`

## Prerequisites

For prompt-free execution, add these allow patterns to `~/.claude/settings.local.json`:

```json
"Bash(gh auth status*)",
"Bash(date +*)",
"Bash(bash tmp/**/let-it-rip.sh)",
"Bash(test -x ~/.claude/skill-references/stream-monitor.sh*)",
"Write(tmp/claude-artifacts/director-sessions/**)"
```

## Director Principle

**Directors observe and direct — they never touch the working tree.** All code changes flow through parallel `claude -p` sessions launched via generated bash scripts. The director writes only: session manifests, directives, and monitoring state.

**Never hand-write runner scripts.** Always use `parallel-claude-runner-template.sh` with placeholder substitution. Hand-written scripts introduce variable scoping bugs (especially with `xargs -I {}` and `export -f`) that fail silently.

## Phase 1: Bootstrap

1. Parse `$ARGUMENTS` for:
   - **Mode**: `review`, `address`, `review+address`, or empty (ask operator)
   - **Passthrough flags**: `--prs=...` forwarded to subordinate skills
   - **Offset**: `--offset=N` minutes between review/address launches (default 3)
   - **Convergence**: if the operator requests "run to convergence" or "converge", read `convergence-loop.md` from this skill's directory and enter convergence loop mode after Phase 3 launch
2. If no mode specified, ask the operator what to orchestrate. This can be any skill that produces manifest.json + item directories + a runner script — not just sweep skills.
3. **Load sweep playbook** (conditional): if mode is `review`, `address`, or `review+address`, read `~/.claude/skill-references/director-playbook.md` for monitoring table format, convergence rules, intervention triggers, and offset cadence. Skip for non-sweep orchestration.
4. **Prerequisites** (warn, don't block):
   - `gh auth status` succeeds
   - `~/.claude/skill-references/stream-monitor.sh` exists and is executable
   - Current branch is `main` (standard path avoids worktree conflicts)
5. Compute timestamp via separate `Bash` call: `date +%Y-%m-%d-%H%M`. Create session directory at `tmp/claude-artifacts/director-sessions/<timestamp>/`.
6. Initialize `session.json` (append-only item-centric index):
   ```json
   {
     "created_at": "<ISO>",
     "session_dir": "<path>",
     "items": {}
   }
   ```
   Indexed by item (`pr-69`, `issue-56`), not by run. Each item maps to an ordered list of run_dirs that touched it. Append-only — never update or remove entries. To check an item's status: read the last run_dir in its list, then read `<item-dir>/status.md`.
7. Initialize `decisions.md` in the session dir with a single header line (append-only decision log per the playbook's Decision Framework):
   ```markdown
   # Director Decisions — <timestamp>
   ```

## Phase 2: Assess + Generate Artifacts

For each requested mode, invoke the corresponding skill via `Skill` tool. Any skill that produces manifest.json + item directories + a runner script can be orchestrated.

**Convenience aliases** for common sweep modes:
- `review` → `skill="sweep:review-prs"`, `args="<passthrough>"`
- `address` → `skill="sweep:address-prs"`, `args="<passthrough>"`

After each skill completes, read its generated `manifest.json` to get the `run_dir` and eligible items. For each item, append the run_dir to its entry in `session.json`:
```json
{
  "items": {
    "pr-69": [{"run_dir": "<path>", "skill": "sweep:review-prs"}],
    "issue-56": [{"run_dir": "<path>", "skill": "sweep:work-items"}]
  }
}
```
To check status: take the last entry for an item, read `<run_dir>/<item-dir>/status.md`.

**Compound mode**: assess review first, launch review runner in the background immediately, then assess address while review is already running. This parallelizes address assessment with review execution, reducing total wall-clock time.

**Artifact generation batching:** Sweep skills generate artifacts internally. When the director writes supporting files (session.json updates, directives, preflight copies), batch independent writes in parallel.

**Always invoke sweep skills for assessment — never generate artifacts directly.** The director's role is to orchestrate, not to replicate assessment logic. Sweep skills handle platform detection, skip filtering, persona discovery, and the full metadata schema. Direct artifact generation bypasses these and makes sessions harder to debug and predict.

## Phase 3: Launch

1. For each run in session manifest, launch its runner script via `Bash(run_in_background: true)`:
   ```
   bash <run_dir>/let-it-rip.sh
   ```
2. **Compound mode** (review+address only): review runner is already running (launched after review assessment in Phase 2). Wait for review completion before launching address:
   - Wait for the review runner's background task to complete (event-driven, not polling)
   - **All review PRs reach `posted` or `done`** → launch address runner immediately (but never before the minimum offset of 3 minutes from review launch, to allow GitLab API propagation)
   - **Any review PR reaches `errored`** → surface to operator before launching address
   - **Timeout after 20 minutes** → launch address runner anyway (review may be stuck; address session's watermark/skip logic handles the no-new-comments case gracefully)
3. Update each run's status to `"active"` in session manifest.
4. Present the initial monitoring table (full table, per playbook format).

## Phase 4: Monitor + React

**Decision matrix applies to every action in this phase.** Read `~/.claude/skill-references/director-decision-matrix.md` and classify before acting: routine → auto-decide and report. Dissent/cost-time → decide and log to `decisions.md`. Irreversible/security/scope-expansion → escalate.

The director is event-driven, not polling. It reads state on-demand: when a background task completes, when the operator asks, or when evaluating convergence.

**Triggers:**

1. **Background task completes** (runner finishes). Read all `<run_dir>/*/state.md` and `<run_dir>/*/status.md`. Build the unified monitoring table per the playbook's Monitoring Table Format. Then execute this checklist — every item, every time:

   **a. Escalations:**
   - `state: errored` + `escalation: needs-director` → read `live.md` tail for diagnostics, investigate root cause, write directive for next launch or escalate to operator.
   - `state: rate-limited` → check `.rate-limited` sentinel, advise operator on retry timing.

   **b. Conflicts (decision matrix: routine — auto-decide):**
   - Any PR shows `mergeable: CONFLICTING` in `status.md` → write directive to `<run_dir>/pr-<N>/directives.md` instructing the addresser to resolve conflicts. If no address run exists yet, generate one with `RESOLVE_CONFLICTS: "true"`. Do not ask the operator. Do not do the rebase yourself. Log to `decisions.md` and surface the action taken.

   **c. Convergence:** evaluate per the Convergence Rules below.

   **d. Decision gate (before surfacing anything to operator):**
   - Load `~/.claude/skill-references/director-decision-matrix.md` if not loaded this phase
   - For each action about to take: classify its tier (routine / decide-with-report / escalate)
   - If routine → execute, log action taken, surface result
   - If escalate → present with recommendation
   - **NEVER present a routine decision as a question.** "Should I resolve the conflicts?" when the matrix says "routine — auto-decide" is a failure. Execute and report: "Resolved conflicts on #87 via addresser directive."

2. **Operator asks for status.** Read all `state.md` + `status.md`, present the monitoring table.

3. **Convergence check.** After all items reach a terminal runner state (completed, errored, rate-limited), evaluate domain convergence per the playbook's Convergence Rules. When a runner completes: decide relaunch (not converged) or mark converged.

**Compound mode auto-relaunch (review+address):** After every runner completion, execute this decision tree automatically — do not prompt the operator unless escalation is needed:
   - **Address runner completes** → read review `results.md` for last cycle's findings. If findings > 0 this cycle, relaunch review runner to verify resolution. If all findings resolved (or review already converged), check address convergence rules.
   - **Review runner completes** → read `results.md`. If new findings posted (inline comments > 0 or thread replies > 0), relaunch address runner. If review skipped or 0 findings, review loop is converging — start the 30m skip window.
   - **Offset cadence**: maintain minimum 3-minute gap between review and address launches on relaunch, same as cycle 0.

**Check directive opportunities** per the playbook's Directive Patterns on each trigger. Write directives when triggered -- summary-only findings and conflict resolution are the most common.

**Conflict resolution is handled inline by the addresser when `RESOLVE_CONFLICTS=true`.** When a PR has merge conflicts (`mergeable: CONFLICTING`), regenerate the address artifacts with `RESOLVE_CONFLICTS: "true"` in the PR's `metadata.json`, then re-assemble the prompt via `fill-template.sh`. Only regenerate when no address session is in-flight for this PR (check `status.md` milestone != `addressing`/`pushing`). If a session is running, write a directive for the next cycle instead of regenerating artifacts mid-flight. The addresser checks for conflicts at runtime (Step 6) — no need to pass conflict state in metadata. This is a routine director decision — auto-decide and surface the action taken, don't prompt the operator. The addresser-prompt's Step 6 invokes the `git:resolve-conflicts` skill and resolves conflicts before addressing comments — rebase + address completes in a single `claude -p` run.

**Present** the monitoring table and any actions taken. First pass: full table. Subsequent: delta-only with "N unchanged" summary.

**Director responsibilities in Phase 4:**
- Convergence evaluation and relaunch decisions
- Directive writing (summary-only findings, conflict resolution)
- Circular activity detection (via `live.md` when investigating escalations)

Note: process lifecycle (inactivity detection, kill, retry) is owned by the runner, not the director.

Out-of-scope review findings become GitHub issues (filed in the CWD repo), not operator pings. When escalating, still present what you see, what you think it means, and what you'd recommend.

## Phase 5: Convergence + Wrap-up

**Never merge PRs and never offer to merge.** Merging is the operator's review checkpoint — the moment they read what agents produced. When a director session reaches a PR-mergeable terminal state, present convergence and stop. Don't propose merge as a "next step" option, even when it's clearly the right move and the PR is in the operator's own repo. The operator merges when they're ready.

1. Check convergence by reading `*/status.md` across all run_dirs listed in `session.json`.
2. Session ends when all runs converge.
3. Write final `director-state.md` per playbook format with terminal state.
4. Present a final summary: per-run retro (read each run's `*/results.md` and `*/learnings.md`).
5. Review `<session_dir>/decisions.md` as part of the retro — surface decide-with-report entries (dissent, cost-time, out-of-scope) so the operator can audit autonomous calls and flag any that should have been escalated.
6. Offer to invoke `/session-retro`. When accepted, the retro skill will read all worker `learnings.md` files before compounding — high-value worker observations are easy to lose otherwise.
