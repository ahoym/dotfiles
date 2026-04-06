Director-layer gotchas and operational decisions not covered by reference files. For the operationalized patterns, see `~/.claude/skill-references/director-playbook.md`, `artifact-contract.md`, and `sweep-scaffold.md`.
- **Keywords:** director, manager, directives, sweep, claude -p, permissions, gotchas, state.md, inactivity, retry, manifest-updates, three-channel
- **Related:** ~/.claude/learnings/claude-code/multi-agent/orchestration.md

---

## Director-as-Supervisor Paradigm

Three orchestration patterns exist, each with different tradeoffs:

| Pattern | Workers | Communication | Visibility |
|---------|---------|---------------|------------|
| Single agent | Self | n/a | Full |
| Agent tool subagents | In-memory children | Return values, SendMessage | Partial |
| **Director + parallel `claude -p`** | Independent OS processes | Files (live.md, directives, status) | Full via stream-monitor |

The director pattern is unique: the agent generates infrastructure (bash scripts), not code. It writes runner scripts that create a fleet of `claude -p` workers, then shifts into a monitoring/steering role.

## Quick Rerun Without Regenerating

When only a subset of work items need updated prompts (e.g., to add the directives step), edit `pr-<N>/prompt.txt` in-place rather than re-running the sweep skill. Avoids creating a new run directory and preserves existing artifacts. Regeneration is better when the template changed substantially or all items need new prompts.

## Skip Confirmation in Sweep Skills

Sweep skills should present the assessment summary table (for visibility) but proceed directly to artifact generation without prompting for confirmation. Operator curates by passing specific PR numbers (`/sweep-review-prs #49 #47`), not by interactive exclusion after assessment.

## Director Local State During Worktree Pushes

When worktree agents push commits to the director's active branch, `git pull` fails if the director has uncommitted local changes. Use `git stash && git pull --ff-only && git stash pop` to sync. Expect this whenever mixing local edits with agent-pushed commits on the same branch.

## Permissions for Sweep Sessions

`claude -p` sessions with `--allowedTools` need explicit `Read` patterns for the run directory (e.g., `Read(~/**/tmp/sweep-reviews/**)`). Without it, the session may not be able to read `status.md` watermarks, `directives.md`, or prior `result.md` sections. `Write` and `Edit` patterns do not imply `Read` access.

## `claude -p` Skill Tool Requires `Skill(*)` Permission

The Skill tool IS available in `claude -p` sessions — a permission denial is not the same as tool unavailability. Add `Skill(*)` to `~/.claude/settings.json` `permissions.allow`. Without it, `claude -p` sessions silently fail when trying to invoke skills (the session completes with `success` but produces no work).

## `--output-format stream-json` Requires `--verbose` with `claude -p`

`claude -p --output-format stream-json` fails with "Error: When using --print, --output-format=stream-json requires --verbose." The error goes to stderr and the session exits immediately — `status.md` stays at `launching`, output log is empty, and the runner reports success (exit 0). Use `claude -p --verbose --output-format stream-json`.

## Sweep Prereqs Must Be Platform-Aware

Sweep skill prerequisite patterns are platform-specific (`gh pr view:*` vs `glab mr view:*`). Hardcoding GitHub patterns causes the prereq check to either pass vacuously on GitLab or miss the actual `glab` patterns needed. Detect platform first, then check the corresponding CLI patterns.

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

## Incremental Manifest Updates

`manifest-updates.json` (append-only JSONL) supports adding/removing items without regenerating the full artifact structure. The runner reads it once on relaunch (not mid-run), applying `add` (new items with prompt.txt ready) and `close` (writes terminal status.md so pre-flight skips). The director writes updates between cycles; sweep skills don't need to be re-invoked for routine changes.

## Rate-Limit Sentinel Persists Across Reruns

`let-it-rip.sh` creates `.rate-limited` in the run directory when any session hits limits. On rerun, all sessions skip immediately without even trying. Clear manually (`rm <RUN_DIR>/.rate-limited`) before retrying.

## Sweeper Footer Regex Must Handle Markdown Italics

The Sweeper footnote renders as `*Role:* Sweeper` (markdown italics). Use `Role.*Sweeper` (no colon in pattern) to match both plain and italic forms. Same for `Sweeper-Confirm`.

## Directives to Running Agents Are Timing-Dependent

Writing `directives.md` after launch only works if the agent hasn't passed Step 2 yet. Mitigation: re-check directives before the implement step (not just at startup), or kill + relaunch.

## Worktree Creation From Checked-Out Branch

`git worktree add <path> main` fails when the main repo is on `main`. Use `origin/main --detach` instead, then `git checkout -b <branch>` in the worktree.
