---
name: make
description: Analyze a plan for parallelization opportunities and produce a structured parallel plan with a dependency DAG. Use when the operator says "parallelize this plan" or wants to split work into concurrent streams.
---

# Make Parallel Plan

Analyze a plan for parallelization opportunities, build a dependency DAG, and output a structured parallel plan that `/parallel-plan:execute` can run.

## Usage

- `/parallel-plan:make <plan-file>` — Analyze and parallelize a plan file
- `/parallel-plan:make` — Analyze the most recently discussed plan

## Reference Files

- `analysis-guide.md` — Detailed methodology for file-conflict analysis, dependency types, DAG design, and agent splitting strategies
- `~/.claude/skill-references/agent-prompting.md` — Best practices for writing agent prompts (speed, landmarks, scaling, TDD, boundaries)

## Output

Writes **two files** — a plan file (`.plan.md`) for review and status tracking, and a prompts file (`.prompts.md`) as the execution manifest. Together they form the contract between this skill and `/parallel-plan:execute`.

- **Plan file** (`<name>.plan.md`) — decisions and structure: context, shared contract, agent summary table, DAG, estimates, verification, branch strategy, review notes, execution state. This is what the operator reviews and what tracks execution progress.
- **Prompts file** (`<name>.prompts.md`) — execution manifest: prompt preamble, full agent definitions (metadata + prompts). This is what the executor consumes to launch agents. Immutable after creation.

## Instructions

### Step 1: Resolve the plan file

If arguments were provided (e.g., `/parallel-plan:make docs/plans/my-plan.md` or `/parallel-plan:make from .claude/plans/my-plan.md`), extract the file path from the arguments (strip any leading "from" prefix) and resolve it relative to the project root. Read that file as the input plan.

If no arguments were provided, use the plan most recently discussed in the conversation. If no plan has been discussed, ask the operator which plan file to parallelize.

### Step 2: Analyze the plan for parallelism

Read the plan file. For each step, identify:
- **Files touched** (created, modified, deleted)
- **Dependencies** (which steps must complete before this one can start)

Build a **file-conflict matrix**: two steps conflict if they modify the same file. Steps that only create new files never conflict with each other.

Read `analysis-guide.md` for the detailed methodology.

### Step 3: Parallelization gate

Evaluate whether parallelization is worthwhile before investing in a full plan. See `analysis-guide.md` → "Parallelization Gate" for decision criteria and thresholds.

If the gate fails, inform the operator and explain why. Offer to proceed for contract-enforcement benefits. Do NOT silently produce a plan with < 1.3x speedup.

### Step 4: Pre-flight dependency verification

Verify all required toolchain dependencies (test framework, build tools, linters) exist before writing agent prompts. See `analysis-guide.md` → "Pre-flight Dependency Verification".

If a dependency is missing, flag it to the operator — never delegate installation to an agent.

While verifying dependencies, collect every distinct Bash command pattern that agents will need to run (test commands, build commands, lint commands, format commands). These go in the plan's **Required Bash Permissions** section.

### Step 5: Design the agent DAG

Convert the file-conflict matrix into a directed acyclic graph. Read `analysis-guide.md` for detailed methodology on:
- Dependency types (hard vs soft) → "Dependency Types"
- Interface-first pattern → "Interface-first Pattern"
- Soft dependency audit → "Soft Dependency Audit"
- DAG visualization verification → "DAG Visualization Verification"
- Splitting large agents → "Splitting Large Agents"

Key invariant: **no two agents share a file** in their creates/modifies/deletes lists.

### Step 6: Merge candidate check

Scan for agents that should be merged (orphaned, tiny, same-chain small pairs, build-verify-only). See `analysis-guide.md` → "Merge Candidate Detection".

After merging, recalculate the critical path and re-run the parallelization gate. Compute speedup **after** merging — report the realistic number.

### Step 7: Define the shared contract

Before agents can work independently, they must agree on interfaces. The contract includes:
- **Types/interfaces** to be created (exact definitions)
- **API contracts** (request/response shapes, URL patterns, query params)
- **Prop interfaces** each component will accept
- **Import paths** agents will use

The contract should be concrete enough that all agents can write compatible code without seeing each other's output.

### Step 8: Assign personas per-agent

Glob available personas from `~/.claude/commands/set-persona/` and `.claude/personas/` (project-local). Match each agent to a persona by comparing the agent's domain (file paths, description, technologies involved) against persona filenames. Don't deep-read persona files to decide — filenames are the index (e.g., `react-frontend.md`, `java-backend.md`, `xrpl-typescript-fullstack.md`).

- Agents working on frontend components → frontend persona
- Agents working on API routes / backend logic → backend persona
- Agents working on shared types / foundation → the persona closest to the dominant consumer, or none
- If no persona is a strong fit for an agent, omit it — not every agent needs one

Add an optional `persona` field to each agent definition with the persona filename (without extension). The executor will read and include the persona content in the agent's prompt at launch time.

### Step 9: Design the branch strategy

Derive the branch strategy from the DAG:
- **Root agents** (no dependencies) → branch from `main`
- **Dependent agents** → branch from their (first) hard or soft dependency's branch
- **All PRs** → target `main` (never target another agent's branch)
- **Merge order** → topological sort of the DAG (root agents merge first, then dependents after rebasing onto updated main)
- **Branch naming** → `feat/<plan-slug>/<agent-name>` (e.g., `feat/bank-ref/foundation`)

For agents with multiple dependencies, branch from the dependency that is on the critical path (longest estimated duration).

### Step 10: Self-review checklist

Run through `analysis-guide.md` → "Self-Review Checklist" before writing the final plan. Key checks:
- No orphaned agents
- No linear-only DAGs without justification
- No agents under 50 lines
- No dependency installation delegated to agents
- Speedup computed after merges
- All prompts have concrete landmarks
- Required Bash Permissions section populated
- Branch Strategy section populated with per-agent branch names, merge order
- Persona assignments match agent domains (or explicitly omitted with reason)
- Review Notes populated for uncertain decisions (or section omitted if none)

Fix any failures before proceeding.

### Step 11: Write the parallel plan

Read `~/.claude/skill-references/agent-prompting.md` for best practices on prompt quality (speed, landmarks, scaling, TDD, boundaries). Write **two files** following the formats below. Present the plan file to the operator for review.

**File naming:** If the input plan is `my-plan.md`, write:
- `my-plan.plan.md` — the plan file
- `my-plan.prompts.md` — the prompts file

Both files include a cross-reference to each other.

---

## Parallel Plan Format

This is the contract between `/parallel-plan:make` (producer) and `/parallel-plan:execute` (consumer). The plan is split into two files: a **plan file** for review and status tracking, and a **prompts file** as the execution manifest.

### Plan File (`.plan.md`)

````markdown
# Parallel Plan: <title>

## Context
<Why this change is being made — the problem, what prompted it, intended outcome>

**Prompts:** `./<name>.prompts.md`

## Shared Contract

### Types
```typescript
// Exact type definitions that agents must agree on
export interface Foo { ... }
```

### API Contracts
```
GET /api/example?param=value → { field: Type[] }
```

### Import Paths
```
FooType → import from "@/lib/types"
barUtil → import from "@/lib/utils/bar"
```

## Agents

| Agent | Depends On | Description |
|-------|-----------|-------------|
| A: <short-name> | — | <1-sentence description> |
| B: <short-name> | A | <1-sentence description> |
| C: <short-name> | A | <1-sentence description> |
| D: <short-name> | B, C | <1-sentence description> |

## DAG Visualization

```
A ──┐
    ├──→ D ──→ E
B ──┘         ↑
C ────────────┘
```

## Pre-Execution Verification
<Commands to verify the project's toolchain works before launching agents>

```bash
<test command> --help        # or equivalent dry-run
<lint command> --help
```

## Required Bash Permissions

<Every distinct Bash command pattern that agents will need to run.
The executor verifies these against `.claude/settings.local.json`
before launching agents. Missing rules cause silent agent failures.>

```bash
<test-command> *           # e.g., Bash(pnpm test *)
<build-command>            # e.g., Bash(pnpm build)
<lint-command> *           # e.g., Bash(pnpm lint *)
<format-command> *         # e.g., Bash(npx prettier --write *)
```

## Critical Path Estimate

| Path | Agents | Estimated Wall-Clock |
|------|--------|---------------------|
| <longest path through DAG> | A → D → F | ~Xs |
| <second longest> | A → B → D → F | ~Xs |

Total sequential estimate: ~Xs
Parallel estimate: ~Xs (critical path)
Speedup: ~N.Nx

## Integration Tests

<2-3 specific cross-cutting scenarios that verify agents' outputs work together.
Each scenario should name the concrete data flow or interaction being tested.
Generic commands like "pnpm test" belong in Verification, not here.>

Example format:
1. **Domain flows through to API call**: Create an offer with `domainID` set → verify the API request includes `DomainID` field and the response reflects it back
2. **Hook passes domain to fetch**: Set `activeDomainID` in `useTradingData` → verify `useFetchMarketData` includes `?domain=` in its API call

## Verification
<How to test the changes end-to-end after execution>

## Branch Strategy

Base: <main-branch-name>

| Agent | Branch From | Branch Name | PR Target | Merge Order |
|-------|-------------|-------------|-----------|-------------|
| <letter> | main | feat/<plan-slug>/<agent-name> | main | 1 |
| <letter> | <dep-agent-letter> | feat/<plan-slug>/<agent-name> | main | 2 (after <dep>) |

After merge order N completes, rebase order N+1 branches onto main.

## Review Notes

<Flag decisions the planner was uncertain about. The executor's fresh-eyes review
will examine each flagged item. Omit this section if there are no uncertainties.>

- [ ] <description of uncertainty and reasoning>
- [ ] <e.g., "A→B is hard but might be soft — B only imports types from A">
- [ ] <e.g., "Agent C scope may be too large (est. 180s) — could split C1/C2">

## Execution State

_This section is managed by `/parallel-plan:execute`. Do not edit manually._

| Agent | Status | Agent ID | Duration | Notes |
|-------|--------|----------|----------|-------|
| <letter> | pending | — | — | |
| <letter> | pending | — | — | blocked by: <deps> |

Started: —
Last updated: —
Build: not yet run
````

### Prompts File (`.prompts.md`)

````markdown
# Agent Prompts: <title>

**Plan:** `./<name>.plan.md`

## Prompt Preamble

<Process instructions prepended to every agent prompt by the executor.
DO NOT duplicate the Shared Contract here — the executor automatically
prepends the Shared Contract section (from the plan file) followed by
this Prompt Preamble to each agent's prompt. This section should only
contain process instructions that apply to all agents: TDD workflow,
project commands, completion report format, and general rules.>

---

## <letter>: <short-name>

- **depends_on**: [] | [<agent-letters>]
- **soft_depends_on**: [] | [<agent-letters>]
- **persona**: <persona-name> | none (e.g., "react-frontend", "java-backend")
- **creates**: [<file-paths>]
- **modifies**: [<file-paths>]
- **deletes**: [<file-paths>]
- **estimated_duration**: <Xs> (e.g., "60s", "120s")
- **description**: <what this agent does, 1-2 sentences>
- **tdd_steps**:
    1. "<test description>" → `<test-file-path>::<test_name>`
    2. "<test description>" → `<test-file-path>::<test_name>`
    3. build-verify → "pnpm build" (use when TDD is impractical — see format rules)
- **prompt**: |
    <Full prompt to give the subagent. Include TDD workflow,
    file scope, shared contract excerpt, code landmarks for edits,
    and explicit DO NOT MODIFY boundaries.

    ## TDD Workflow (mandatory)

    For each change, follow RED → GREEN → REFACTOR:

    **Step 1: <description>**
    - RED: Write `<test_name>` in `<test-file>` that tests <behavior>. Run it — it MUST fail.
    - GREEN: Implement the minimal code in `<source-file>` to make the test pass.
    - REFACTOR: Clean up while tests stay green.

    **Step 2: <description>**
    ...

    Run tests after each phase to verify:
    - RED: test fails (function/class doesn't exist yet)
    - GREEN: test passes
    - REFACTOR: test still passes

    Before finishing, run the full test suite to catch regressions.

    ## Completion Report

    When done, end your output with a brief report:
    - Files created/modified
    - TDD steps completed (N/N)
    - Checkpoint: last completed step
    - Discoveries: any gotchas, surprises, or learnings that other agents
      or future work should know about>

---

## <letter>: <short-name>
...
````

### Format Rules

#### General (both files)

1. **Agents are lettered A-Z** — short identifiers for the DAG. Letters and names must match across both files.
2. **`depends_on`** lists hard dependencies (agent letters). Agent cannot start until these are fully completed and verified. Present in both files — the plan's agent summary table shows depends_on for DAG readability; the prompts file includes it for executor parsing.
3. **`soft_depends_on`** lists soft dependencies (agent letters). Agent can start as soon as the dependency's files exist on disk — it only needs the interface contract, not full verification. Omit if empty.
4. **No two agents share a file** in their creates/modifies/deletes lists.
5. **DAG visualization must match declarations** — every arrow in the visualization must correspond to a `depends_on` or `soft_depends_on` entry, and vice versa. Use `──→` for hard dependencies and `··→` (dotted) for soft dependencies.
6. **Cross-references are required** — the plan file includes `**Prompts:** ./<name>.prompts.md` in its Context section; the prompts file includes `**Plan:** ./<name>.plan.md` in its header.

#### Plan file (`.plan.md`)

7. **Agent summary table** — one row per agent with letter, name, depends_on, and a 1-sentence description. This is the reviewer's at-a-glance view of the DAG.
8. **Shared Contract is the single source of truth** — types, API shapes, import paths. The executor reads this from the plan file and prepends it to every agent prompt.
9. **Pre-Execution Verification section is required** — lists commands to validate the toolchain before any agents run.
10. **Integration Tests section is required** — must include 2-3 specific cross-cutting scenarios that name the concrete data flow being tested. Generic commands like "run all tests" are insufficient.
11. **Critical Path Estimate section is required** — shows the longest path through the DAG with estimated wall-clock time.
12. **Required Bash Permissions section is required** — lists every distinct Bash command pattern agents will need.
13. **Branch Strategy section is required** — defines per-agent branch names, branch-from sources, PR targets, and merge order.
14. **Review Notes section is optional but encouraged** — flags uncertain decisions for the executor's fresh-eyes review.
15. **Execution State is initialized by the executor** — the planner includes the template with one row per agent (all `pending`); the executor fills in runtime state. The executor also tracks live state in a `.parallel-plan-state.json` file alongside the plan.

#### Prompts file (`.prompts.md`)

16. **Prompt Preamble contains only process instructions** — TDD workflow template, project commands, completion report format, and general rules. DO NOT include the Shared Contract — the executor prepends it automatically from the plan file.
17. **File lists are exhaustive** — every file an agent touches must be listed in its creates/modifies/deletes, including test files.
18. **`estimated_duration` is required** — use the time estimates from analysis-guide.md.
19. **`tdd_steps` field is required** — lists each TDD cycle with the test name and path.
20. **`build-verify` is a valid tdd_steps entry** — use when TDD is impractical. Format: `build-verify → "<build command>"` with a parenthetical reason.
21. **Prompts are complete** — the executor prepends `Shared Contract + Prompt Preamble` automatically, then appends the agent's `prompt` field. Agent prompts should NOT duplicate the shared contract or preamble content.
22. **Prompts include agent-specific context** — landmarks, TDD steps, file scope, and DO NOT MODIFY boundaries.
23. **Prompts include explicit boundaries** — "DO NOT modify X" for files owned by other agents.
24. **Prompts include TDD workflow** — every agent prompt must specify RED → GREEN → REFACTOR steps with concrete test names and file paths.
25. **Prompts end with a Completion Report section** — agents must report files changed, TDD steps completed, checkpoint, and discoveries.
26. **`persona` field is optional per-agent** — assigned from `~/.claude/commands/set-persona/` or `.claude/personas/`. Set to `none` if no persona fits. The executor reads the persona file and includes its content at launch time.
27. **The prompts file is immutable after creation** — the executor never writes to it. All runtime state goes in the plan file's Execution State section or the `.parallel-plan-state.json` state file.

## Important Notes

- The goal is two files that `/parallel-plan:execute` can run mechanically — no interpretation needed
- The plan file is the **review surface** (~200-400 lines) — everything the operator needs to approve the architecture
- The prompts file is the **execution manifest** (~500-1000+ lines) — consumed by the executor, rarely read by humans
- If a step is too small for a subagent (< 5 lines changed), merge it into an adjacent agent that touches related files
- Shared utility files (`types.ts`, `constants.ts`) should have all changes consolidated into a single early agent
- The DAG visualization helps the operator understand the parallelism at a glance
