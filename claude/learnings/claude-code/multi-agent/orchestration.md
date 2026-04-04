Multi-agent orchestration — work distribution, synthesis, parallelization strategy, context compaction, and session-resumable workflows.
- **Keywords:** subagent, orchestrator, synthesis, parallel agents, context compaction, three-phase refactoring, session-resumable, partial batch, explore agent, codebase comparison, claude -p, parallel skill invocation, watermark, rerun, directives, append-only, sweep
- **Related:** ~/.claude/learnings/claude-authoring/skill-design.md

---

## Synthesis Should Run in a Separate Invocation

Combining outputs from multiple agents into a unified document should happen in a fresh context — not in the orchestrator that launched the agents. The orchestrator's context is already partially consumed; a fresh context gets full budget dedicated to reading output files and writing the final synthesis. If synthesis fails, it can be re-run without re-running all exploration agents.

**Preferred — same skill, separate invocation:**
1. Exploration agents write to output files
2. Skill detects mode via file existence — first run scans, second run synthesizes (see Stateful Mode Detection in ~/.claude/learnings/claude-authoring/skill-design.md)
3. Synthesis invocation reads each file with a fully clean context

**Alternative — synthesis as sub-agent:** Orchestrator launches a synthesis agent with file paths and output format requirements. Works but the orchestrator still needs enough context to coordinate.

These two patterns together (intermediate files + separate synthesis) break the "N agents → 1 orchestrator" bottleneck entirely.

## Agent Output Files as First-Class Documentation

When agents write intermediate files, design them as standalone documentation — not just pipeline artifacts to delete after synthesis.

**Pattern:**
- Name descriptively (e.g., `data-model.md`, not `_scan-data-model.md`)
- Structure with a consistent template (sections, bullet points, file paths)
- Include scan metadata in a header comment (agent name, commit, branch, date)
- Git-track the files — enables staleness detection (commit hash comparison) and incremental re-scanning

## Group Parallel Refactoring by File Domain, Not Change Type

When distributing a large refactor across parallel subagents, group changes by file domain (API routes, frontend components, lib, test scripts) — not by change type (all `validateRequired` replacements in one agent, all `getNetworkParam` in another).

**Why:** Grouping by change type creates conflicts when both agents need to edit the same file's imports. Grouping by file domain ensures each file is only touched by one agent. Don't split a single file domain across multiple agents — risks conflicts on shared imports. Run a final build after all agents complete to verify cross-agent compatibility.

## Codebase Comparison for Feature Porting

When comparing two codebases to identify features worth porting:

1. **Parallel exploration**: Launch 2 Explore agents simultaneously — one per project. Each reads all components in the target area and summarizes features, props, notable patterns.
2. **Build the feature matrix**: Categorize as "port candidates" (A has, B doesn't), "preserve" (B has, A doesn't), "compare quality" (shared, different implementations), "evaluate" (architectural differences).
3. **Prioritize** by user impact, implementation effort, dependencies, and risk.
4. **Write the plan** with file ownership and parallel execution phases.

## Port/Migrate Tasks: Request Full Source on First Pass

When the task is porting code from one codebase to another, request **exact source code** from Explore agents — not summaries. Summaries are useful for understanding; porting requires the actual class signatures, method bodies, annotations, and import lists. Requesting summaries first then re-launching agents for full code doubles the exploration cost.

## Distill Before Discussing

After parallel Explore agents return, synthesize their findings into a concise summary before jumping to questions or decisions. The operator shouldn't have to reconstruct the picture from raw agent output. Pattern: explore → distill ("here's what I found and what it means") → discuss. Especially important when agents return large outputs spanning multiple files and dependency trees.

**Heuristic:** If the plan will include "port X from repo A to repo B", the explore prompt should say "read the FULL contents of these files — report package declarations, imports, and complete class bodies."

## Three-Phase Subagent Refactoring

When performing codebase-wide refactoring with subagents:

1. **Exploration phase**: Launch 2-3 Explore agents in parallel, each focused on a different area (API routes, lib modules, test infrastructure). They analyze independently and report findings.
2. **Implementation phase**: Launch general-purpose agents in parallel for independent changes. Each agent gets the specific files to modify, what to change, and instructions to verify its own work.
3. **Verification phase**: After all parallel agents complete, run the full test suite once to catch any cross-agent conflicts.

## Project Adaptation Workflow

When forking or adapting an existing codebase into a new project, systematically categorize every file:

| Category | Description | Example |
|----------|-------------|---------|
| **Copy as-is** | Files needing zero changes | Utility modules, generic hooks, configs |
| **Adapt** | Files needing specific, enumerable modifications | Remove features, rename, add fields |
| **New** | Files that don't exist in the source | New pages, new components for changed UX |
| **Exclude** | Source files that should NOT be brought over | Features being dropped entirely |

**Process:** Inventory the source by architectural layer → categorize each file → document specific changes for "Adapt" files → group by dependency layer (libs → hooks → API routes → components → pages) → identify parallelization (independent layers run concurrently by separate agents).

## Context Compaction in Multi-Agent Workflows

Long-running orchestrations (e.g., 4 parallel merge agents processing 30+ files) can exceed the orchestrator's context window. Background agents continue running independently — they have their own context and are decoupled from the orchestrator's context lifecycle. On resumption, the compaction summary preserves agent IDs, completion statuses, and file-level progress. You'll be notified automatically when background agents complete — don't poll with `TaskOutput` (it only works for background Bash commands; see "TaskOutput Only Works for Background Bash Tasks" in ~/.claude/learnings/claude-code/multi-agent/quality.md).

**Risk with 10+ agents:** Some may complete after compaction, losing original agent IDs and notifications. Mitigations: (1) batch in waves of 5-6 so each wave completes within the context window, (2) use a status tracking table updated after each notification, (3) record agent IDs in a file for the continuation session.

## Balance Agent Work Distribution by Complexity

When splitting work across parallel agents, balance by estimated complexity — not just file count. In a 30-file merge operation split 3/3/5/19, the 19-file agent (472s, 105 tool uses) was the bottleneck while others finished in 217-320s.

**Complexity factors beyond count:** files needing fine-grained per-section merging (BOTH_UNIQUE) are ~3-5x more work than simple overwrites (SUPERSET:source) or copies (source-only). Weight distribution by merge type, not just file count.

## Write One, Validate, Then Parallelize

When generating N similar files (e.g., test files, config files), write **one** first, run it, fix issues, then use the validated version as a template for parallel generation. Avoids mass-failure scenarios where the same bug hits all N files simultaneously.

## Context Budget: Delegate Bulk Generation Early

When a task involves both bulk file creation (tests) and iterative refactoring, delegate the bulk creation to agents early to preserve main context for the refactoring phase where judgment and iteration matter more.

## Categorize Parallel Work by Shared Structure

When generating many similar files via parallel agents, group them by structural shape — not alphabetically. For example, test files for GET routes share mock patterns distinct from POST mutation routes. Each category shares templates, making them ideal for parallel agents with distinct instructions.

## Simple Multi-File Patterns: Inline over Agent

For mechanical substitutions across many files (e.g., changing a 3-line pattern to 2 lines in 13 files), inline editing with `replace_all` or sequential Edit calls is faster and more reliable than launching an agent. Agents are better for files requiring judgment or different logic per file.

## Explore Agent Upfront for Large Implementation Tasks

For implementation tasks touching 10+ reference files (existing infrastructure, patterns to follow, files to edit), launch a thorough Explore agent upfront before writing anything. The upfront cost (~2 min, 50+ tool calls) eliminates incremental back-and-forth during execution and enables writing all output files in parallel with full context. This is faster end-to-end than reading files incrementally as you discover you need them.

## Session-Resumable Long-Running Workflows

For workflows spanning multiple sessions (hundreds of items to process), the plan file must be self-contained for resumption:

1. **Progress tracker** — table with batch status so next session knows where to pick up
2. **Subagent prompt templates** — exact prompts so new sessions reconstruct them without context from the original planning discussion
3. **Resume instructions** — explicit steps (read plan, check progress, glob existing output files for current state, start next batch)
4. **Tool constraints** — document any discovered UX issues (e.g., "don't use python3, use jq")

The plan file is the single source of truth across sessions — it should contain everything needed to continue without reading the conversation history.

## Partial Batch Completion Is Normal Operating Mode

When parallel extractors fail (API rate limits, permission issues), process completed ones immediately rather than retrying the full batch. Track partial completion explicitly in progress notes ("5 of 10 PRs, #21-#26 deferred") so the next session picks up exactly where it left off. This avoids wasting successful extractor outputs and keeps the workflow moving forward. The progress tracker in the plan file is the single coordination point — partial batches get their own row with clear deferred-item lists.

## Explore Agent Can't Access ~/.claude/ Paths

The Explore agent type fails to glob or read files under `~/.claude/` (symlinked config directories). Use general-purpose agents for file operations on these paths. The Explore agent is fast for repo-scoped searches but its tool access doesn't resolve symlinks outside the working directory.

## File Splits via Parallel Subagents

For mechanical file splits (read → determine boundary → write 2 files), launch one general-purpose subagent per file in parallel. Each subagent independently reads, splits, and writes — no coordination needed since they target different files. The orchestrator handles shared resources (CLAUDE.md index updates) after all subagents complete. Validated at 6 concurrent splits with zero conflicts.

## Parallel Skill Invocation via `claude -p` Sessions

When a skill needs to run N times in parallel (e.g., team-review per PR), subagents can't help — they can't invoke skills or nest agents. Instead, generate a bash script that launches parallel `claude -p` sessions, each invoking the skill via the Skill tool. Each `claude -p` is a full top-level session with complete tool access (Skill, Agent, everything). Use `xargs -P` for bounded concurrency. Write per-invocation prompts to files and pipe to `claude -p` to avoid shell escaping issues. This pattern decouples assessment (interactive skill) from execution (bash script) from retro (read artifacts).

## Generated Script UX Checklist

When generating bash scripts for operators to run (especially long-running parallel `claude -p` sessions), verify before writing:

1. **Immediate output on launch** — header banner with run parameters (PR count, concurrency, run dir)
2. **Timestamped per-item status** — `[HH:MM:SS] PR #N: launching...` and `[HH:MM:SS] PR #N: DONE (Xs)`
3. **External monitoring tip** — a one-liner the operator can run in another terminal to watch progress files
4. **macOS portability** — no `watch`, no GNU-specific flags. Use `while clear; do ...; sleep N; done` for polling loops
5. **Error visibility** — failures print immediately, don't get swallowed by tee/redirect

A script that runs 5-10 minutes with zero output erodes operator confidence. The operator's terminal experience is a first-class UX concern.

## Shared Runner Templates for Parallel Skills

When multiple skills generate structurally identical bash scripts (same concurrency control, logging, rate-limit detection), extract a shared template with mustache-style placeholders (`{{MODE}}`, `{{PRS}}`, `{{CONCURRENCY}}`) and conditional blocks (`{{#WORKTREES}}...{{/WORKTREES}}`). Each skill fills its specifics; improvements to the runner happen in one place. See `~/.claude/skill-references/parallel-claude-runner-template.sh`.

## Pre-flight State Check in Rerunnable Runners

When a generated script is designed to be rerun (e.g., after an address-review cycle), add a cheap pre-flight check before launching each `claude -p` session: `gh pr view $N --json state -q '.state'`. Skip merged/closed PRs immediately — one API call is far cheaper than spinning up a session that detects terminal state and exits. The inner skill's own terminal-state handling remains as a safety net.

## Parallel Cluster Analysis for Catalog Sweeps

For catalog-wide curation across 50+ files organized in clusters, launch one subagent per cluster to analyze all files in parallel. Each subagent reads every file, checks headers, cross-refs, collisions, and reports structured findings (per-file summary table, issues, all H2/H3 headings for collision detection). The orchestrator merges results, runs cross-cluster collision detection on the combined heading lists, and classifies findings by confidence. Validated at 5 concurrent cluster agents (~80 files total) — wall clock ~3 min vs ~15 min sequential.

## Writer Subagents Must Produce Only Complete Replacement Files

When writer subagents enrich existing files, instruct them to write the full file content with the same filename — never delta/instruction files or `-enriched` suffix variants. If a glob copy (`for f in staging/*.md; cp $f target/`) runs over the staging directory, instruction files overwrite real content and suffix variants create dedup confusion. The fix is explicit in the writer prompt: "Write ONLY complete replacement files with the SAME filename as the original."

## Re-sync Shared Directories After Batch Overwrites

When multiple output destinations share content (e.g., `~/.claude/learnings/` and `~/.claude/learnings-team/learnings/`), batch writer agents may overwrite one but not the other. After each batch finalization, re-sync the secondary from the primary to prevent divergence. Without this, later batches compound the drift and orphaned files accumulate.

## Spot-Check Yield Correlates with Original Pass Discussion Density

When re-extracting batches with a new lens (e.g., implementation patterns), the dedup rate against original-pass learnings predicts yield: implementation-only batches (~40% dedup) have the most new signal; discussion-rich batches (~80% dedup) are already well-captured. Prioritize spot-checks on batches where the original triage skipped MRs or where batch notes emphasize discussion findings over implementation.

## Skip Private Writers for Spot-Check Runs

Spot-check passes over previously-extracted batches consistently produce zero private-scoped learnings — the original pass already captured anything private-worthy. Skip spawning the private writer subagent to save ~10k tokens per batch. Still spawn it for fresh (never-extracted) batches.

## Combine Batches in a Single Writer Invocation

When multiple batches are spot-checked in the same session, concatenate all extractor outputs and spawn one set of writers covering both batches. Writers handle dedup across the combined set, and the reduced agent count (3 instead of 6) saves context and wall-clock time. Works well up to ~2 batches; beyond that the concatenated prompt may exceed writer context budget.

## Writer Agents Scale to ~50 Inputs Per Scope

A single project writer processed 52 extracted learnings (from 19 MRs across 2 batches) in one pass — reading 11 existing files, deduplicating 33, enriching 5, and writing 14 new entries. General writers handle fewer inputs (~8) but perform deeper dedup against a larger existing file set. This confirms single-writer-per-scope works up to ~50 inputs without hitting context limits.

## Background Writer Staging Bypass

Background writer subagents sometimes write directly to final locations (`~/.claude/learnings/`) instead of the staging directory (`docs/learnings/_staging/`), even when instructed to stage. This happens when the agent has write permissions to the final path. The `finalize-staging.sh` script then reports "0 files copied" — which looks like a failure but actually means the work was already done. Verify by checking file modification timestamps at the final location rather than trusting the copy count. The orchestrator should check both staging and final paths before concluding something went wrong.

## Cross-Refs

- `~/.claude/learnings/claude-authoring/skill-design.md` — skill design patterns including structured footnote usage and review skill design (source of migrated agent-to-agent review patterns)
- `~/.claude/learnings/claude-code/multi-agent/director-patterns.md` — director-layer patterns: watermark rerun, directives channel, append-only artifacts, run lifecycle
