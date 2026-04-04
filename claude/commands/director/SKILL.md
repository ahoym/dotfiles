---
name: director
description: "Orchestrate parallel claude -p sessions — bootstrap, launch, monitor, and converge. Works with any skill that produces the standard artifact contract (manifest.json + item directories + runner script)."
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
"Write(tmp/director-sessions/**)"
```

## Director Principle

**Directors observe and direct — they never touch the working tree.** All code changes flow through parallel `claude -p` sessions launched via generated bash scripts. The director writes only: session manifests, directives, and monitoring state.

## Phase 1: Bootstrap

1. Parse `$ARGUMENTS` for:
   - **Mode**: `review`, `address`, `review+address`, or empty (ask operator)
   - **Passthrough flags**: `--prs=...` forwarded to subordinate skills
   - **Offset**: `--offset=N` minutes between review/address launches (default 3)
2. If no mode specified, ask the operator what to orchestrate. This can be any skill that produces the standard artifact contract — not just sweep skills.
3. **Load sweep playbook** (conditional): if mode is `review`, `address`, or `review+address`, read `~/.claude/skill-references/director-playbook.md` for monitoring table format, convergence rules, intervention triggers, and offset cadence. Skip for non-sweep orchestration.
4. **Prerequisites** (warn, don't block):
   - `gh auth status` succeeds
   - `~/.claude/skill-references/stream-monitor.sh` exists and is executable
   - Current branch is `main` (standard path avoids worktree conflicts)
5. Compute timestamp via separate `Bash` call: `date +%Y-%m-%d-%H%M`. Create session directory at `tmp/director-sessions/<timestamp>/`.
6. Initialize `session.json`:
   ```json
   {
     "created_at": "<ISO>",
     "session_dir": "<path>",
     "runs": [],
     "status": "active"
   }
   ```

## Phase 2: Assess + Generate Artifacts

For each requested mode, invoke the corresponding skill via `Skill` tool. Any skill that produces the standard artifact contract (manifest.json + item directories + runner script) can be orchestrated.

**Convenience aliases** for common sweep modes:
- `review` → `skill="sweep-review-prs"`, `args="<passthrough>"`
- `address` → `skill="sweep-address-prs"`, `args="<passthrough>"`

After each skill completes, read its generated `manifest.json` to get the `run_dir`. Append to `session.json`:
```json
{ "run_dir": "<path>", "source_skill": "<skill-name>", "status": "ready" }
```

**Compound mode**: assess both skills before launching either — artifacts should be ready for both runs before cycle 0 begins.

## Phase 3: Launch

1. For each run in session manifest, launch its runner script via `Bash(run_in_background: true)`:
   ```
   bash <run_dir>/let-it-rip.sh
   ```
2. **Compound mode** (review+address only): launch review runner immediately. Then poll for review completion before launching address:
   - Poll every 2 minutes: read each review PR's `status.md` for milestone
   - **All review PRs reach `posted` or `done`** → launch address runner immediately (but never before the minimum offset of 3 minutes from review launch, to allow GitLab API propagation)
   - **Any review PR reaches `errored`** → surface to operator before launching address
   - **Timeout after 20 minutes** → launch address runner anyway (review may be stuck; address session's watermark/skip logic handles the no-new-comments case gracefully)
   - This replaces the fixed offset sleep — a review that finishes in 5 minutes triggers address at 5 minutes instead of waiting a fixed 3 minutes, and a 15-minute review doesn't launch address prematurely at 3 minutes when there's nothing to address yet.
3. Update each run's status to `"active"` in session manifest.
4. Present the initial monitoring table (full table, per playbook format).

## Phase 4: Monitor Loop

Enter the monitoring loop. Continue until all runs converge or the operator ends the session.

**Each pass:**

1. **Read state.** For each active run, read the tail of each `<run_dir>/*/live.md` (last 10 lines) and each `<run_dir>/*/status.md`. Build the unified monitoring table per the playbook's Monitoring Table Format.

2. **Check intervention triggers** per the playbook's Director Intervention table. For clear cases (stale >5min, permission denial wall), act: kill the session via `session.pid` and write the appropriate directive. For ambiguous cases, escalate to the operator with your assessment and recommendation.

3. **Check directive opportunities** per the playbook's Directive Patterns. Write directives when triggered — summary-only findings and conflict resolution are the most common.

4. **Evaluate convergence** per the playbook's Convergence Rules for each run. When a runner completes (background task notification), decide: relaunch (not converged) or mark converged. Compound mode maintains offset cadence on relaunch.

5. **Present** the monitoring table and any actions taken. First pass: full table. Subsequent: delta-only with "N unchanged" summary.

**Pace**: 2-3 minutes between passes during active sessions.

**Escalation over automation**: when in doubt, present what you see, what you think it means, and what you'd recommend. The operator decides. As trust is established, the operator may cede more judgment — respect the current escalation level.

## Phase 5: Convergence + Wrap-up

1. Mark converged runs in `session.json` (`"status": "converged"`).
2. Session ends when all runs converge.
3. Write final `director-state.md` per playbook format with terminal state.
4. Present a final summary: per-run retro (read each run's `*/result.md` and `*/learnings.md`).
5. Offer to invoke `/session-retro` if the session was substantial.
