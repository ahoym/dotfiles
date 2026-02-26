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
- **Security hooks**: Bash, WebFetch, WebSearch blocked; writes scoped to `.claude/` only
- **Two-pass progression**: LEARNINGS → SKILLS → GUIDELINES × 2 passes (catches cross-type regressions)
- **Autonomous MEDIUM judgment**: Agent decides HIGHs and MEDIUMs autonomously; only true blockers surface for human review via `blockers.md`
- **Convergence**: 2 consecutive clean sweeps per content type (not task-based completion signal)
- **Runner**: `~/.claude/ralph/consolidate/wiggum.sh` (separate from the research `~/.claude/lab/ralph/wiggum.sh`)
- **Resume**: `/ralph:consolidate:resume` handles blocker resolution and relaunch (vs `/ralph:resume` for research question answering)

## Brief as Pre-PR Workflow

`/ralph:brief` naturally surfaces cleanup work before creating a PR for a research branch. Loading all core files into context reveals: superseded v1 directories to compare and clean up, unique content to port between versions, open questions to document in the PR. Use brief → compare → port → PR as a natural completion sequence.
