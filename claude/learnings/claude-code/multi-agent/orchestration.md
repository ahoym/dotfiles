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

After parallel Explore agents return, synthesize their findings into a concise summary before jumping to questions or decisions. The user shouldn't have to reconstruct the picture from raw agent output. Pattern: explore → distill ("here's what I found and what it means") → discuss. Especially important when agents return large outputs spanning multiple files and dependency trees.

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

## Cross-Refs

- `~/.claude/learnings/claude-authoring/skill-design.md` — skill design patterns including structured footnote usage and review skill design (source of migrated agent-to-agent review patterns)
- `~/.claude/learnings/claude-code/multi-agent/director-patterns.md` — director-layer patterns: watermark rerun, directives channel, append-only artifacts, run lifecycle
