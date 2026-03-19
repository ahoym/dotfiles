# Ralph Loop

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

## Consolidation Loop Variant

The consolidation loop (`/ralph:consolidate:init`) is a ralph-style autonomous loop specialized for learnings curation. Key differences from the research loop:

- **Security hooks**: Bash restricted to git allowlist (rm, add, mv, commit, status, diff — scoped to `claude/`); WebFetch, WebSearch blocked; writes scoped to `claude/` only. wiggum.sh validates sweep count delta after each invocation.
- **Single-pass broad sweep**: LEARNINGS → SKILLS → GUIDELINES (one each), then deep dives. No convergence rounds — cross-type regressions are rare and deep dives provide defense-in-depth.
- **Autonomous MEDIUM judgment**: Agent decides HIGHs and MEDIUMs autonomously; LOWs + blocked MEDIUMs surface via `review.md`.
- **Compounded learnings**: After sweeps with findings, agent compounds meta-insights into the corpus (worktree `claude/` paths). These become corpus changes evaluated by deep dives and subsequent runs.

## Research Output Pipeline: staged-learnings

Research output goes to `docs/staged-learnings/<project>/` inside the worktree — not `docs/learnings/`. The naming creates an explicit pipeline: research produces staged learnings that can later be filtered/promoted into `docs/learnings/`. This separates raw research artifacts from curated knowledge.

## Pre-Flight Cadence Analysis

Count curation-related commits in recent git history to right-size iteration counts. Recent curation (3+ of last 5 commits) → suggest fewer iterations (corpus likely clean). Stale (0 of last 5) → suggest full sweep. Avoids wasting iterations on corpora that were just curated.

**Known limitation:** The heuristic matches commit message keywords (e.g., "consolidat"), not actual corpus file changes. Meta-tooling commits ("Improve consolidation loop") inflate the curation count without cleaning the corpus. Overshooting iterations is preferred to undershooting (cheap clean sweeps vs missed findings), so this is acceptable.

## Small Files Gravitate Toward Larger Domain Files

Standalone reference files risk orphaning when a larger file in the same domain independently accumulates the same patterns with more context. Example: all 3 patterns from `research-methodology.md` were re-discovered and expanded in `claude-authoring-skills.md`, making the small file fully redundant. This is a natural corpus decay vector — the consolidation loop detects it, but it explains why thin files tend to need folding over time.

## Nested Skill Glob Pattern

`commands/*/SKILL.md` only matches top-level skill directories. For repos with multi-level nesting (e.g., `commands/ralph/consolidate/init/SKILL.md`), use `commands/**/SKILL.md`. This applies anywhere skills are inventoried — init pre-flight, spec corpus definitions, sweep methodology.

## Convergence as Safety Net for Compounding

Compounded insights go directly into the sweep corpus (worktree's `claude/learnings/`, guidelines, or skills) rather than a staging file. The round-based convergence mechanism (a clean round) is the circuit breaker — if compounding introduces issues, they surface as findings in the next sweep, resetting the clean streak. This trades isolation for directness: no post-loop `/learnings:compound` step needed, but the loop may take an extra round to re-converge if a compounded insight needs adjustment.

## Inline Compounding Over Skill Invocation in Autonomous Loops

When an autonomous agent needs to compound learnings mid-loop, inline the compound methodology rather than invoking `/learnings:compound` via the Skill tool. The agent already has the required tools (Read, Glob, Grep, Edit, Write) and the judgment context from the sweep it just completed. The compound skill adds: Skill tool dependency (may be hook-blocked), `~/.claude/` path assumptions (wrong in worktrees), AskUserQuestion (no user present), and ~120 lines of context per invocation. None of these are needed.

The inline methodology: categorize insights using `claude-authoring-content-types.md` (Skill/Guideline/Learning), assign utility (High/Medium/Low), dedup-grep target directory before creating, write to worktree `claude/` paths, log what was compounded in `decisions.md`. Compounded files are corpus changes — deep dives and subsequent consolidation runs evaluate them.

## Personas as Execution-Mode Learnings Conduit

The implementation-start gate only checks personas, not learnings directly. This is intentional: well-wired personas have "Detailed references" sections pointing to relevant learnings. Setting the persona *is* the learnings trigger for execution — the agent loads the persona, sees the references, and pulls knowledge just-in-time. Direct learnings search happens at session start and plan-mode entry; by execution time, the persona layer handles it.

## One-Action-Per-Invocation Enforcement

Stateless agents may violate one-action-per-invocation constraints when the action is trivially clean — they "helpfully" continue to the next action. Fix: **belt and suspenders.** Strengthen spec language (dedicated section with rationale, explicit "STOP") AND add outer-loop state validation (wiggum.sh reads SWEEP_COUNT pre/post, asserts delta = 1).

Spec change reduces frequency; validation catches it when it happens anyway. On violation: log WARNING but continue (work is already done, aborting mid-loop leaves inconsistent state). Without validation, numbering divergence is silent — only discoverable by reading log contents vs filenames.

## Worktree-Aware File Editing

When editing files from a worktree context, use the worktree's absolute path (e.g., `claude/worktrees/consolidate-2026-02-28/claude/learnings/foo.md`), not the main repo path that `~/.claude/` symlinks resolve to. Both are valid filesystem paths on disk, but they target different git branches. Editing via `~/.claude/learnings/foo.md` modifies main's copy; editing via the worktree path modifies the branch's copy. The Edit/Write tools won't warn you — the file exists at both paths.

**Explore agents in worktrees.** When launching an Explore agent from a worktree, include the worktree absolute path in the prompt and instruct it to return paths relative to that CWD (e.g., "CWD is `/path/to/worktree/`, return all paths relative to it"). Otherwise the agent resolves to main-repo absolute paths, and editing those puts changes on the wrong branch — requiring copy-to-worktree + revert-main cleanup.

## Worktree Commit-to-Main Workflow

When working in a worktree and the user wants changes on main, apply directly to the main repo (`git -C <main-repo-path>`) rather than commit-on-branch then cherry-pick. Cherry-picking requires stashing main's uncommitted changes first, and stash-pop conflicts are likely when main has dirty state on the same files. Direct application avoids the stash/cherry-pick/conflict-resolution chain entirely.

## Diagnosing Iteration Count Divergence

When outer-loop iteration count diverges from agent sweep count (e.g., 8 log files but agent reports 9 sweeps), check log *contents* against log *filenames*. The root cause is likely the agent doing multiple actions per invocation — not a missing log file or race condition. In the observed case, `iteration_2.log` contained "Iteration 3 complete" — the agent did sweeps 2+3 in wiggum's iteration 2.

## Defect Mode vs Opportunity Mode in Curation

Curation systems that only find defects (duplicates, staleness, project-specific content, broken references) miss optimization opportunities. The distinction:

- **Defect mode**: "Is anything wrong here?" — duplicates, overlaps, stale content, misplaced files
- **Opportunity mode**: "Could this be better?" — merges for cohesion, splits for discoverability, compression for token ROI, reference wiring, persona de-enrichment

Both need explicit methodology in the spec. Defect mode has clear confidence levels (a duplicate is a duplicate). Opportunity mode is inherently more subjective — classify as MEDIUM auto-apply when reversible (content moves, not lost). Without explicit opportunity methodology, the agent concludes "clean" when nothing is broken, even when the corpus could be meaningfully improved.

## Brief as Pre-PR Workflow

`/ralph:brief` naturally surfaces cleanup work before creating a PR for a research branch. Loading all core files into context reveals: superseded v1 directories to compare and clean up, unique content to port between versions, open questions to document in the PR. Use brief → compare → port → PR as a natural completion sequence.

## Runner-Spec Signal Contract

Two failure modes in sentinel-based loop control:

1. **False positives**: `grep -q` matches sentinels (e.g., `WOOT_COMPLETE_WOOT`) embedded in prose, not just as stop signals. Fix: use `grep -qx` (exact line match). Root cause is predictable — stateless agents will eventually write sentinels speculatively in notes.

2. **Missing signal checks**: When adding stop signals to a spec (e.g., `MAX_DEEP_DIVES_HIT`), verify the runner checks for all signals. If the runner only checks the original signal, new signals cause the agent to stop but the runner to keep launching until the stalled detector kicks in.

## Deep Dive Carryover and MAX_DEEP_DIVES_HIT

`MAX_DEEP_DIVES_HIT` is a completion signal — treat it like `COMPLETE` for resume purposes. Remaining candidates are staleness-eligible files awaiting periodic review (qualified via `run_count - last_deep_dive_run >= threshold`), not incomplete work from the current run. Relaunching is optional (they'll be picked up next run with higher priority). The resume skill should offer the merge path, noting what carries over.

## Resume Decision vs Action Ambiguity

The consolidation agent misinterpreted a resume commit (which recorded human decisions in progress.md notes) as having already applied the L-2 extraction. This caused it to verify stability of changes that never happened, then report "clean."

**Fix**: Notes for resume decisions must clearly distinguish state. Use explicit phrasing like "decision recorded, action pending — apply during next LEARNINGS sweep" rather than just stating the resolution. The agent reads Notes literally and will treat "RESOLVED — extract shared gotchas" as "already extracted."

## Stacked Gate Diagnosis for Autonomous Agent Output

When an autonomous agent fails to produce expected output despite qualifying conditions, diagnose which gate blocked: structural (spec rules) vs behavioral (agent judgment/prompting). Example: compounding produced zero insights even on action sweeps — the spec gate (only after HIGHs/MEDIUMs) was correct, but the agent's judgment gate (novelty threshold for what counts as an insight) was too high. Fix was prompting within the gate, not changing the gate itself.

## Broad Sweep Per-Pattern Blind Spot

Cluster-level analysis can't catch per-pattern duplicates when: (a) headings use different wording for the same concept (no collision), (b) the duplicate lives in a different cluster's file, and (c) the source file is medium-sized (not thin enough to fold, not large enough to auto-flag). This is the gap that per-file content-mode curation (deep dives) fills — it cross-references each pattern against the full corpus, catching duplicates that cluster-level thematic matching misses.

## Failure Diagnostics in Outer Loops

When an outer-loop iteration produces a 0 sweep-count delta, the log should capture the agent's stdout, not just the post-hoc validation warning. Without this, post-run analysis identifies *that* failures occurred (via log timestamps and delta checks) but not *why*. Current `wiggum.sh` logs only the warning line — the agent's actual output is lost.

## Track Assumptions with Confidence Levels in Iterative Research

When running multi-iteration research (ralph loops, deep dives), explicitly log assumptions with confidence ratings (High/Medium/Low) and a validation tracker table. This prevents later iterations from re-investigating settled questions or proceeding on shaky foundations. Format: assumption statement, confidence level, whether validated, and resolution. Cross-reference assumptions from the ID (A1, A2...) in other documents.

## Absence of Documentation ≠ Absence of Feature

When docs describe a feature only in the context of X (e.g., "auto-discovery works with `skills/`"), do NOT conclude that Y (e.g., `commands/`) lacks the feature. Silence is not exclusion. Require **explicit** evidence — a statement like "X does not support Y" — before claiming a capability difference. If the docs also contain a general equivalence statement (e.g., "both work the same way"), that should be the default position until contradicted.

**When asserting "X can't do Y":** actively search for evidence that X *can* do Y before committing to the claim. This is the adversarial/red-team step that catches false negatives.

## Broaden Primary Source Coverage in Research

Don't rely on a single doc page. When researching a feature area, traverse **related** official pages (e.g., researching skills? also read plugins, settings, reference docs). Key findings often live on adjacent pages — e.g., the plugin structure table that confirmed `commands/` support was on the plugins page, not the skills page.

## Validate Factual Claims About Runtime Behavior

Research that asserts capability differences (e.g., "directory X supports feature Y but directory Z doesn't") should be validated empirically when possible, not just inferred from docs. If the research loop constraints prevent code execution, flag the claim as **low-confidence/unverified** and note that empirical testing is needed before acting on it.

## Skill-as-Methodology for Autonomous Agents

Autonomous agents (`claude --print`) can't invoke the Skill tool, but they can read a SKILL.md file and follow its steps as inline methodology. Override only the interactive steps (AskUserQuestion → auto-apply, report generation → skip, results → skip). The skill drives classification, cross-referencing, and analysis; the spec provides the autonomous overrides. When the skill evolves, the agent gets improvements for free.

## Lazy-Load Phase-Specific Methodology in Specs

Stateless agent specs benefit from splitting phase-specific methodology into separate files loaded on-demand. The core spec (constraints, workflow, transitions) stays as the prompt; the agent reads the relevant methodology file only when entering that phase. Keep shared decision criteria (e.g., candidacy rules referenced by multiple phases) in core — only extract sections used exclusively by one phase.

## "Validate" Means Run It

When asked to validate that scripts/workflows work, **execute them** — don't just lint. Static analysis (`bash -n`, file existence checks, cross-reference verification) catches structural issues but misses runtime bugs: wrong env values, ordering problems, integration failures. Default escalation: syntax check → dry-run (if available) → actual execution. Only stop at static analysis if execution is explicitly impossible or the user says so.

When creating docs that mirror code-defined data (enums, config, topology), run the source code to validate claims programmatically. Counting items, listing values, or computing derived facts via `poetry run python3 -c "..."` catches misclassifications that manual review misses.

## Confidence Calibration Diagnostic for Autonomous Loops

When an autonomous loop produces zero items at a classification level (e.g., zero LOWs across all iterations), diagnose whether it's genuine clarity or systematic under-reporting:

1. **Audit the level above**: Check MEDIUM decisions for borderline calls that should have been LOWs. Were any "auto-applied" where the rationale required non-trivial judgment?
2. **Check the classification funnel**: Count action types per level. If the auto-apply bucket has 14 action types and the block/escalate bucket has 4, the funnel structurally prevents items from reaching the lower level.
3. **Spot-check "clean" items**: Pick 2-3 files the agent called clean and review manually. If a human finds things the agent missed, the agent is resolving ambiguity silently rather than surfacing it.

## Edit Templates, Not Output Copies

Consolidation output files (`claude/consolidate-output/spec.md`, `deep-dive-methodology.md`, etc.) are copies scaffolded from `~/.claude/ralph/consolidate/templates/` at init time. To change loop behavior globally (e.g., bump max guard), edit the templates — not the current run's copies. The current run's copies are ephemeral state owned by the loop; editing them mid-run is fragile and won't persist to future runs.

## Strip Consolidate-Output from PR Branches

`claude/consolidate-output/` files (spec, progress, decisions, blockers, report, lows, iteration logs) are working artifacts — they track loop state, not deliverables. The actual value of a consolidation branch is the edits to learnings, guidelines, skills, and personas.

Before creating a PR, strip working state from the branch while preserving local copies: `git rm --cached -r claude/consolidate-output/` (removes from git index, keeps on disk). Add `claude/consolidate-output/` to `.gitignore` to prevent re-staging. For untracked logs (iterations after last commit), no git action needed — they're already local-only.

## Gotchas Files Are Not Thin Files

`*-gotchas.md` files must never be merged into their parent domain files (e.g., `spring-boot-gotchas.md` → `spring-boot.md`) during consolidation sweeps. They serve different architectural roles: gotchas files are small, cheap proactive-load files loaded on every persona activation; parent learnings files are larger detailed references loaded on-demand. A thin gotchas file (2-4 bullets) is working as designed, not a merge candidate. The consolidation spec's thin-file heuristic must explicitly exclude `*-gotchas.md` files.

## Resume Should Check for Uncommitted Deep-Dive Changes

The resume skill should run `git status` before cleanup and check for uncommitted modifications from the deep-dive phase. Deep-dive iterations may leave changes that weren't committed by the autonomous agent (e.g., agent-prompting compression, new learnings sections). These need to be committed before `git rm -r consolidate-output/` to avoid losing work or creating a confusing commit history.

## Retro → Compound → Curate as Search Protocol Feedback Loop

The existing retro → compound → curate pipeline provides search protocol performance feedback without needing a dedicated log file. Session retro reviews which learnings were loaded and whether they influenced the work. Compound captures insights ("this file keeps being noise," "this domain had no match"). Curate reads those insights and restructures files accordingly. The signal is qualitative (prose) rather than quantitative (tallies), but curation doesn't need quantitative precision to act.

## Unreferenced Learnings Are Not Orphans

Not every learning file needs a persona Detailed reference. Context-aware learnings (`context-aware-learnings.md` guideline) discovers files by filename matching at session start and on keyword triggers — no persona wiring required. Only add a learning to a persona's Detailed references when it's highly correlated with the domain (most sessions with that persona would benefit). Niche learnings (e.g., `local-dev-seeding.md`) work better as context-aware discoveries — they get loaded when the topic actually comes up, not on every persona activation. During consolidation sweeps, do NOT wire learnings into personas just because they're unreferenced.

## Consolidation Worktree Hooks Auto-Commit and Can Revert

The consolidation worktree has guard hooks that auto-commit changes and can revert uncommitted modifications to match the last committed state. When making multiple sequential changes in an interactive session, commit after each logical change — don't batch. Uncommitted changes between tool calls may be silently reverted by hooks, requiring the work to be redone.

## Interactive-Autonomous Tracker Coordination

`/learnings:curate` (interactive) and the consolidation loop (autonomous) both review corpus files. After interactive curation, update the deep-dive tracker (`~/.claude/ralph/consolidate/deep-dive-tracker.json`) by setting `last_deep_dive_run = current run_count` for the curated file. This prevents the next consolidation run from queueing files for deep dives that were just manually reviewed.


## Session-Start Learnings Search Is Noisy for Consolidation Reviews

When evaluating a consolidation run, every file the loop touched appears in recent commit messages. The session-start learnings search matches those commit messages, loading files that are irrelevant to the *evaluation* task (e.g., `multi-agent-patterns.md` loaded because the loop edited it, not because the review session needed multi-agent knowledge). Low cost per false positive (~500 tokens), but worth noting as a known noise vector.

## Rate Limit Detection in Outer Loops

Outer loops (wiggum.sh) should grep agent output for known failure messages (e.g., "hit your limit") and exit immediately rather than retrying. Without this, the loop burns through remaining iterations on predictable failures — the rate limit won't clear mid-loop. The sweep-count delta check (expected 1, got 0) logs a warning but doesn't stop the loop; the rate limit check should.

## Issue Simplicity Heuristic for Implementer Loops

"Simple" = low-judgment, regardless of surface area. A 30-file mechanical rename is simpler than a 3-file architectural decision. Criteria:

- **In**: issue body contains enough context to execute without questions; clear done state; no external dependencies
- **Out**: requires design decisions not in the issue; requires empirical testing against external systems; body says "research"/"investigate"/"explore" without a concrete action plan

File count and cross-cutting scope don't disqualify — only judgment requirements do.

## Recovering from Partial Iteration State

When wiggum.sh errors leave partial state (progress.md updated but no commit), `git reset --hard <last-successful-commit>` is the cleanest recovery. Partial iterations can leave tracker gaps (files marked "done" in progress.md but missing from deep-dive-tracker.json) and decisions.md holes. Resetting to the last committed checkpoint ensures all state files are consistent. The lost iterations are cheap to redo — clean deep dives take ~3 minutes each.

**Diagnosis**: Check `git log --oneline -1` vs progress.md SWEEP_COUNT. If progress.md is ahead of the commit log, the last N iterations partially executed but didn't commit.

## LOW Review Items Require Human Judgment

All `[L-N]` items in `review.md` are human judgment items — even the ones that appear trivially fixable (wrong step number in a skill, stale description, etc.). The LOW tag signals that the autonomous loop deferred to the operator, not that the change is low-stakes. During `/ralph:consolidate:resume`, always use `AskUserQuestion` for every LOW before acting. Autonomously fixing any LOW bypasses the deferral that was intentionally placed there.

## Worktree Claude Config Location

The per-worktree claude config lives at `claude/worktrees/<name>/claude/` — not `~/.claude/worktrees/<name>/`. The `claude/` subdirectory is nested *inside* the worktree directory, not at the `~/.claude/` level. When editing worktree-specific persona files, commands, or guidelines, the absolute path is `/Users/<user>/WORKSPACE/<repo>/claude/worktrees/<name>/claude/<path>`.

## All Content Type Runs Are Roughly Equal Length

`min_deep_dives` (default 20) backfills small corpus runs with stale files from the deep-dive tracker. A GUIDELINES run with 4 files still does 20 deep dives — 16 slots filled from the stalest tracked files across all types. When planning how many iterations to allocate, treat all content type runs as ~same length regardless of corpus size.

## Scaffolding Strategy: cp vs Read+Edit

Before choosing a scaffolding approach for init skills, audit each template for whether it's modified during initialization. Verbatim copies should use a single `cp` (or `cp *.md`) in Bash — reading them into context just to Write them back wastes tool calls and tokens. Only templates that need placeholder substitution or pre-flight data population warrant Read+Edit. The audit is quick (check the init steps for which files get modified) and the savings compound: N verbatim templates = 2N fewer tool calls (N Reads + N Writes → 1 `cp`).

## See also

- `~/.claude/commands/learnings/curate/curation-insights.md` — sweep calibration, classification heuristics, and compression targets that complement the curation methodology patterns here (defect vs opportunity mode, broad sweep blind spots)
- `~/.claude/learnings/claude-code.md` — worktree permission mismatches and path resolution mechanics underlying the worktree editing gotchas here
- `~/.claude/learnings/multi-agent-patterns.md` — multi-agent orchestration patterns that complement the stateless iteration and autonomous loop design here
