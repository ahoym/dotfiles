---
description: Analyze a sequential plan for parallelization opportunities and produce a structured parallel plan. Use when the user says "parallelize this plan", "make this parallel", or wants to split a plan into concurrent work streams.
---

# Make Parallel Plan

Analyze a plan for parallelization opportunities, build a dependency DAG, and output a structured parallel plan that `/parallel-plan:execute` can run.

## Usage

- `/parallel-plan:make <plan-file>` — Analyze and parallelize a plan file
- `/parallel-plan:make` — Analyze the most recently discussed plan

## Reference Files

- `analysis-guide.md` — Detailed methodology for file-conflict analysis, dependency types, DAG design, and agent splitting strategies
- `~/.claude/commands/_shared/agent-prompting.md` — Best practices for writing agent prompts (speed, landmarks, scaling, TDD, boundaries)

## Output

Writes a structured parallel plan to the plan file. The output follows the format defined in the **Parallel Plan Format** section below — this is the contract between this skill and `/parallel-plan:execute`.

## Instructions

### Step 1: Resolve the plan file

If arguments were provided (e.g., `/parallel-plan:make docs/plans/my-plan.md` or `/parallel-plan:make from .claude/plans/my-plan.md`), extract the file path from the arguments (strip any leading "from" prefix) and resolve it relative to the project root. Read that file as the input plan.

If no arguments were provided, use the plan most recently discussed in the conversation. If no plan has been discussed, ask the user which plan file to parallelize.

### Step 2: Analyze the plan for parallelism

Read the plan file. For each step, identify:
- **Files touched** (created, modified, deleted)
- **Dependencies** (which steps must complete before this one can start)

Build a **file-conflict matrix**: two steps conflict if they modify the same file. Steps that only create new files never conflict with each other.

Read `analysis-guide.md` for the detailed methodology.

### Step 3: Parallelization gate

Evaluate whether parallelization is worthwhile before investing in a full plan. See `analysis-guide.md` → "Parallelization Gate" for decision criteria and thresholds.

If the gate fails, inform the user and explain why. Offer to proceed for contract-enforcement benefits. Do NOT silently produce a plan with < 1.3x speedup.

### Step 4: Pre-flight dependency verification

Verify all required toolchain dependencies (test framework, build tools, linters) exist before writing agent prompts. See `analysis-guide.md` → "Pre-flight Dependency Verification".

If a dependency is missing, flag it to the user — never delegate installation to an agent.

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

### Step 8: Design the branch strategy

Derive the branch strategy from the DAG:
- **Root agents** (no dependencies) → branch from `main`
- **Dependent agents** → branch from their (first) hard or soft dependency's branch
- **All PRs** → target `main` (never target another agent's branch)
- **Merge order** → topological sort of the DAG (root agents merge first, then dependents after rebasing onto updated main)
- **Branch naming** → `feat/<plan-slug>/<agent-name>` (e.g., `feat/bank-ref/foundation`)

For agents with multiple dependencies, branch from the dependency that is on the critical path (longest estimated duration).

### Step 9: Self-review checklist

Run through `analysis-guide.md` → "Self-Review Checklist" before writing the final plan. Key checks:
- No orphaned agents
- No linear-only DAGs without justification
- No agents under 50 lines
- No dependency installation delegated to agents
- Speedup computed after merges
- All prompts have concrete landmarks
- Required Bash Permissions section populated
- Branch Strategy section populated with per-agent branch names, merge order
- Review Notes populated for uncertain decisions (or section omitted if none)

Fix any failures before proceeding.

### Step 10: Write the parallel plan

Read `~/.claude/commands/_shared/agent-prompting.md` for best practices on prompt quality (speed, landmarks, scaling, TDD, boundaries). Write the structured plan to the plan file following the format below. Present it to the user for review.

---

## Parallel Plan Format

This is the contract between `/parallel-plan:make` (producer) and `/parallel-plan:execute` (consumer).

````markdown
# Parallel Plan: <title>

## Context
<Why this change is being made — the problem, what prompted it, intended outcome>

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

## Prompt Preamble

<Process instructions prepended to every agent prompt by the executor.
DO NOT duplicate the Shared Contract here — the executor automatically
prepends the Shared Contract section followed by this Prompt Preamble
to each agent's prompt. This section should only contain process
instructions that apply to all agents: TDD workflow, project commands,
completion report format, and general rules.>

## Agents

### <letter>: <short-name>
- **depends_on**: [] | [<agent-letters>]
- **soft_depends_on**: [] | [<agent-letters>]
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

### <letter>: <short-name>
...

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

### Format Rules

1. **Agents are lettered A-Z** — short identifiers for the DAG
2. **`depends_on`** lists hard dependencies (agent letters). Agent cannot start until these are fully completed and verified.
3. **`soft_depends_on`** lists soft dependencies (agent letters). Agent can start as soon as the dependency's files exist on disk — it only needs the interface contract, not full verification. Omit if empty.
4. **File lists are exhaustive** — every file an agent touches must be listed, including test files
5. **No two agents share a file** in their creates/modifies/deletes lists
6. **Prompts are complete** — the executor prepends `Shared Contract + Prompt Preamble` automatically, then appends the agent's `prompt` field. Agent prompts should NOT duplicate the shared contract or preamble content.
7. **Prompts include agent-specific context** — landmarks, TDD steps, file scope, and DO NOT MODIFY boundaries. The shared contract is already provided via the preamble; agent prompts can reference it (e.g., "see Shared Contract above") instead of repeating it.
8. **Prompts include explicit boundaries** — "DO NOT modify X" for files owned by other agents
9. **Prompts include TDD workflow** — every agent prompt must specify RED → GREEN → REFACTOR steps with concrete test names and file paths
10. **`tdd_steps` field is required** — lists each TDD cycle with the test name and path, giving reviewers a quick summary without reading the full prompt
11. **`build-verify` is a valid tdd_steps entry** — use it when a function is impractical to unit-test (e.g., API route handlers that need a running server, UI wiring that only adds prop-threading). The agent must include an explicit justification in its prompt explaining why TDD is skipped for that step, and must run a type-check/build command instead. Format: `build-verify → "<build command>"` with a parenthetical reason, e.g., `build-verify → "pnpm build" (API route handler — tested via integration)`
12. **`estimated_duration` is required** — use the time estimates from analysis-guide.md. This enables the Critical Path Estimate section.
13. **Prompts end with a Completion Report section** — agents must report files changed, TDD steps completed, checkpoint, and discoveries
14. **Pre-Execution Verification section is required** — lists commands to validate the toolchain before any agents run
15. **Integration Tests section is required** — must include 2-3 specific cross-cutting scenarios that name the concrete data flow being tested. Generic commands like "run all tests" are insufficient — each scenario should describe what crosses agent boundaries and how to verify it.
16. **Critical Path Estimate section is required** — shows the longest path through the DAG with estimated wall-clock time, enabling reviewers to evaluate whether the parallelization is worthwhile
17. **DAG visualization must match declarations** — every arrow in the visualization must correspond to a `depends_on` or `soft_depends_on` entry, and vice versa. Use `──→` for hard dependencies and `··→` (dotted) for soft dependencies.
18. **Prompt Preamble contains only process instructions** — TDD workflow template, project commands, completion report format, and general rules. DO NOT include the Shared Contract in the preamble — the executor prepends `Shared Contract + Prompt Preamble` automatically. This avoids markdown code-fence nesting issues and keeps the contract as a single source of truth.
19. **`Execution State` is initialized by the executor** — the planner includes the section template with one row per agent (all `pending`), but the executor fills in actual status, agent IDs, and timestamps during execution. The executor tracks live state in a `.parallel-plan-state.json` file alongside the plan (lightweight, avoids repeated plan edits) and syncs results back to the plan's Execution State section at completion for archival.
20. **`Required Bash Permissions` section is required** — lists every distinct Bash command pattern agents will need, using the same `Bash(...)` syntax as `.claude/settings.local.json` allow patterns. The executor verifies these against settings before launching agents.
21. **`Branch Strategy` section is required** — defines per-agent branch names, branch-from sources, PR targets, and merge order. All PRs target `main`. Root agents (no deps) branch from `main`. Dependent agents branch from their dependency's branch (so they have upstream code). Merge order is derived from topological sort of the DAG. After upstream PRs merge, downstream branches rebase onto main. The executor uses this section to mechanically create branches, commits, and PRs as agents complete.
22. **`Review Notes` section is optional but encouraged** — the planner flags decisions they were uncertain about (dependency classifications, agent scope, landmark accuracy). The executor's fresh-eyes review examines each item. Omit the section entirely if there are no uncertainties.

## Important Notes

- The goal is a plan that `/parallel-plan:execute` can run mechanically — no interpretation needed
- If a step is too small for a subagent (< 5 lines changed), merge it into an adjacent agent that touches related files
- Shared utility files (`types.ts`, `constants.ts`) should have all changes consolidated into a single early agent
- The DAG visualization helps the user understand the parallelism at a glance
