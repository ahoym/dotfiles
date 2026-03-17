# Multi-Agent Patterns

See also: `~/.claude/skill-references/subagent-patterns.md` for universal patterns (output verification, intermediate files, structured templates).

## Synthesis Should Run in a Separate Invocation

Combining outputs from multiple agents into a unified document should happen in a fresh context — not in the orchestrator that launched the agents. The orchestrator's context is already partially consumed; a fresh context gets full budget dedicated to reading output files and writing the final synthesis. If synthesis fails, it can be re-run without re-running all exploration agents.

**Preferred — same skill, separate invocation:**
1. Exploration agents write to output files
2. Skill detects mode via file existence — first run scans, second run synthesizes (see Stateful Mode Detection in claude-authoring-skills.md)
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

## Coordinating Interface Changes Across Parallel Subagents

When removing a parameter/prop from many modules using parallel subagents, each agent must update **both** the module's interface and any call sites within the same file.

**The Problem:** Agent A removes `config` from `ModuleX`'s interface. Agent B removes `config` from `ModuleY`'s interface. But `ModuleX` calls `ModuleY(config)` — if Agent A doesn't also update that call site, the build breaks because `ModuleY` no longer accepts `config`.

**The Rule:** Each subagent should:
1. Remove the parameter from the module's interface/signature
2. Remove the parameter from internal destructuring/usage
3. Add the replacement (e.g., context lookup, import) inside the module
4. **Update all call sites within that file** where the callee is also being refactored

**Execution Order:** Leaf modules first (no callees to update), then mid-level (update own interface + fix leaf call sites), then top-level entry points last.

## Group Parallel Refactoring by File Domain, Not Change Type

When distributing a large refactor across parallel subagents, group changes by file domain (API routes, frontend components, lib, test scripts) — not by change type (all `validateRequired` replacements in one agent, all `getNetworkParam` in another).

**Why:** Grouping by change type creates conflicts when both agents need to edit the same file's imports. Grouping by file domain ensures each file is only touched by one agent. Don't split a single file domain across multiple agents — risks conflicts on shared imports. Run a final build after all agents complete to verify cross-agent compatibility.

## Sandbox Workaround: Lifecycle Scripts for Out-of-Directory Operations

Task tool subagents are sandboxed to the project directory. They cannot create directories, write, or edit files outside the project root. For skills that need to operate in a git worktree (outside project root), create a single lifecycle shell script with subcommands (create, attach, write, read, delete, commit, remove) and pre-approve it:

```
Bash(bash ~/.claude/commands/<skill-name>/worktree-lifecycle.sh:*)
```

Key design decisions:
- Use heredoc redirect syntax (`bash ... write ... <<'DELIM'`) so the command starts with `bash` and matches the permission pattern
- Single permission entry covers all operations
- Auto-cleanup of stale worktrees in create/attach subcommands
- Every filesystem operation the agent might need (CRUD) must have a corresponding subcommand — without `read`, agents resort to fragile `git show branch:path`; without `delete`, agents cannot clean up probe/test files before committing

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

## Verify Subagent Research Actually Used Web Sources

When delegating research to subagents (Task tool with `claude-code-guide` or `Explore`), check the **sources** in their output — not just the conclusions. Subagents may read local files and existing learnings instead of performing fresh web searches, then present recycled information as new research. This is especially problematic when the local files contain the very claims you're trying to validate.

**Red flags:** output only cites local file paths, no WebSearch/WebFetch calls in the work, conclusions perfectly match existing assumptions. **Fix:** explicitly instruct subagents to "use WebSearch and WebFetch to find NEW information — do not rely on local files" and review whether they actually did.

## Three-Branch Gate Announcements

Every hard gate (session start, plan mode, implementation start) needs three announcement templates: positive match, already satisfied, and skip/no-match. Missing a branch means the gate fires silently — no observability on whether it executed. During calibration this is especially costly: silent skips look identical to gates that didn't fire at all, making it impossible to diagnose whether the system is working.

## Delegated Operations via Intent Files

When an agent can't execute certain operations (e.g., Bash blocked by security hooks), delegate via structured intent files: agent writes requests to a dedicated file (one per line), outer loop processes them between iterations. Prefer explicit intent files over parsing action logs — separate concerns, simpler parsing, no coupling to log format.

Example: agent can't `git rm` (Bash blocked) → writes `.claude/consolidate-output/pending-deletions.txt` with paths to delete → wiggum.sh reads the file between iterations and runs `git rm` for each entry. Safety check: only delete files that are truly empty (prevents accidental deletion from wrong paths).

## Front-Load Structural Context in Subagent Prompts

When delegating classification or evaluation tasks to subagents, include structural context that prevents misclassification — don't assume the subagent will infer it. For example, when evaluating skills, tell the subagent that subdirectory skills (e.g., `explore-repo/brief/`) are already sub-commands of their parent, not independent skills to merge. Without this, subagents flag false positives based on surface-level overlap analysis.

## Full Write > Incremental Edit for Content-Aware Merges

When merging diverged files with many structural changes (new sections, reordered content, genericized examples), a full `Write` is more reliable than many incremental `Edit` calls. Incremental edits can create duplication artifacts — e.g., a section gets inserted inside an existing code block, or an edit's context match lands in the wrong location after prior edits shifted content.

**Recovery pattern:** If an agent detects duplication after incremental edits (by reading the file back), it should abandon the edit approach and do a full `Write` with the correct merged content. This self-correction is cheaper than debugging cascading edit failures.

## Context Compaction in Multi-Agent Workflows

Long-running orchestrations (e.g., 4 parallel merge agents processing 30+ files) can exceed the orchestrator's context window. Background agents continue running independently — they have their own context and are decoupled from the orchestrator's context lifecycle. On resumption, the compaction summary preserves agent IDs, completion statuses, and file-level progress. You'll be notified automatically when background agents complete — don't poll with `TaskOutput` (it only works for background Bash commands; see "TaskOutput Only Works for Background Bash Tasks" below).

**Risk with 10+ agents:** Some may complete after compaction, losing original agent IDs and notifications. Mitigations: (1) batch in waves of 5-6 so each wave completes within the context window, (2) use a status tracking table updated after each notification, (3) record agent IDs in a file for the continuation session.

## Balance Agent Work Distribution by Complexity

When splitting work across parallel agents, balance by estimated complexity — not just file count. In a 30-file merge operation split 3/3/5/19, the 19-file agent (472s, 105 tool uses) was the bottleneck while others finished in 217-320s.

**Complexity factors beyond count:** files needing fine-grained per-section merging (BOTH_UNIQUE) are ~3-5x more work than simple overwrites (SUPERSET:source) or copies (source-only). Weight distribution by merge type, not just file count.

## Write One, Validate, Then Parallelize

When generating N similar files (e.g., test files, config files), write **one** first, run it, fix issues, then use the validated version as a template for parallel generation. Avoids mass-failure scenarios where the same bug hits all N files simultaneously.

## Cross-Agent File References Need Orchestrator Verification

When parallel agents each create files that *reference each other* (paths, function calls, shared IDs), no individual agent can verify the integration seams — each only sees its own output. Distinct from the "interface changes" pattern (agents editing shared code): here agents create independent files with cross-references baked into strings and paths.

**Fix:** After all agents complete, the orchestrator must verify integration points: file paths match, shared constants agree, argument signatures align. Budget time for this — agents produce correct structure but wrong cross-references (e.g., `$SCRIPT_DIR/validate.sh` vs `$SCRIPT_DIR/seed/validate.sh`).

## Simple Multi-File Patterns: Inline over Agent

For mechanical substitutions across many files (e.g., changing a 3-line pattern to 2 lines in 13 files), inline editing with `replace_all` or sequential Edit calls is faster and more reliable than launching an agent. Agents are better for files requiring judgment or different logic per file.

## Context Budget: Delegate Bulk Generation Early

When a task involves both bulk file creation (tests) and iterative refactoring, delegate the bulk creation to agents early to preserve main context for the refactoring phase where judgment and iteration matter more.

## Categorize Parallel Work by Shared Structure

When generating many similar files via parallel agents, group them by structural shape — not alphabetically. For example, test files for GET routes share mock patterns distinct from POST mutation routes. Each category shares templates, making them ideal for parallel agents with distinct instructions.

## Standardize Worktree Agent Commit Behavior

Tell worktree agents explicitly: **"Do NOT commit your changes — leave them unstaged."** This ensures a single extraction path (`git diff > patch && git apply`) for every agent. Mixed commit behavior (some commit, some don't) forces the orchestrator to check each worktree individually and use different extraction methods.

If an agent does commit despite instructions, fall back to `git cherry-pick`. But the goal is to eliminate this branch entirely.

## Worktree Agent Verification: Full Lint Stack

Every worktree agent's verification step should run the **full** lint stack, not just pytest:
```bash
poetry run pytest --tb=short
poetry run ruff check
poetry run ruff format --check
poetry run pyright .
```
Skipping lint/format in agents causes issues to accumulate at the end, requiring multiple fix-commit cycles in the main worktree.

## Worktree Agent Merge: Check Commit State Before Extracting

Worktree agents may or may not commit their changes — check both `git log` and `git status` in the worktree before extracting. Uncommitted changes need `git diff > patch && git apply`, while committed changes need `git cherry-pick`. Mixing up the extraction method produces empty patches or missed changes.

**Pattern:**
```bash
git log origin/main..HEAD --oneline   # new commits?
git status --short                     # unstaged changes?
# Uncommitted → git diff > patch && git apply
# Committed   → git cherry-pick <sha>
```

## Subagents Cannot Write .md Files

The Write tool blocks documentation file creation (`.md`, `README`) unless explicitly requested by the user. Background agents can't get user approval, so they silently fail. This is a systemic blocker for skills like `explore-repo` where agents produce `.md` output files.

**Workarounds (in preference order):**
1. **Pre-create directories + resume pattern**: Orchestrator creates output directories (`mkdir -p docs/learnings`) *before* launching agents. If agents still fail on Write (permission prompt they can't answer), resume them after the user approves the first write — agents retain their full analysis context, so the resume only costs 1 tool call per agent. This avoids re-doing all analysis work.
2. Have the orchestrator write files instead of delegating writes to subagents
3. Use Bash (`cat <<'EOF' > file.md`) in the agent — may also be blocked but worth trying
4. **Transcript extraction pattern**: after blocked agents complete, launch extraction agents that read the transcript output files (chunked `Read` with offset/limit) and write the actual files from orchestrator context

**Resume pattern details**: When N agents fail on Write, resume all N in parallel — each retains full analysis context, so the resume costs only 1 Write call per agent (observed: ~60-90s vs ~200-370s for fresh scans). The transcript extraction pattern (option 4) doubles agent count but recovers from permission failures; launch extractors in parallel to minimize wall-clock time.

## Extractor-Writer Subagent Pattern

For bulk data processing (e.g., extracting learnings from 460 MRs), split into two subagent roles:

1. **Extractors** (N parallel): Each processes one item (MR, file, etc.), fetches its own data, returns structured output. Research-only — no file writes.
2. **Writer** (1 sequential): Receives all extractor outputs concatenated, reads existing files, deduplicates, classifies, and writes updates.

**Why separate:** Extractors run in parallel and absorb raw data noise (API responses, discussion threads) that would pollute the main context. The writer handles dedup coherently because it sees all extractions at once + all existing content. Main context becomes pure orchestration: fetch metadata → spawn extractors → spawn writer → update progress.

**Context cost:** Subagent results still flow back to main context as messages. System reminders also echo back every file edit the writer makes. Minimize by having the writer do fewer, larger writes (full file rewrites) rather than many small edits.

## Session-Resumable Long-Running Workflows

For workflows spanning multiple sessions (hundreds of items to process), the plan file must be self-contained for resumption:

1. **Progress tracker** — table with batch status so next session knows where to pick up
2. **Subagent prompt templates** — exact prompts so new sessions reconstruct them without context from the original planning discussion
3. **Resume instructions** — explicit steps (read plan, check progress, glob existing output files for current state, start next batch)
4. **Tool constraints** — document any discovered UX issues (e.g., "don't use python3, use jq")

The plan file is the single source of truth across sessions — it should contain everything needed to continue without reading the conversation history.

## TaskOutput Only Works for Background Bash Tasks

`TaskOutput` with `block: false` works for background Bash commands (`run_in_background: true`), not for background Agent tasks. Agent IDs from `run_in_background` agents are tracked via the automatic notification system — you'll be notified when they complete. Don't poll with `TaskOutput`; it returns "No task found" errors.

## Split Writers by Output Location for Parallelism

When a batch workflow writes to independent file sets (e.g., project-specific learnings vs global learnings), split into parallel writer subagents — one per location. Each writer reads and deduplicates only against its own files. Cuts writer wall-clock time roughly in half since the bottleneck is reading existing files + processing.

## Verification: Targeted Grep Over Full File Reads

After subagent writes, verify with `wc -l`, `grep -c`, and a 5-line spot-check — not full file reads. Full reads consume ~8k tokens per batch for equivalent confidence to ~400 tokens of grep. Reserve full reads for debugging when grep checks fail.

## Trust-Building Arc as Human-Agent Collaboration Model

The manager-report trust pattern maps directly to human-agent autonomy calibration: small scoped tasks with close review → demonstrate good judgment → gradually expand scope → occasional mistakes that are caught and learned from. Learnings, guidelines, and personas are trust artifacts — accumulated evidence of calibration, not just rules for an agent. This frame is useful for evaluating system changes: does this change help build trust (positive signals, outcome tracking) or just constrain behavior (more rules)?

## Explore Agent Upfront for Large Implementation Tasks

For implementation tasks touching 10+ reference files (existing infrastructure, patterns to follow, files to edit), launch a thorough Explore agent upfront before writing anything. The upfront cost (~2 min, 50+ tool calls) eliminates incremental back-and-forth during execution and enables writing all output files in parallel with full context. This is faster end-to-end than reading files incrementally as you discover you need them.

## Partial Batch Completion Is Normal Operating Mode

When parallel extractors fail (API rate limits, permission issues), process completed ones immediately rather than retrying the full batch. Track partial completion explicitly in progress notes ("5 of 10 PRs, #21-#26 deferred") so the next session picks up exactly where it left off. This avoids wasting successful extractor outputs and keeps the workflow moving forward. The progress tracker in the plan file is the single coordination point — partial batches get their own row with clear deferred-item lists.

## Staging Directory Pattern for Out-of-Project Writes

Background agents cannot write to paths outside the project directory — this is a hardcoded restriction that no permission pattern can override. When agents need to produce files destined for external locations (e.g., `~/.claude/learnings/`), have them write to a staging directory inside the project instead. The orchestrator then copies staged files to their final locations in foreground, where the restriction doesn't apply.

Pattern: agent reads from real location (dedup), writes to `docs/learnings/_staging/<scope>/`, orchestrator runs `cp` + `rm -rf` after all agents complete. The staging files are also visible in `git status` before being applied, enabling review.

## Pre-Read External Files Before Launching Agents

Agents inherit the parent session's permission scope. Files outside permissioned directories (e.g., `~/Downloads/`) cause silent failures — agents complete analysis but can't read the inputs. When launching agents that need files from outside the workspace, read the files yourself first and pass the content in the agent prompt. The analysis is the expensive part; providing input content is cheap.

## Orchestrator/Agent Split for Multi-Step Skills

Split SKILL.md into two files when a skill has a multi-step background workflow:
1. **Orchestrator (SKILL.md)** — User interaction only: identifying items, displaying for selection, gathering input. Target ~80 lines. List reference files as conditional (no eager `@`).
2. **Background agent steps (separate .md)** — Autonomous workflow executed by a Task agent. Use aliases at top, decision tables for branching, inline warnings at point of use, error recovery at bottom.

## Verify Assumptions Before Documenting

Test assumptions with a controlled experiment before writing them as facts across multiple files. Run a minimal reproducer that isolates the specific claim. If testing "agents can't use X", test with a known-working variant first before concluding it's a platform issue.

## Cross-Check Subagent Inventory Comparisons

When subagents compare file inventories across two directories, they may report files as "unique to X" that actually exist in both — especially with large file counts (50+). Always cross-check subagent diff results against a canonical source you control (e.g., a glob you ran yourself). The error compounds when the over-reported "unique" files drive downstream decisions (what to copy, what to merge).

## Agent-to-Agent Review Architecture

Reviewer → addresser → human is a viable review cycle. The addresser investigates deeper than the reviewer (reads full files, not just the diff) and can surface issues the reviewer missed. When the addresser agrees with a suggestion, auto-implement without human approval; escalate only on disagreement or uncertainty. The human's role shifts from approving every change to reviewing the PR diff and calibrating agent judgment over time.

Use structured footnotes (`Persona + Role`) to separate comment chains when both agents post as the same GitHub user. Comments without a Role tag are human.

## Iterative Testing for Timing-Dependent Autonomous Features

Autonomous features with timing-dependent side effects (stale poll auto-cancel, timeout-based cleanup, rate-limiting) need iterative testing with a human watching. The spec gets ~70% right, but edge cases only surface in production: premature cancellation, clock access limitations, permission friction on state persistence. Design the first version, run it live, observe failures, fix, repeat. The loop itself is the test harness.

## File Overlap as Parallel Conflict Predictor

When independent work items (issues, tasks) could run in parallel, check for file overlap before launching. Issues that touch the same files (e.g., two terminology sweeps both editing persona files) cause merge conflicts in parallel worktree agents. Options: pre-filter conflicting items into sequential batches, accept conflicts and resolve post-merge, or group by file domain and run groups sequentially. File overlap analysis is cheap (grep issue bodies for mentioned paths/patterns) and prevents the most common parallel failure mode.

## See also

- `~/.claude/learnings/claude-code.md` — permission patterns, worktree isolation mismatches, background agent permission gotchas, cron and polling patterns (platform mechanics underlying the agent patterns here)
- `~/.claude/learnings/claude-authoring-skills.md` — skill design patterns including structured footnote usage and review skill design (source of migrated agent-to-agent review patterns)
- `~/.claude/learnings/parallel-plans.md` — DAG shape analysis, plan splitting, branch strategies, fan-in cherry-pick mechanics (plan-level complement to the agent orchestration patterns here)
