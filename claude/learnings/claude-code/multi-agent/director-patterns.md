Director-layer gotchas and operational decisions not covered by reference files. For the operationalized patterns, see `~/.claude/skill-references/director-playbook.md`, `artifact-contract.md`, and `sweep-scaffold.md`.
- **Keywords:** director, manager, directives, sweep, claude -p, permissions, gotchas, state.md, inactivity, retry, manifest-updates, three-channel
- **Related:** none

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

Sweep skills should present the assessment summary table (for visibility) but proceed directly to artifact generation without prompting for confirmation. Operator curates by passing specific PR numbers (`/sweep:review-prs #49 #47`), not by interactive exclusion after assessment.

## Director Local State During Worktree Pushes

When worktree agents push commits to the director's active branch, `git pull` fails if the director has uncommitted local changes. Use `git stash && git pull --ff-only && git stash pop` to sync. Expect this whenever mixing local edits with agent-pushed commits on the same branch.

## Permissions for Sweep Sessions

`claude -p` sessions with `--allowedTools` need explicit `Read` patterns for the run directory (e.g., `Read(~/**/tmp/sweep-reviews/**)`). Without it, the session may not be able to read `status.md` watermarks, `directives.md`, or prior `results.md` sections. `Write` and `Edit` patterns do not imply `Read` access.

## `claude -p` Skill Tool Requires Scoped Permission

The Skill tool IS available in `claude -p` sessions and works for invoking skills (e.g., verified working: `git:resolve-conflicts`, `git:team-review-request`, `git:address-request-comments`). Add scoped patterns like `Skill(git:team-review-request *)` to `~/.claude/settings.json` `permissions.allow`. Without a matching pattern, `claude -p` sessions silently skip the Skill call (no permission denial in logs — the session just works around it by doing the work manually, often incorrectly). Prefer scoped patterns over `Skill(*)` to limit what headless sessions can invoke.

**`--allowedTools` override:** For `claude -p` sessions launched with `--allowedTools`, Skill patterns must also appear in the `--allowedTools` list — `permissions.allow` alone is insufficient. The `--allowedTools` flag is more restrictive: it defines the complete tool set, and global allow patterns don't override it.

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

## Post-Action Watermark Recording

Agents that post comments (clarifiers, confirmers) must record watermarks *after* posting, not before. The agent's own comment changes the issue's `updatedAt` and `last_comment_id` — recording pre-post values creates a perpetually stale watermark where every rerun sees "new activity" (its own prior post). Re-fetch `updatedAt` and `last_comment_id` after the `gh issue comment` call and use those values in `status.md`.

## Self-Comment Guard

Watermark diffs alone don't distinguish "human replied" from "agent posted last time." Before acting on a watermark mismatch, check whether the latest comment is from a sweeper role (`Role:.*Sweeper` or `Role:.*Sweeper-Confirm` in the comment body). If the latest comment is the agent's own and `status.md` shows `milestone: done`, skip — there's no new human input. This is defense-in-depth alongside the post-action watermark fix.

## Dual-Signal Watermark Comparison

Require both `last_comment_id` AND `updatedAt` to match before skipping a work item. Either signal alone has blind spots: `last_comment_id` misses body/label edits (which change `updatedAt` without adding comments), and `updatedAt` alone could miss propagation edge cases. The two signals cover each other — any mutation breaks at least one.

## Map Full Call Chain Before Patching One Layer

Multi-layer systems (assessment → runner → agent) can have the same bug manifest at multiple layers. Before fixing the first instance found, trace the full flow and identify all places the defense should exist. Patching one layer reactively leads to discovering the next gap only after testing — mapping upfront catches them in one pass.

## Deferred Runs Need Event-Triggered Reassessment

When a director defers a run ("no eligible items — reassess after X completes"), it records the reason but has no mechanism to auto-resume when the blocking condition clears. The next cycle requires manual re-invocation. Deferral reasons should map to observable events (new review comments posted, PR state change, issue reply) so the director can reassess without operator intervention.

## Pre-Filter Converged Items Before Launching Sweeps

Launching a sweep run for items that already converged wastes a full session startup (~30s + API cost) for a no-op quick-exit. The director should check convergence signals (HEAD SHA unchanged, no new comments since last review) before including items in the manifest. This is distinct from the runner's pre-flight skip — the director has cross-session state and can avoid generating artifacts entirely.

## Discovery During Clarify Doesn't Feed Back Into Scope

When a clarify pass discovers the actual blast radius differs from the plan (e.g., 7 files with references vs 4 originally listed), that finding lives only in the clarify output. Subsequent assessment and implement passes use the original scope. Directors should read clarify outputs and update the manifest's scope metadata so downstream passes inherit discoveries.

## Parallel Session Rate Limit Competition

Launching 4+ `claude -p` sessions simultaneously reliably exhausts API rate limits. The first 2-3 sessions complete; later ones hit limits mid-execution. Mitigations: lower concurrency (2-3 for heavy sessions like team reviews), stagger launches, or accept that reruns will be needed. The `.rate-limited` sentinel prevents wasted retries but must not overwrite completed sessions (see runner pre-flight order).

## Director State Is Mostly Computable; Only Decisions Need Logging

Most director-layer state is derivable from worker artifacts: cycle counts from `state.md` timestamps, convergence flags from `status.md` milestones, monitoring snapshots from synthesis. The genuinely uncomputable part is the *director's decision history* — `relaunched address at 14:51 because review found 4 findings`. Append decisions to `<RUN_DIR>/director-decisions.log` on non-routine events (relaunch, escalation, convergence call, directive write), not on a periodic clock. Natural agent behavior — write when something happens, not on a heartbeat. Same shape applies one tier up: a VP managing multiple directors reads each director's decision log + the workers' `state.md` files; no per-tier state file needed.

## Sweep Runner Model Selection: Orchestrator vs Leaf

Match the model to the runner's role. **Orchestrator runners** mainly invoke other skills/subagents (`sweep:review-prs` calling `git:team-review-request`, which spawns reviewer subagents) — `claude-sonnet-4-6` is fine because the heavy work is in the spawned children. **Leaf runners** do the actual work themselves: read diffs, edit files, run git, push commits (`sweep:address-prs`, `sweep:work-items` implementer) — use `claude-opus-4-6`. The runner template's `{{MODEL}}` placeholder is filled per-skill at let-it-rip generation. The `[1m]` variant only when context demands it (very large diffs, multi-file refactors).

## Active Intent Capture: Draft, Lock, Update

Capture intent at session start as a structured artifact (`<session_dir>/intents/<id>.md`), not as conversation context. Director drafts from item metadata, operator confirms or revises, result is locked. In-session scope expansion goes through an explicit update step (append revision section, log to `decisions.md`) — never silent mutation. The locked artifact survives context compaction and grounds decision-making: "is this in scope?" becomes a checkable question against the file, not a subjective recall.

## TOCTOU in Orchestration Pre-Filters

When an orchestration skill reads state at Phase N for an optimization decision (e.g., pre-filter unchanged items) and re-reads at Phase M for an authoritative decision (e.g., convergence check), items excluded at Phase N could have new activity by Phase M. Classic time-of-check/time-of-use applied to skill orchestration: either re-check excluded items at the authoritative phase, or accept that the optimization can miss state changes between phases.

## Runner Template Assumes PR Entity Type

The `parallel-claude-runner-template.sh` hardcodes `pr-<N>` directory naming, `gh pr view` pre-flight checks, and `pr_state:` status keys. Work-item sweeps using `issue-<N>` directories require post-generation patches: rename directories to `pr-<N>`, replace `gh pr view` with `gh issue view` in the pre-flight, and adjust terminal-state logic (issues only have `CLOSED`, not `MERGED`). A future template improvement could parameterize the entity type via metadata (`ENTITY_TYPE`, `ENTITY_PREFIX`, `STATE_CHECK_CMD`).

## Directors Orchestrate, Never Replicate

Directors must always invoke sweep skills for assessment — never generate artifacts directly, even when the director "already knows" the PR state and metadata schema. Direct generation bypasses platform detection, skip filtering, persona discovery, and the full assessment flow. The predictability cost outweighs the performance gain: deterministic director behavior enables layering a higher orchestration tier above. The sweep skill is the single source of truth for assessment logic; the director is the single source of truth for convergence and relaunch decisions.

## Decision Matrix Is Trust, Not Suggestion

When a decision falls within the documented matrix (routine, in-scope, taste-based), execute and report — don't ask. Prompting the operator for a decision the matrix already covers forces them to re-grant trust they already codified. The pattern "I see X, the matrix says Y, should I do Y?" is worse than just doing Y and saying "did Y because X." Uncertainty is fine for genuinely ambiguous cases, but conflict resolution, convergence calls, and directive writes are explicitly routine. The decision framework exists to empower autonomous action — defaulting to "ask the human" under context pressure negates its purpose. Route through the addresser via directives, not by doing the git work directly.

## Use `sweep-status.sh` for Status Checks

`~/.claude/skill-references/sweep-status.sh` exists for reading run directory status. Use it instead of ad-hoc Bash `for` loops or `cat` commands, which trigger permission prompts (they don't match single-command patterns like `Bash(gh pr view:*)`). The script matches `Bash(bash ~/.claude/skill-references/**)` and outputs a formatted table.

## Worktree EXIT Trap Destroys Uncommitted Implementer Work

The runner's `cleanup_worktrees` EXIT trap fires unconditionally — including when the session timed out before committing. All files written by `Write` tool to the worktree are lost. The branch persists locally (no commits, same as base), creating a second failure on relaunch: `git worktree add -b <branch>` fails because the branch already exists. The session can fall back to working in the project root, but the first run's work is unrecoverable. Mitigation options: (1) skip cleanup when `state.md` shows non-`completed` terminal state, (2) commit WIP before cleanup, (3) don't clean up implementer worktrees at all (current skill note: "Worktrees are preserved").

## Stale Branch Blocks Worktree Creation on Relaunch

`git worktree add -b <branch> <path> origin/main` fails when `<branch>` already exists locally from a prior timed-out run (worktree cleaned up but branch not deleted). The session falls back to working in the project root successfully — functional but bypasses worktree isolation. Fix: add `git branch -D <branch> 2>/dev/null` before `git worktree add -b` in the setup function, or use `--force` flag.

## Runner Pre-Flight: Entity Terminal States Only, Not Role Convergence

The runner's bash pre-flight skip should gate only on **entity terminal states** (`issue_state: CLOSED`, `pr_state: MERGED/CLOSED`) — never on role convergence signals (`comment_posted`, `pr_opened`, `confirmation_posted`). Convergence signals mean "this role's job is done for now," not "this entity is done." Adding them to pre-flight causes confirm/implement cycles to false-skip after the clarifier posts. The session's internal watermark logic handles "nothing new since last pass" — the runner's job is the cheap cost-optimization skip for truly terminal entities. Same boundary as `state.md` (runner) vs `status.md` (session): don't read session-domain signals in runner code.

## Missing `fill-template.sh` Keys Fail Silently

`fill-template.sh` has no defaults — missing keys in metadata.json leave raw `{KEY}` placeholders in the output. Worse: agents often reason around unresolved placeholders (inferring the intended command from context) rather than erroring. The session succeeds, but the pipeline is fragile. Every skill must explicitly provide every key its template references. Verify with `grep '\{[A-Z_]*\}' prompt.txt` after assembly — a clean run has zero matches.

## Standalone Worktree Agent for Bootstrap Infrastructure

When fixing infrastructure that the sweep flow itself depends on (e.g., the runner template), prefer `Agent(isolation: "worktree")` over generating sweep artifacts. The sweep flow would need to manually patch the very template being fixed — a chicken-and-egg. The worktree agent gets a clean checkout, implements from a fully-specified plan, and pushes a branch. The director still doesn't touch the working tree; the worktree agent is just a different execution vehicle than `claude -p` with metadata.json artifacts.

## Compose Escalation Through Existing Decision Frameworks

Secondary agents that need to escalate (verifier asking for clarification, validator finding ambiguity) should route through whatever decision framework already governs the primary loop — not build a parallel escalation channel. Verifier mid-run clarification flows through the same operator-cession framework the director uses (silent for routine, decide-with-report for partial, escalate to operator for ambiguous). Composability over duplication: one escalation surface for the operator to learn, one set of categories, one log location.

## Compound Findings Halve Per Cycle When Author Fixes Root Causes

Substantive PRs in compound review+address mode follow a predictable trajectory: findings count roughly halves each cycle (e.g., 10 → 5 → 0). Three cycles is typical for a PR with 3 HIGH findings; clean re-review (0 new findings) is the convergence signal. If findings don't shrink between cycles, the addresser is patching symptoms rather than root causes — write a directive or escalate.
