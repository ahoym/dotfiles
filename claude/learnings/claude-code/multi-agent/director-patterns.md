Director-layer patterns for multi-agent workflows — run lifecycle, inter-run communication, state management across stateless workers.
- **Keywords:** director, manager, directives, watermark, rerun, append-only, sweep, run lifecycle, inter-run, stateless workers, claude -p
- **Related:** ~/.claude/learnings/claude-code/multi-agent/orchestration.md

---

## Hierarchy

Director (operator + main agent) → Manager (`claude -p` session per work item) → Sub-agents (reviewer personas, addressers, etc.). Directors set strategy and steer; managers orchestrate a single work item; sub-agents execute specific tasks. Communication flows down via prompt templates and directives; results flow up via artifacts.

## Watermark-Based Rerun

`claude -p` sessions are stateless — they see existing artifacts (result.md, status.md) and may interpret them as "already done" rather than "prior run output." To make sweep scripts genuinely rerunnable:

**Watermark in status.md**: store `last_reviewed_sha` and `last_comment_id` (or equivalent) after each run. On next launch, compare watermark against current PR state via `gh`. Skip only if both match.

**Append-only artifacts**: `result.md` and `learnings.md` get a new dated section per run (`## Review — <ISO timestamp>`) rather than being overwritten. Each section is self-contained with its own table. Gives an audit trail across runs without directory nesting.

## Directives Channel

A `directives.md` file (global at `RUN_DIR/` and per-work-item at `PR_DIR/`) that directors write between runs. The prompt template reads directives before the watermark check; directives override skip logic even when watermarks match.

Solves the "no way to pass instructions down to running managers" problem. Either director (operator or main agent) can write to it. Format is dated entries, append-only:

```markdown
## <ISO timestamp>

<context and instructions for the manager>
```

## Composition

The three mechanisms compose: watermarks handle automatic change detection, append-only artifacts preserve history, and directives handle human-in-the-loop steering.

## Quick Rerun Without Regenerating

When only a subset of work items need updated prompts (e.g., to add the directives step), edit `pr-<N>/prompt.txt` in-place rather than re-running the sweep skill. Avoids creating a new run directory and preserves existing artifacts. Regeneration is better when the template changed substantially or all items need new prompts.

## Permissions for Sweep Sessions

`claude -p` sessions with `--allowedTools` need explicit `Read` patterns for the run directory (e.g., `Read(~/**/tmp/sweep-reviews/**)`). Without it, the session may not be able to read `status.md` watermarks, `directives.md`, or prior `result.md` sections. `Write` and `Edit` patterns for the same directory do not imply `Read` access. Add matching `Read` patterns to both the skill prerequisites and `settings.json`.

## Offset Loops for Tighter Convergence

When running review and address sweeps concurrently, offset their loop cadences (e.g., review at :00/:05/:10, address at :03/:08/:13). Same-time firing wastes a full cycle on handoff — review posts findings that the concurrent address sweep misses until the next cycle. A 3m offset cuts the review→address→review handoff from ~10m to ~5m.

## Pre-Flight State Check in Runner Scripts

`let-it-rip.sh` must check `gh pr view --json state` before launching each `claude -p` session. Merged/closed PRs skip without spinning up a process. For address mode with worktrees, the same check must also appear in the `setup_worktrees` loop — `git fetch` fails on merged branches before the launch loop's skip ever fires.

## Active-Branch PR Workaround

See `coordination.md` § "Agent Worktree Isolation for Active-Branch PRs" for the `Agent(isolation: "worktree")` workaround when `git worktree add` can't check out the director's active branch.

## Convergence Rules by Loop Type

Review and address loops have different termination conditions:
- **Review loop**: auto-cancel after 30m of all-skip inactivity (reviews are reactive to changes)
- **Address loop**: keep running while open PRs exist, even during all-skip. Main advancing can create merge conflicts on converged PRs at any time. Only auto-cancel when all PRs are terminal (merged/closed).

The address loop doubles as a conflict monitor — each cycle should read `mergeable` from review status.md files and write directives when CONFLICTING detected.

## Skip Confirmation in Sweep Skills

Sweep skills should present the assessment summary table (for visibility) but proceed directly to artifact generation without prompting for confirmation. Operator curates by passing specific PR numbers (`/sweep-review-prs #49 #47`), not by interactive exclusion after assessment. The confirmation gate adds friction with no value when the operator already specified their intent.

## Concurrent Review/Address Timing

When running review and address concurrently, the review sweep may skip if the address agent hasn't pushed its changes yet — the watermark still matches. This costs one extra cycle but is harmless. Mitigation options: offset start times (review first, address 3min later), or accept the extra cycle as normal operating mode. In practice, a single-PR sweep converges in 3-4 cycles regardless.

## Launch Review Before Address Assessment

After generating review sweep artifacts, launch `let-it-rip.sh` immediately — don't wait for address assessment to complete. The review sessions start working while the director assesses address candidates. Parallelizes cycle 0.

## Cross-Refs

- `~/.claude/learnings/claude-code/multi-agent/orchestration.md` — lower-level orchestration patterns (subagent synthesis, context compaction, runner templates)
- `~/.claude/learnings/claude-code/multi-agent/coordination.md` — worktree coordination, Agent isolation workaround
