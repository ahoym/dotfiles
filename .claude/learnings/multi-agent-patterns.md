# Multi-Agent Patterns

## Agents Should Write Output to Intermediate Files

When a skill launches multiple agents in parallel and needs to synthesize their outputs, agents should write their results to intermediate files on disk rather than returning everything to the orchestrator.

**Why:**
- Agent outputs can be very large (each agent may read hundreds of files and produce detailed reports)
- The orchestrator must hold ALL agent outputs in context simultaneously for synthesis
- With 7 agents returning substantial outputs, this easily exhausts the context window mid-synthesis
- When context compresses, the synthesis works from a summary rather than the full data — detail is lost

**Pattern:**
- Agents write full findings to output files (e.g., `docs/learnings/<dimension>.md`)
- Agents return only a 2-3 sentence summary to the orchestrator (for success/failure tracking)
- Orchestrator stays lightweight — short summaries, not full reports
- A separate synthesis step (or separate invocation) reads from the output files with a clean context

## Verify Subagent Output Before Acting On It

When you delegate research or analysis to a subagent and plan to act on the result (presenting findings to the user, making edits, offering to merge), spot-check the key claim before proceeding.

**Why:** Subagent output *sounds* authoritative — it's structured, detailed, and confident. But subagents can misread files, confuse labels, or draw wrong conclusions. If you pass their output through to the user without verification, you amplify the error with your own credibility.

**When to verify:**
- The subagent's finding would trigger an action (merge, edit, recommendation to user)
- The finding is directional (A has X, B doesn't) — these are especially error-prone
- The finding contradicts your prior understanding or seems surprising

**How to verify:** Read the relevant file/section yourself and confirm the key claim. One targeted read is enough — you don't need to redo the full analysis.

**When to skip:** The subagent's output is purely informational (e.g., "how many files match this pattern?") and you won't act on it without further investigation.

## Structured Templates as Natural Size Constraints

Instead of hard output size limits (which LLMs can't reliably count or enforce), use structured templates to naturally constrain agent output length.

**Why hard limits don't work:**
- "Keep output under 300 lines" might produce 150 or 500
- Technical enforcement (truncation) risks cutting off findings mid-thought
- Hard limits on large repos force agents to silently drop important findings

**Pattern:**
- Give each agent a template with named sections, bullet-point format, and table structures
- Add a soft guideline: "Aim for 150-250 lines. Prioritize the most architecturally significant findings."
- The template structure itself limits verbosity — bullets force conciseness, named sections prevent rambling
- If an agent genuinely needs 400 lines for a complex domain, that's fine — the synthesizer can handle it

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

## Git Worktrees for Parallel Subagent Execution

When running parallel subagents that modify code in the same repo, use **git worktrees** so each agent works in its own directory on its own branch.

**Branching model within a batch:**
- Independent items: each worktree branches from the batch's starting point
- Dependent items: branch the dependent from the dependency's branch
- After all agents complete, merge branches sequentially, running the gate after each merge

## Scope Agent Context Narrowly

When launching parallel subagents for a refactoring plan, give each agent **only its relevant section** of the plan — not the full document. Full plan context leads to over-engineering and cross-cutting concerns that aren't the agent's responsibility.

## Pre-Approve Permissions Before Parallel Execution

Before launching parallel subagents, ensure wildcard bash permissions are pre-approved (e.g., `Bash(git branch:*)`, `Bash(pnpm test:*)`). In restrictive permission mode, each agent prompts independently for every command, serializing what should be parallel work.

## Project Adaptation Workflow

When forking or adapting an existing codebase into a new project, systematically categorize every file:

| Category | Description | Example |
|----------|-------------|---------|
| **Copy as-is** | Files needing zero changes | Utility modules, generic hooks, configs |
| **Adapt** | Files needing specific, enumerable modifications | Remove features, rename, add fields |
| **New** | Files that don't exist in the source | New pages, new components for changed UX |
| **Exclude** | Source files that should NOT be brought over | Features being dropped entirely |

**Process:** Inventory the source by architectural layer → categorize each file → document specific changes for "Adapt" files → group by dependency layer (libs → hooks → API routes → components → pages) → identify parallelization (independent layers run concurrently by separate agents).
