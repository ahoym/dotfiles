# Multi-Agent Patterns

See also: `~/.claude/skill-references/subagent-patterns.md` for universal patterns (output verification, intermediate files, structured templates).

## Synthesis Should Run in a Separate Invocation

Combining outputs from multiple agents into a unified document should happen in a fresh context — not in the orchestrator that launched the agents. The orchestrator's context is already partially consumed; a fresh context gets full budget dedicated to reading output files and writing the final synthesis. If synthesis fails, it can be re-run without re-running all exploration agents.

**Preferred — same skill, separate invocation:**
1. Exploration agents write to output files
2. Skill detects mode via file existence — first run scans, second run synthesizes (see Stateful Mode Detection in skill-design.md)
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

## Multi-Agent Workflows Survive Context Compaction

Long-running orchestrations (e.g., 4 parallel merge agents processing 30+ files) can exceed the orchestrator's context window. When context compaction occurs mid-execution, background agents continue running independently — they have their own context. On resumption:

1. The compaction summary preserves agent IDs, completion statuses, and file-level progress
2. Use `TaskOutput` with `block: false` to check running agents' status
3. Use `TaskOutput` with `block: true` to wait for still-running agents
4. Completed agents' results are available via their agent IDs

**Key insight:** agents are decoupled from the orchestrator's context lifecycle. The orchestrator can be compacted, resumed, or even restarted — agents keep working.

## Balance Agent Work Distribution by Complexity

When splitting work across parallel agents, balance by estimated complexity — not just file count. In a 30-file merge operation split 3/3/5/19, the 19-file agent (472s, 105 tool uses) was the bottleneck while others finished in 217-320s.

**Complexity factors beyond count:** files needing fine-grained per-section merging (BOTH_UNIQUE) are ~3-5x more work than simple overwrites (SUPERSET:source) or copies (source-only). Weight distribution by merge type, not just file count.

## Many-Agent Context Compaction Risk

When launching 10+ background agents, some may complete after context compaction. The continuation session loses the original agent IDs and completion notifications. Mitigations: (1) batch agents in waves of 5-6 so each wave completes within the context window, (2) use a status tracking table updated after each completion notification, (3) if agents must all launch at once, record agent IDs in a file for the continuation session to check via `TaskOutput`.

## Write One, Validate, Then Parallelize

When generating N similar files (e.g., test files, config files), write **one** first, run it, fix issues, then use the validated version as a template for parallel generation. Avoids mass-failure scenarios where the same bug hits all N files simultaneously.

## Simple Multi-File Patterns: Inline over Agent

For mechanical substitutions across many files (e.g., changing a 3-line pattern to 2 lines in 13 files), inline editing with `replace_all` or sequential Edit calls is faster and more reliable than launching an agent. Agents are better for files requiring judgment or different logic per file.

## Context Budget: Delegate Bulk Generation Early

When a task involves both bulk file creation (tests) and iterative refactoring, delegate the bulk creation to agents early to preserve main context for the refactoring phase where judgment and iteration matter more.

## Categorize Parallel Work by Shared Structure

When generating many similar files via parallel agents, group them by structural shape — not alphabetically. For example, test files for GET routes share mock patterns distinct from POST mutation routes. Each category shares templates, making them ideal for parallel agents with distinct instructions.
