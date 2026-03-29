Curation-specific patterns for the ralph consolidation loop — compounding mechanics, deep dive methodology, defect vs opportunity mode, brief as pre-PR workflow, staged-learnings pipeline, gotchas files policy, and consolidation worktree hooks.
- **Keywords:** consolidation, curation, compounding, deep dive, defect mode, opportunity mode, brief, staged-learnings, gotchas, worktree hooks, sweep, cluster batch, persona, thin file
- **Related:** `~/.claude/learnings/claude-code/ralph-loop.md`

---

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

Standalone reference files risk orphaning when a larger file in the same domain independently accumulates the same patterns with more context. Example: all 3 patterns from `research-methodology.md` were re-discovered and expanded in `~/.claude/learnings/claude-authoring/skills.md`, making the small file fully redundant. This is a natural corpus decay vector — the consolidation loop detects it, but it explains why thin files tend to need folding over time.

## Nested Skill Glob Pattern

`commands/*/SKILL.md` only matches top-level skill directories. For repos with multi-level nesting (e.g., `commands/ralph/consolidate/init/SKILL.md`), use `commands/**/SKILL.md`. This applies anywhere skills are inventoried — init pre-flight, spec corpus definitions, sweep methodology.

## Convergence as Safety Net for Compounding

Compounded insights go directly into the sweep corpus (worktree's `claude/learnings/`, guidelines, or skills) rather than a staging file. The round-based convergence mechanism (a clean round) is the circuit breaker — if compounding introduces issues, they surface as findings in the next sweep, resetting the clean streak. This trades isolation for directness: no post-loop `/learnings:compound` step needed, but the loop may take an extra round to re-converge if a compounded insight needs adjustment.

## Inline Compounding Over Skill Invocation in Autonomous Loops

When an autonomous agent needs to compound learnings mid-loop, inline the compound methodology rather than invoking `/learnings:compound` via the Skill tool. The agent already has the required tools (Read, Glob, Grep, Edit, Write) and the judgment context from the sweep it just completed. The compound skill adds: Skill tool dependency (may be hook-blocked), `~/.claude/` path assumptions (wrong in worktrees), AskUserQuestion (no user present), and ~120 lines of context per invocation. None of these are needed.

The inline methodology: categorize insights using `~/.claude/learnings/claude-authoring/routing-table.md` (Skill/Guideline/Learning), assign utility (High/Medium/Low), dedup-grep target directory before creating, write to worktree `claude/` paths, log what was compounded in `decisions.md`. Compounded files are corpus changes — deep dives and subsequent consolidation runs evaluate them.

## Personas as Execution-Mode Learnings Conduit

The implementation-start gate only checks personas, not learnings directly. This is intentional: well-wired personas have "Cross-Refs" sections pointing to relevant learnings. Setting the persona *is* the learnings trigger for execution — the agent loads the persona, sees the references, and pulls knowledge just-in-time. Direct learnings search happens at session start and plan-mode entry; by execution time, the persona layer handles it.

## Defect Mode vs Opportunity Mode in Curation

Curation systems that only find defects (duplicates, staleness, project-specific content, broken references) miss optimization opportunities. The distinction:

- **Defect mode**: "Is anything wrong here?" — duplicates, overlaps, stale content, misplaced files
- **Opportunity mode**: "Could this be better?" — merges for cohesion, splits for discoverability, compression for token ROI, reference wiring, persona de-enrichment

Both need explicit methodology in the spec. Defect mode has clear confidence levels (a duplicate is a duplicate). Opportunity mode is inherently more subjective — classify as MEDIUM auto-apply when reversible (content moves, not lost). Without explicit opportunity methodology, the agent concludes "clean" when nothing is broken, even when the corpus could be meaningfully improved.

## Brief as Pre-PR Workflow

`/ralph:brief` naturally surfaces cleanup work before creating a PR for a research branch. Loading all core files into context reveals: superseded v1 directories to compare and clean up, unique content to port between versions, open questions to document in the PR. Use brief → compare → port → PR as a natural completion sequence.

## Strip Consolidate-Output from PR Branches

`claude/consolidate-output/` files (spec, progress, decisions, blockers, report, lows, iteration logs) are working artifacts — they track loop state, not deliverables. The actual value of a consolidation branch is the edits to learnings, guidelines, skills, and personas.

Before creating a PR, strip working state from the branch while preserving local copies: `git rm --cached -r claude/consolidate-output/` (removes from git index, keeps on disk). Add `claude/consolidate-output/` to `.gitignore` to prevent re-staging. For untracked logs (iterations after last commit), no git action needed — they're already local-only.

## Gotchas Files Are Not Thin Files

`*-gotchas.md` files must never be merged into their parent domain files (e.g., `spring-boot-gotchas.md` → `spring-boot.md`) during consolidation sweeps. They serve different architectural roles: gotchas files are small, cheap proactive cross-ref files loaded on every persona activation; parent learnings files are larger reactive cross-refs loaded on-demand. A thin gotchas file (2-4 bullets) is working as designed, not a merge candidate. The consolidation spec's thin-file heuristic must explicitly exclude `*-gotchas.md` files.

## Resume Should Check for Uncommitted Deep-Dive Changes

The resume skill should run `git status` before cleanup and check for uncommitted modifications from the deep-dive phase. Deep-dive iterations may leave changes that weren't committed by the autonomous agent (e.g., agent-prompting compression, new learnings sections). These need to be committed before `git rm -r consolidate-output/` to avoid losing work or creating a confusing commit history.

## Retro → Compound → Curate as Search Protocol Feedback Loop

The existing retro → compound → curate pipeline provides search protocol performance feedback without needing a dedicated log file. Session retro reviews which learnings were loaded and whether they influenced the work. Compound captures insights ("this file keeps being noise," "this domain had no match"). Curate reads those insights and restructures files accordingly. The signal is qualitative (prose) rather than quantitative (tallies), but curation doesn't need quantitative precision to act.

## Unreferenced Learnings Are Not Orphans

Not every learning file needs a persona Cross-Refs entry. Context-aware learnings (`context-aware-learnings.md` guideline) discovers files by filename matching at session start and on keyword triggers — no persona wiring required. Only add a learning to a persona's Cross-Refs when it's highly correlated with the domain (most sessions with that persona would benefit). Niche learnings (e.g., `local-dev-seeding.md`) work better as context-aware discoveries — they get loaded when the topic actually comes up, not on every persona activation. During consolidation sweeps, do NOT wire learnings into personas just because they're unreferenced.

## Consolidation Worktree Hooks Auto-Commit and Can Revert

The consolidation worktree has guard hooks that auto-commit changes and can revert uncommitted modifications to match the last committed state. When making multiple sequential changes in an interactive session, commit after each logical change — don't batch. Uncommitted changes between tool calls may be silently reverted by hooks, requiring the work to be redone.

## Interactive-Autonomous Tracker Coordination

`/learnings:curate` (interactive) and the consolidation loop (autonomous) both review corpus files. After interactive curation, update the deep-dive tracker (`~/.claude/ralph/consolidate/deep-dive-tracker.json`) by setting `last_deep_dive_run = current run_count` for the curated file. This prevents the next consolidation run from queueing files for deep dives that were just manually reviewed.

## Session-Start Learnings Search Is Noisy for Consolidation Reviews

When evaluating a consolidation run, every file the loop touched appears in recent commit messages. The session-start learnings search matches those commit messages, loading files that are irrelevant to the *evaluation* task (e.g., `multi-agent-patterns.md` loaded because the loop edited it, not because the review session needed multi-agent knowledge). Low cost per false positive (~500 tokens), but worth noting as a known noise vector.

## LOW Review Items Require Human Judgment

All `[L-N]` items in `review.md` are human judgment items — even the ones that appear trivially fixable (wrong step number in a skill, stale description, etc.). The LOW tag signals that the autonomous loop deferred to the operator, not that the change is low-stakes. During `/ralph:consolidate:resume`, always use `AskUserQuestion` for every LOW before acting. Autonomously fixing any LOW bypasses the deferral that was intentionally placed there.

## Broad Sweep Per-Pattern Blind Spot

Cluster-level analysis can't catch per-pattern duplicates when: (a) headings use different wording for the same concept (no collision), (b) the duplicate lives in a different cluster's file, and (c) the source file is medium-sized (not thin enough to fold, not large enough to auto-flag). This is the gap that per-file content-mode curation (deep dives) fills — it cross-references each pattern against the full corpus, catching duplicates that cluster-level thematic matching misses.

## Cluster-Batched Deep Dives

Deep dives batch per learnings cluster directory — all candidate files in `claude/learnings/frontend/` are processed in one invocation, amortizing methodology loading and context setup. Unclustered files (top-level `claude/learnings/*.md`) remain one-per-invocation since they tend to be larger cross-cutting files.

**Cluster-level candidacy**: When any file in a cluster qualifies via the standard 7 criteria, all files in that cluster become candidates. The marginal cost of scanning additional small files in a cluster you're already loading is near zero, and having the full cluster in context enables intra-cluster cross-referencing that per-file analysis misses.

**Structural scans at cluster level**: Merge-for-cohesion and split-for-discoverability opportunity scans happen during cluster deep dives (not broad sweeps). The cluster batch is the best vantage point — all files at pattern-level detail, in the context of their neighbors.

**Max guard**: 15 invocations (down from 30). With cluster batching, 15 invocations covers significantly more files. The `min_deep_dives` floor (default 20) remains a file count, not invocation count.

## All Content Type Runs Are Roughly Equal Length

`min_deep_dives` (default 20) backfills small corpus runs with stale files from the deep-dive tracker. A GUIDELINES run with 4 files still does 20 deep dives — 16 slots filled from the stalest tracked files across all types. When planning how many iterations to allocate, treat all content type runs as ~same length regardless of corpus size.

## Stale Persona Paths Are the Dominant Curation Finding

Cluster reorganization silently breaks proactive and reactive cross-refs across *all* personas — not just those in the reorganized cluster. In a 13-persona collection, 10 had stale paths after learnings were clustered. This was the #1 finding across learnings, skills, and guidelines sweeps. Prioritize a bulk `grep` for flat-style paths (`learnings/<name>.md` without cluster prefix) as the first action in any post-reorg sweep.

## Curation Targets vs Comparison Context

In diff-routed deep dives, the 3-5 file group cap applies to **curation targets** (files actively curated — classified, actioned, keyword-enriched), not to **comparison context** (files loaded read-only for overlap/duplicate detection). A group might read 10-15 files total but only curate 3-5. The cap constrains curation *work*, not context *reads* — comparison context is unbounded because it's read-only and the cost is tokens, not curation complexity.

## Cross-Refs

- `~/.claude/learnings/claude-code/ralph-loop.md` — core loop mechanics: resuming, state management, stateless iteration, one-action enforcement, worktree mechanics, runner-spec contracts
- `~/.claude/commands/learnings/curate/curation-insights.md` — sweep calibration, classification heuristics, and compression targets that complement the curation methodology patterns here (defect vs opportunity mode, broad sweep blind spots)
