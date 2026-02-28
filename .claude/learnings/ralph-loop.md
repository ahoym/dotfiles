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
- **Output files**: 7 files (spec, progress, decisions, blockers, report, lows, compounded-learnings) instead of 5 core research files
- **Security hooks**: Bash restricted to selective git allowlist (rm, add, mv, commit, status, diff — scoped to `.claude/`); WebFetch, WebSearch blocked; writes scoped to `.claude/` only. wiggum.sh validates sweep count delta (expected 1) after each invocation.
- **Round-based progression**: Each round sweeps LEARNINGS → SKILLS → GUIDELINES (one each). Convergence = 2 consecutive clean rounds. Max 5 rounds before forced stop.
- **Autonomous MEDIUM judgment**: Agent decides HIGHs and MEDIUMs autonomously; only true blockers surface for human review via `blockers.md`
- **Compounded learnings**: After sweeps with findings, agent appends corpus-level meta-insights to `compounded-learnings.md` (isolated from sweep corpus to prevent feedback loops). Resume skill surfaces these for `/learnings:compound` post-loop.
- **Runner**: `~/.claude/ralph/consolidate/wiggum.sh` (separate from the research `~/.claude/lab/ralph/wiggum.sh`)
- **Resume**: `/ralph:consolidate:resume` handles blocker resolution and relaunch (vs `/ralph:resume` for research question answering)

## Round-Based vs Type-Blocked Convergence

Type-blocked convergence (sweep type A twice, then type B twice) confirms each type in isolation — the "confirmation" sweep has no cross-type context. Round-based convergence (sweep A → B → C, then A → B → C again) means each type's confirmation sweep happens after all other types have been swept, catching cross-type regressions naturally. Also halves the minimum iteration count for clean corpora (6 vs 12 for 3 types × 2 confirmations).

## Compounded Learnings Isolation

When an autonomous agent writes insights during curation, those files must live outside the sweep corpus to prevent feedback loops (new insight → next sweep finds it → generates more insights → ...). The `consolidate-output/` directory serves as this isolation boundary — the spec defines corpus paths that exclude it.

## Pre-Flight Cadence Analysis

Count curation-related commits in recent git history to right-size iteration counts. Recent curation (3+ of last 5 commits) → suggest fewer iterations (corpus likely clean). Stale (0 of last 5) → suggest full sweep. Avoids wasting iterations on corpora that were just curated.

**Known limitation:** The heuristic matches commit message keywords (e.g., "consolidat"), not actual corpus file changes. Meta-tooling commits ("Improve consolidation loop") inflate the curation count without cleaning the corpus. Overshooting iterations is preferred to undershooting (cheap clean sweeps vs missed findings), so this is acceptable.

## Small Files Gravitate Toward Larger Domain Files

Standalone reference files risk orphaning when a larger file in the same domain independently accumulates the same patterns with more context. Example: all 3 patterns from `research-methodology.md` were re-discovered and expanded in `skill-design.md`, making the small file fully redundant. This is a natural corpus decay vector — the consolidation loop detects it, but it explains why thin files tend to need folding over time.

## Nested Skill Glob Pattern

`commands/*/SKILL.md` only matches top-level skill directories. For repos with multi-level nesting (e.g., `commands/ralph/consolidate/init/SKILL.md`), use `commands/**/SKILL.md`. This applies anywhere skills are inventoried — init pre-flight, spec corpus definitions, sweep methodology.

## Isolation Boundaries Enable Future Optionality

Building passive output files outside the active corpus (e.g., `compounded-learnings.md` in `consolidate-output/`) creates zero-cost architecture for future feedback loops. The file is ignored during sweeps today but could become an input to a future generative stage without changing the plumbing. The gate between "passive capture" and "active feedback" is a decision, not a redesign. Pair with a circuit breaker (max rounds guard) so the gate can be opened safely.

## Inline Compounding Over Skill Invocation in Autonomous Loops

When an autonomous agent needs to compound learnings mid-loop, inline the compound methodology rather than invoking `/learnings:compound` via the Skill tool. The agent already has the required tools (Read, Glob, Grep, Edit, Write) and the judgment context from the sweep it just completed. The compound skill adds: Skill tool dependency (may be hook-blocked), `~/.claude/` path assumptions (wrong in worktrees), AskUserQuestion (no user present), and ~120 lines of context per invocation. None of these are needed.

The inline methodology: categorize insights using `content-type-decisions.md` (Skill/Guideline/Learning), assign utility (High/Medium/Low), dedup-grep target directory before creating, write to worktree `.claude/` paths, log what was compounded. `compounded-learnings.md` becomes an audit log, not a staging file. Compounded files are corpus changes — the next LEARNINGS sweep evaluates them naturally via the convergence mechanism.

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

## Diagnosing Iteration Count Divergence

When outer-loop iteration count diverges from agent sweep count (e.g., 8 log files but agent reports 9 sweeps), check log *contents* against log *filenames*. The root cause is likely the agent doing multiple actions per invocation — not a missing log file or race condition. In the observed case, `iteration_2.log` contained "Iteration 3 complete" — the agent did sweeps 2+3 in wiggum's iteration 2.

## Defect Mode vs Opportunity Mode in Curation

Curation systems that only find defects (duplicates, staleness, project-specific content, broken references) miss optimization opportunities. The distinction:

- **Defect mode**: "Is anything wrong here?" — duplicates, overlaps, stale content, misplaced files
- **Opportunity mode**: "Could this be better?" — merges for cohesion, splits for discoverability, compression for token ROI, reference wiring, persona de-enrichment

Both need explicit methodology in the spec. Defect mode has clear confidence levels (a duplicate is a duplicate). Opportunity mode is inherently more subjective — classify as MEDIUM auto-apply when reversible (content moves, not lost). Without explicit opportunity methodology, the agent concludes "clean" when nothing is broken, even when the corpus could be meaningfully improved.

## Brief as Pre-PR Workflow

`/ralph:brief` naturally surfaces cleanup work before creating a PR for a research branch. Loading all core files into context reveals: superseded v1 directories to compare and clean up, unique content to port between versions, open questions to document in the PR. Use brief → compare → port → PR as a natural completion sequence.
