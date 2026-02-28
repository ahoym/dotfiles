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

## Nested Skill Glob Pattern

`commands/*/SKILL.md` only matches top-level skill directories. For repos with multi-level nesting (e.g., `commands/ralph/consolidate/init/SKILL.md`), use `commands/**/SKILL.md`. This applies anywhere skills are inventoried — init pre-flight, spec corpus definitions, sweep methodology.

## Isolation Boundaries Enable Future Optionality

Building passive output files outside the active corpus (e.g., `compounded-learnings.md` in `consolidate-output/`) creates zero-cost architecture for future feedback loops. The file is ignored during sweeps today but could become an input to a future generative stage without changing the plumbing. The gate between "passive capture" and "active feedback" is a decision, not a redesign. Pair with a circuit breaker (max rounds guard) so the gate can be opened safely.

## Personas as Execution-Mode Learnings Conduit

The implementation-start gate only checks personas, not learnings directly. This is intentional: well-wired personas have "Detailed references" sections pointing to relevant learnings. Setting the persona *is* the learnings trigger for execution — the agent loads the persona, sees the references, and pulls knowledge just-in-time. Direct learnings search happens at session start and plan-mode entry; by execution time, the persona layer handles it.

## Brief as Pre-PR Workflow

`/ralph:brief` naturally surfaces cleanup work before creating a PR for a research branch. Loading all core files into context reveals: superseded v1 directories to compare and clean up, unique content to port between versions, open questions to document in the PR. Use brief → compare → port → PR as a natural completion sequence.
