# Ralph Loop

## Resuming a Completed Loop

Each iteration is stateless — `claude --print` with no conversation history. Continuity is only through files on disk (`spec.md`, `progress.md`, output files).

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

- **Output directory**: `.claude/consolidate-output/` (not `docs/learnings/<project>/`)
- **Output files**: 6 files (spec, progress, decisions, blockers, report, lows) instead of 5 core research files
- **Security hooks**: Bash restricted to selective git allowlist (rm, add, mv, commit, status, diff — scoped to `.claude/`); WebFetch, WebSearch blocked; writes scoped to `.claude/` only. wiggum.sh validates sweep count delta (expected 1) after each invocation.
- **Round-based progression**: Each round sweeps LEARNINGS → SKILLS → GUIDELINES (one each). Convergence = 2 consecutive clean rounds. Max 5 rounds before forced stop.
- **Autonomous MEDIUM judgment**: Agent decides HIGHs and MEDIUMs autonomously; only true blockers surface for human review via `blockers.md`
- **Compounded learnings**: After sweeps with findings, agent compounds meta-insights directly into the learnings system (worktree `.claude/` paths). These become corpus changes evaluated by subsequent sweeps via the convergence mechanism.
- **Runner**: `~/.claude/ralph/consolidate/wiggum.sh` (separate from the research `~/.claude/lab/ralph/wiggum.sh`)
- **Resume**: `/ralph:consolidate:resume` handles blocker resolution and relaunch (vs `/ralph:resume` for research question answering)

## Round-Based vs Type-Blocked Convergence

Type-blocked convergence (sweep type A twice, then type B twice) confirms each type in isolation — the "confirmation" sweep has no cross-type context. Round-based convergence (sweep A → B → C, then A → B → C again) means each type's confirmation sweep happens after all other types have been swept, catching cross-type regressions naturally. Also halves the minimum iteration count for clean corpora (6 vs 12 for 3 types × 2 confirmations).

## Pre-Flight Cadence Analysis

Count curation-related commits in recent git history to right-size iteration counts. Recent curation (3+ of last 5 commits) → suggest fewer iterations (corpus likely clean). Stale (0 of last 5) → suggest full sweep. Avoids wasting iterations on corpora that were just curated.

**Known limitation:** The heuristic matches commit message keywords (e.g., "consolidat"), not actual corpus file changes. Meta-tooling commits ("Improve consolidation loop") inflate the curation count without cleaning the corpus. Overshooting iterations is preferred to undershooting (cheap clean sweeps vs missed findings), so this is acceptable.

## Small Files Gravitate Toward Larger Domain Files

Standalone reference files risk orphaning when a larger file in the same domain independently accumulates the same patterns with more context. Example: all 3 patterns from `research-methodology.md` were re-discovered and expanded in `skill-design.md`, making the small file fully redundant. This is a natural corpus decay vector — the consolidation loop detects it, but it explains why thin files tend to need folding over time.

## Nested Skill Glob Pattern

`commands/*/SKILL.md` only matches top-level skill directories. For repos with multi-level nesting (e.g., `commands/ralph/consolidate/init/SKILL.md`), use `commands/**/SKILL.md`. This applies anywhere skills are inventoried — init pre-flight, spec corpus definitions, sweep methodology.

## Convergence as Safety Net for Compounding

Compounded insights go directly into the sweep corpus (worktree's `.claude/learnings/`, guidelines, or skills) rather than a staging file. The round-based convergence mechanism (2 consecutive clean rounds) is the circuit breaker — if compounding introduces issues, they surface as findings in the next sweep, resetting the clean streak. This trades isolation for directness: no post-loop `/learnings:compound` step needed, but the loop may take an extra round to re-converge if a compounded insight needs adjustment.

## Inline Compounding Over Skill Invocation in Autonomous Loops

When an autonomous agent needs to compound learnings mid-loop, inline the compound methodology rather than invoking `/learnings:compound` via the Skill tool. The agent already has the required tools (Read, Glob, Grep, Edit, Write) and the judgment context from the sweep it just completed. The compound skill adds: Skill tool dependency (may be hook-blocked), `~/.claude/` path assumptions (wrong in worktrees), AskUserQuestion (no user present), and ~120 lines of context per invocation. None of these are needed.

The inline methodology: categorize insights using `content-type-decisions.md` (Skill/Guideline/Learning), assign utility (High/Medium/Low), dedup-grep target directory before creating, write to worktree `.claude/` paths, log what was compounded in `decisions.md`. Compounded files are corpus changes — the next LEARNINGS sweep evaluates them naturally via the convergence mechanism.

## Personas as Execution-Mode Learnings Conduit

The implementation-start gate only checks personas, not learnings directly. This is intentional: well-wired personas have "Detailed references" sections pointing to relevant learnings. Setting the persona *is* the learnings trigger for execution — the agent loads the persona, sees the references, and pulls knowledge just-in-time. Direct learnings search happens at session start and plan-mode entry; by execution time, the persona layer handles it.

## One-Action-Per-Invocation Violations

Stateless agents may violate one-action-per-invocation constraints when the action is trivially clean — they "helpfully" continue to the next action in the same invocation. Observed in consolidation: agent did SKILLS sweep (clean), then immediately did GUIDELINES sweep instead of exiting. The spec said "one sweep per invocation" but it was a single bullet point — easy for the model to deprioritize when continuing seems efficient.

**Fix: belt and suspenders.** Strengthen spec language (dedicated section with rationale, explicit "STOP" instruction) AND add outer-loop state validation (read SWEEP_COUNT before/after, assert delta = 1). Spec change reduces frequency; validation catches it when it happens anyway.

## Post-Invocation State Validation

The outer loop (wiggum.sh) should read agent state before and after each invocation and assert expected deltas. For consolidation: read SWEEP_COUNT from progress.md pre/post, verify it incremented by exactly 1.

**Why**: Catches spec violations (double-sweep), provides infrastructure for future optimizations (e.g., fast-path skipping when no files changed), and maintains iteration-count parity between outer loop and agent. Without validation, numbering divergence is silent — only discoverable by reading log contents vs filenames.

**On violation**: log WARNING but continue (don't abort — work is already done, aborting mid-loop leaves inconsistent state).

## Worktree-Aware File Editing

When editing files from a worktree context, use the worktree's absolute path (e.g., `.claude/worktrees/consolidate-2026-02-28/.claude/learnings/foo.md`), not the main repo path that `~/.claude/` symlinks resolve to. Both are valid filesystem paths on disk, but they target different git branches. Editing via `~/.claude/learnings/foo.md` modifies main's copy; editing via the worktree path modifies the branch's copy. The Edit/Write tools won't warn you — the file exists at both paths.

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

## Sentinel Value False Positives in Signal Detection

`grep -q` matches a sentinel value (e.g., `WOOT_COMPLETE_WOOT`) anywhere in the file — including prose mentions in Notes for Next Iteration. Agents naturally write sentinels speculatively ("if clean, streak reaches 2 → WOOT_COMPLETE_WOOT"), triggering premature loop exit.

**Fix**: Use `grep -qx` (exact line match) instead of `grep -q`. This matches only when the sentinel is the entire content of a line, rejecting it when embedded in prose. Same applies to `MAX_ROUNDS_HIT` or any signal checked by the outer loop.

**Root cause is predictable**: stateless agents have no memory that their prose will be `grep`'d by the runner. Any sentinel value used as a signal by the outer loop will eventually appear in agent notes.

## Spec-Runner Signal Coherence

When adding stop signals to a spec (e.g., `MAX_DEEP_DIVES_HIT`), verify the runner script checks for all signals. The spec defines agent behavior (write signal, stop sweeping); the runner defines loop termination (grep for signal, exit). If the runner only checks the original signal (`WOOT_COMPLETE_WOOT`), new signals cause the agent to stop but the runner to keep launching iterations until the stalled detector kicks in.

## Resume Decision vs Action Ambiguity

The consolidation agent misinterpreted a resume commit (which recorded human decisions in progress.md notes) as having already applied the L-2 extraction. This caused it to verify stability of changes that never happened, then report "clean."

**Fix**: Notes for resume decisions must clearly distinguish state. Use explicit phrasing like "decision recorded, action pending — apply during next LEARNINGS sweep" rather than just stating the resolution. The agent reads Notes literally and will treat "RESOLVED — extract shared gotchas" as "already extracted."

## Stacked Gate Diagnosis for Autonomous Agent Output

When an autonomous agent fails to produce expected output despite qualifying conditions, diagnose which gate blocked: structural (spec rules) vs behavioral (agent judgment/prompting). Example: compounding produced zero insights even on action sweeps — the spec gate (only after HIGHs/MEDIUMs) was correct, but the agent's judgment gate (novelty threshold for what counts as an insight) was too high. Fix was prompting within the gate, not changing the gate itself.

## Broad Sweep Per-Pattern Blind Spot

Cluster-level analysis can't catch per-pattern duplicates when: (a) headings use different wording for the same concept (no collision), (b) the duplicate lives in a different cluster's file, and (c) the source file is medium-sized (not thin enough to fold, not large enough to auto-flag). This is the gap that per-file content-mode curation (deep dives) fills — it cross-references each pattern against the full corpus, catching duplicates that cluster-level thematic matching misses.

## Failure Diagnostics in Outer Loops

When an outer-loop iteration produces a 0 sweep-count delta, the log should capture the agent's stdout, not just the post-hoc validation warning. Without this, post-run analysis identifies *that* failures occurred (via log timestamps and delta checks) but not *why*. Current `wiggum.sh` logs only the warning line — the agent's actual output is lost.

<<<<<<< Updated upstream
## Track Assumptions with Confidence Levels in Iterative Research

When running multi-iteration research (ralph loops, deep dives), explicitly log assumptions with confidence ratings (High/Medium/Low) and a validation tracker table. This prevents later iterations from re-investigating settled questions or proceeding on shaky foundations. Format: assumption statement, confidence level, whether validated, and resolution. Cross-reference assumptions from the ID (A1, A2...) in other documents.

## Absence of Documentation ≠ Absence of Feature

When docs describe a feature only in the context of X (e.g., "auto-discovery works with `skills/`"), do NOT conclude that Y (e.g., `commands/`) lacks the feature. Silence is not exclusion. Require **explicit** evidence — a statement like "X does not support Y" — before claiming a capability difference. If the docs also contain a general equivalence statement (e.g., "both work the same way"), that should be the default position until contradicted.

**When asserting "X can't do Y":** actively search for evidence that X *can* do Y before committing to the claim. This is the adversarial/red-team step that catches false negatives.

## Broaden Primary Source Coverage in Research

Don't rely on a single doc page. When researching a feature area, traverse **related** official pages (e.g., researching skills? also read plugins, settings, reference docs). Key findings often live on adjacent pages — e.g., the plugin structure table that confirmed `commands/` support was on the plugins page, not the skills page.

## Validate Factual Claims About Runtime Behavior

Research that asserts capability differences (e.g., "directory X supports feature Y but directory Z doesn't") should be validated empirically when possible, not just inferred from docs. If the research loop constraints prevent code execution, flag the claim as **low-confidence/unverified** and note that empirical testing is needed before acting on it.

## "Validate" Means Run It

When asked to validate that scripts/workflows work, **execute them** — don't just lint. Static analysis (`bash -n`, file existence checks, cross-reference verification) catches structural issues but misses runtime bugs: wrong env values, ordering problems, integration failures. Default escalation: syntax check → dry-run (if available) → actual execution. Only stop at static analysis if execution is explicitly impossible or the user says so.

When creating docs that mirror code-defined data (enums, config, topology), run the source code to validate claims programmatically. Counting items, listing values, or computing derived facts via `poetry run python3 -c "..."` catches misclassifications that manual review misses.

## Confidence Calibration Diagnostic for Autonomous Loops

When an autonomous loop produces zero items at a classification level (e.g., zero LOWs across all iterations), diagnose whether it's genuine clarity or systematic under-reporting:

1. **Audit the level above**: Check MEDIUM decisions for borderline calls that should have been LOWs. Were any "auto-applied" where the rationale required non-trivial judgment?
2. **Check the classification funnel**: Count action types per level. If the auto-apply bucket has 14 action types and the block/escalate bucket has 4, the funnel structurally prevents items from reaching the lower level.
3. **Spot-check "clean" items**: Pick 2-3 files the agent called clean and review manually. If a human finds things the agent missed, the agent is resolving ambiguity silently rather than surfacing it.
=======
## Strip Consolidate-Output from PR Branches

`.claude/consolidate-output/` files (spec, progress, decisions, blockers, report, lows, iteration logs) are working artifacts — they track loop state, not deliverables. The actual value of a consolidation branch is the edits to learnings, guidelines, skills, and personas.

Before creating a PR, strip working state from the branch while preserving local copies: `git rm --cached -r .claude/consolidate-output/` (removes from git index, keeps on disk). Add `.claude/consolidate-output/` to `.gitignore` to prevent re-staging. For untracked logs (iterations after last commit), no git action needed — they're already local-only.
>>>>>>> Stashed changes
