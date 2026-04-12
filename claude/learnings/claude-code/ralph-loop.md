Design patterns, operational gotchas, and convergence mechanics for the ralph autonomous research loop — resuming, state management, core files, research branches, stateless iteration, one-action enforcement, worktree mechanics, and runner-spec contracts.
- **Keywords:** ralph, wiggum, stateless agent, claude --print, progress.md, spec.md, convergence, worktree, sentinel, WOOT_COMPLETE_WOOT, MAX_DEEP_DIVES_HIT, runner-spec, one-action, diff-routed, keyword-index, graph-extension
- **Related:** none

---

## Resuming a Completed Loop

Each iteration is stateless — `claude --print` with no conversation history. Continuity is only through files on disk (`spec.md`, `progress.md`, output files).

## Stateless Iteration as Viewpoint Diversity

Fresh agents per iteration don't just provide fault tolerance — they provide viewpoint diversity. Each agent brings independent judgment to the same state, catching things a single continuous agent would miss (same dynamic as multiple code reviewers). This works because state files are the shared ground truth (facts), while interpretation (judgment) varies per agent. The prerequisite: state must be explicit in files so diversity of interpretation doesn't become diversity of state understanding.

`wiggum.sh` checks for `WOOT_COMPLETE_WOOT` in `progress.md` after every iteration. If present, the loop exits immediately. **To resume**: remove the completion signal, update pending tasks/answers, then re-run the script.

## Question Tracking in progress.md

Use `**ANSWER:**` prefix inline on answered questions rather than changing the section header (e.g., `(Answered)`). This keeps the "Questions Requiring User Input" header stable — new questions can be added below without conflicting with a header that implies everything is resolved. Agents distinguish answered vs unanswered by presence/absence of the `**ANSWER:**` prefix.

## Core Files

A ralph project's context lives in 5 core files:

- `spec.md` — topic definition, constraints, research workflow
- `progress.md` — status, completed/pending tasks, answered questions, notes, completion signal
- `info.md` — comprehensive research findings
- `assumptions-and-questions.md` — key decisions, assumptions, open items
- `implementation-plan.md` — phased action plan

Deep research files (`<topic>.md`) are supplementary — created when a research area exceeds ~200 lines in info.md.

## Always Check Research Branches

`/ralph:compare` (and any research review) must check `research/<topic>` branches via `git show`, not just the local filesystem. A project directory may appear empty locally (only boilerplate `spec.md` + `progress.md`) while the branch has the full research output — deep research files, iteration logs, codebase summaries, etc. Comparing only local files would incorrectly conclude "never started" and miss real work.

## Stateless Spec Design for Autonomous Agents

When writing a spec for `claude --print` agents with no conversation history, embed methodology inline — not just as file references. The agent can read reference files on the first iteration (when SWEEP_COUNT = 0), but subsequent iterations have no memory of what was read. The spec must be self-sufficient: inline enough analytical framework that later iterations can execute without re-reading references. Use "Notes for Next Iteration" in progress.md as the inter-iteration communication channel for condensed context.

## One-Action-Per-Invocation Enforcement

Stateless agents may violate one-action-per-invocation constraints when the action is trivially clean — they "helpfully" continue to the next action. Fix: **belt and suspenders.** Strengthen spec language (dedicated section with rationale, explicit "STOP") AND add outer-loop state validation (wiggum.sh reads SWEEP_COUNT pre/post, asserts delta = 1).

Spec change reduces frequency; validation catches it when it happens anyway. On violation: log WARNING but continue (work is already done, aborting mid-loop leaves inconsistent state). Without validation, numbering divergence is silent — only discoverable by reading log contents vs filenames.

## Worktree-Aware File Editing

When editing files from a worktree context, use the worktree's absolute path (e.g., `claude/worktrees/consolidate-2026-02-28/claude/learnings/foo.md`), not the main repo path that `~/.claude/` symlinks resolve to. Both are valid filesystem paths on disk, but they target different git branches. Editing via `~/.claude/learnings/foo.md` modifies main's copy; editing via the worktree path modifies the branch's copy. The Edit/Write tools won't warn you — the file exists at both paths.

**Explore agents in worktrees.** When launching an Explore agent from a worktree, include the worktree absolute path in the prompt and instruct it to return paths relative to that CWD (e.g., "CWD is `/path/to/worktree/`, return all paths relative to it"). Otherwise the agent resolves to main-repo absolute paths, and editing those puts changes on the wrong branch — requiring copy-to-worktree + revert-main cleanup.

## Worktree Commit-to-Main Workflow

When working in a worktree and the operator wants changes on main, apply directly to the main repo (`git -C <main-repo-path>`) rather than commit-on-branch then cherry-pick. Cherry-picking requires stashing main's uncommitted changes first, and stash-pop conflicts are likely when main has dirty state on the same files. Direct application avoids the stash/cherry-pick/conflict-resolution chain entirely.

## Diagnosing Iteration Count Divergence

When outer-loop iteration count diverges from agent sweep count (e.g., 8 log files but agent reports 9 sweeps), check log *contents* against log *filenames*. The root cause is likely the agent doing multiple actions per invocation — not a missing log file or race condition. In the observed case, `iteration_2.log` contained "Iteration 3 complete" — the agent did sweeps 2+3 in wiggum's iteration 2.

## Runner-Spec Signal Contract

Two failure modes in sentinel-based loop control:

1. **False positives**: `grep -q` matches sentinels (e.g., `WOOT_COMPLETE_WOOT`) embedded in prose, not just as stop signals. Fix: use `grep -qx` (exact line match). Root cause is predictable — stateless agents will eventually write sentinels speculatively in notes.

2. **Missing signal checks**: When adding stop signals to a spec (e.g., `MAX_DEEP_DIVES_HIT`), verify the runner checks for all signals. If the runner only checks the original signal, new signals cause the agent to stop but the runner to keep launching until the stalled detector kicks in.

## Deep Dive Carryover and MAX_DEEP_DIVES_HIT

`MAX_DEEP_DIVES_HIT` is a completion signal — treat it like `COMPLETE` for resume purposes. Remaining candidates are staleness-eligible files awaiting periodic review (qualified via `run_count - last_deep_dive_run >= threshold`), not incomplete work from the current run. Relaunching is optional (they'll be picked up next run with higher priority). The resume skill should offer the merge path, noting what carries over.

## Resume Decision vs Action Ambiguity

The consolidation agent misinterpreted a resume commit (which recorded operator decisions in progress.md notes) as having already applied the L-2 extraction. This caused it to verify stability of changes that never happened, then report "clean."

**Fix**: Notes for resume decisions must clearly distinguish state. Use explicit phrasing like "decision recorded, action pending — apply during next LEARNINGS sweep" rather than just stating the resolution. The agent reads Notes literally and will treat "RESOLVED — extract shared gotchas" as "already extracted."

## Stacked Gate Diagnosis for Autonomous Agent Output

When an autonomous agent fails to produce expected output despite qualifying conditions, diagnose which gate blocked: structural (spec rules) vs behavioral (agent judgment/prompting). Example: compounding produced zero insights even on action sweeps — the spec gate (only after HIGHs/MEDIUMs) was correct, but the agent's judgment gate (novelty threshold for what counts as an insight) was too high. Fix was prompting within the gate, not changing the gate itself.

## Failure Diagnostics in Outer Loops

When an outer-loop iteration produces a 0 sweep-count delta, the log should capture the agent's stdout, not just the post-hoc validation warning. Without this, post-run analysis identifies *that* failures occurred (via log timestamps and delta checks) but not *why*. Current `wiggum.sh` logs only the warning line — the agent's actual output is lost.

## Track Assumptions with Confidence Levels in Iterative Research

When running multi-iteration research (ralph loops, deep dives), explicitly log assumptions with confidence ratings (High/Medium/Low) and a validation tracker table. This prevents later iterations from re-investigating settled questions or proceeding on shaky foundations. Format: assumption statement, confidence level, whether validated, and resolution. Cross-reference assumptions from the ID (A1, A2...) in other documents.

## Edit Templates, Not Output Copies

Consolidation output files (`claude/consolidate-output/spec.md`, `deep-dive-methodology.md`, etc.) are copies scaffolded from `~/.claude/ralph/consolidate/templates/` at init time. To change loop behavior globally (e.g., bump max guard), edit the templates — not the current run's copies. The current run's copies are ephemeral state owned by the loop; editing them mid-run is fragile and won't persist to future runs.

## Rate Limit Detection in Outer Loops

Outer loops (wiggum.sh) should grep agent output for known failure messages (e.g., "hit your limit") and exit immediately rather than retrying. Without this, the loop burns through remaining iterations on predictable failures — the rate limit won't clear mid-loop. The sweep-count delta check (expected 1, got 0) logs a warning but doesn't stop the loop; the rate limit check should.

## Recovering from Partial Iteration State

When wiggum.sh errors leave partial state (progress.md updated but no commit), `git reset --hard <last-successful-commit>` is the cleanest recovery. Partial iterations can leave tracker gaps (files marked "done" in progress.md but missing from deep-dive-tracker.json) and decisions.md holes. Resetting to the last committed checkpoint ensures all state files are consistent. The lost iterations are cheap to redo — clean deep dives take ~3 minutes each.

**Diagnosis**: Check `git log --oneline -1` vs progress.md SWEEP_COUNT. If progress.md is ahead of the commit log, the last N iterations partially executed but didn't commit.

## Worktree Claude Config Location

The per-worktree claude config lives at `claude/worktrees/<name>/claude/` — not `~/.claude/worktrees/<name>/`. The `claude/` subdirectory is nested *inside* the worktree directory, not at the `~/.claude/` level. When editing worktree-specific persona files, commands, or guidelines, the absolute path is `/Users/<user>/WORKSPACE/<repo>/claude/worktrees/<name>/claude/<path>`.

## Scaffolding Strategy: cp vs Read+Edit

Before choosing a scaffolding approach for init skills, audit each template for whether it's modified during initialization. Verbatim copies should use a single `cp` (or `cp *.md`) in Bash — reading them into context just to Write them back wastes tool calls and tokens. Only templates that need placeholder substitution or pre-flight data population warrant Read+Edit. The audit is quick (check the init steps for which files get modified) and the savings compound: N verbatim templates = 2N fewer tool calls (N Reads + N Writes → 1 `cp`).

## Diff-Routed Curation Architecture

Full-corpus reads don't scale — token cost grows linearly with corpus size regardless of change volume. Replace with diff-routed curation: git diff identifies changed files, terms extracted from diff content route to relevant corpus slices via an inverted keyword index (`learnings/.keyword-index.json`), then graph extension follows cross-refs to impacted neighbors. Full reads become targeted, not exhaustive.

**Key components:** (1) inverted keyword index — derived from headers, rebuilt each run, maps terms to file paths; (2) git-diff scoping via `last_consolidation_commit` in tracker; (3) relevance-gated graph extension — follow cross-refs while headers match derived terms, no hard depth cap; (4) grouped curation — related files read in same subagent context for direct comparison, curated in one pass (no separate deep-dive re-read); (5) stale rotation for baseline coverage of unchanged files.

**Scaling:** effort proportional to change volume, not corpus size. A 200-file corpus with 3 changes reads the same ~15 files as an 80-file corpus with 3 changes. Design doc: `docs/plans/diff-routed-curation.md`.

## Cross-Refs

