# Multi-Agent Patterns

See also: `~/.claude/skill-references/subagent-patterns.md` for universal patterns (output verification, intermediate files, structured templates).

## Coordinating Prop Removal Across Parallel Subagents

When removing a prop from many components using parallel subagents, each agent must update **both** the component interface and any child component call sites within the same file.

**The Problem:** Agent A removes `network` from `RecipientCard`'s props. Agent B removes `network` from `BalanceDisplay`'s props. But `RecipientCard` renders `<BalanceDisplay network={network} />` — if Agent A doesn't also remove that prop from the JSX, the build breaks because `BalanceDisplay` no longer accepts `network`.

**The Rule:** Each subagent that modifies a component should:
1. Remove the prop from the component's interface
2. Remove the prop from the destructured parameters
3. Add the replacement (e.g., `useAppState()`) inside the component
4. **Remove the prop from all child component JSX within that file** where the child is also being refactored

**Execution Order:** Leaf components first (no children to update), then mid-level components (update own interface + remove prop from leaf children), then parent pages last (remove prop from all top-level component calls).

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

## Front-Load Structural Context in Subagent Prompts

When delegating classification or evaluation tasks to subagents, include structural context that prevents misclassification — don't assume the subagent will infer it. For example, when evaluating skills, tell the subagent that subdirectory skills (e.g., `explore-repo/brief/`) are already sub-commands of their parent, not independent skills to merge. Without this, subagents flag false positives based on surface-level overlap analysis.
