Observability primitives for the director: how `claude -p` worker state surfaces back to the orchestrator.
- **Keywords:** observability, stream-json, live.md, state.md, status.md, three-channel, inactivity, sweep-status.sh
- **Related:** runner-design.md, failure-modes.md

---

## Three-Channel Director Interface

The director communicates through three distinct channels, not two:

| Direction | Channel | Medium | Timing |
|-----------|---------|--------|--------|
| Down | Directives | Files (append-only) | Between cycles |
| Up | Status | Files (overwrite) | Post-completion |
| Sideways | Kill + live observation | OS signal + file reads | During execution |

The "during execution" channels break the batch model. The runner-owned lifecycle refactor reduces the sideways reach by moving inactivity detection and retry to bash.

## Separate state.md (Runner) from status.md (Session)

`state.md` is runner-written (process lifecycle: running/retrying/errored/completed). `status.md` is session-written (domain state: watermarks, milestones, PR state, mergeable). Different authorities own different files at different times. The runner knows process facts (PID alive? exit code? last activity?); the session knows domain facts (what SHA did I review?).

## Inactivity Timeout Over Elapsed-Time Timeout

Active sessions that take long are valid; silence is the failure signal. Use `live.md` mtime as the inactivity clock — `stream-monitor.sh` appends on every stream-json event (tool calls, results, etc.), so a stale mtime means genuinely stuck, not just thinking. Default: 10 minutes, configurable via runner template placeholder.

## `--output-format stream-json` Requires `--verbose` with `claude -p`

`claude -p --output-format stream-json` fails with "Error: When using --print, --output-format=stream-json requires --verbose." The error goes to stderr and the session exits immediately — `status.md` stays at `launching`, output log is empty, and the runner reports success (exit 0). Use `claude -p --verbose --output-format stream-json`.

## Use `sweep-status-summary.sh` for Status Checks

`~/.claude/skill-references/sweep-status-summary.sh` exists for reading run directory status. Use it instead of ad-hoc Bash `for` loops or `cat` commands, which trigger permission prompts (they don't match single-command patterns like `Bash(gh pr view:*)`). The script matches `Bash(bash ~/.claude/skill-references/**)` and outputs a formatted per-item section dump that the director parses into the monitoring table.

## Reviewer Convergence-Cycle Skips `results.md` Append

When a `sweep:review-prs` re-review cycle's only outcome is "verified, 0 new findings" — no inline comments posted, no thread replies — the reviewer prompt updates `status.md` (`milestone: posted`, `last_reviewed_sha` advanced) but does NOT append a section to `results.md`. The director sees convergence via `status.md` + the GitHub review body, but the per-cycle audit trail is incomplete; cross-cycle finding-history reconstruction has to go to GitHub directly.

Fix lives in `~/.claude/commands/sweep/review-prs/reviewer-prompt.md`: the results.md append step should fire unconditionally, with body *"Re-review verified — 0 new findings on `<sha>`"* when convergence is the outcome. Symptom check: `wc -l <run_dir>/<pr>/results.md` after a converged re-review should grow by ≥1 section vs the prior cycle.
