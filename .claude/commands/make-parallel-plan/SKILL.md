---
description: Analyze a sequential plan for parallelization opportunities and produce a structured parallel plan. Use when the user says "parallelize this plan", "make this parallel", or wants to split a plan into concurrent work streams.
---

# Make Parallel Plan

Analyze a plan for parallelization opportunities, build a dependency DAG, and output a structured parallel plan that `/execute-parallel-plan` can run.

## Usage

- `/make-parallel-plan <plan-file>` — Analyze and parallelize a plan file
- `/make-parallel-plan` — Analyze the most recently discussed plan

## Reference Files

- `analysis-guide.md` — Detailed methodology for file-conflict analysis, dependency types, DAG design, and agent splitting strategies

## Output

Writes a structured parallel plan to the plan file. The output follows the format defined in the **Parallel Plan Format** section below — this is the contract between this skill and `/execute-parallel-plan`.

## Instructions

### Step 1: Analyze the plan for parallelism

Read the plan file. For each step, identify:
- **Files touched** (created, modified, deleted)
- **Dependencies** (which steps must complete before this one can start)

Build a **file-conflict matrix**: two steps conflict if they modify the same file. Steps that only create new files never conflict with each other.

Read `analysis-guide.md` for the detailed methodology.

### Step 2: Design the agent DAG

Convert the file-conflict matrix and dependencies into a directed acyclic graph of agents. Each agent is an independent unit of work.

**Key principles:**
- **File boundary = agent boundary** — never let two agents modify the same file
- **New file creation is always safe** — agents creating new files never conflict
- **Minimize depth** (longest path through the DAG) — this is the floor for wall-clock time
- **Split large agents** on the critical path to reduce depth (see analysis-guide.md)
- **Dependencies are per-agent, not per-phase** — agent B depends on agent A specifically, not on "everything before it"

### Step 3: Define the shared contract

Before agents can work independently, they must agree on interfaces. The contract includes:
- **Types/interfaces** to be created (exact definitions)
- **API contracts** (request/response shapes, URL patterns, query params)
- **Prop interfaces** each component will accept
- **Import paths** agents will use

The contract should be concrete enough that all agents can write compatible code without seeing each other's output.

### Step 4: Write the parallel plan

Write the structured plan to the plan file following the format below. Present it to the user for review.

---

## Parallel Plan Format

This is the contract between `/make-parallel-plan` (producer) and `/execute-parallel-plan` (consumer).

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

## Agents

### <letter>: <short-name>
- **depends_on**: [] | [<agent-letters>]
- **creates**: [<file-paths>]
- **modifies**: [<file-paths>]
- **deletes**: [<file-paths>]
- **description**: <what this agent does, 1-2 sentences>
- **prompt**: |
    <Full prompt to give the subagent. Include file scope,
    shared contract excerpt, code landmarks for edits,
    and explicit DO NOT MODIFY boundaries.>

### <letter>: <short-name>
...

## DAG Visualization

```
A ──┐
    ├──→ D ──→ E
B ──┘         ↑
C ────────────┘
```

## Verification
<How to test the changes end-to-end after execution>

## Execution State

_This section is managed by `/execute-parallel-plan`. Do not edit manually._

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
2. **`depends_on`** lists agent letters, not phase numbers
3. **File lists are exhaustive** — every file an agent touches must be listed
4. **No two agents share a file** in their creates/modifies/deletes lists
5. **Prompts are complete** — the executor copies them verbatim to the subagent
6. **Prompts include the shared contract** — don't assume agents can read the plan header
7. **Prompts include explicit boundaries** — "DO NOT modify X" for files owned by other agents
8. **`Execution State` is initialized by the executor** — the planner includes the section template with one row per agent (all `pending`), but the executor fills in actual status, agent IDs, and timestamps during execution

## Important Notes

- The goal is a plan that `/execute-parallel-plan` can run mechanically — no interpretation needed
- If a step is too small for a subagent (< 5 lines changed), merge it into an adjacent agent that touches related files
- Shared utility files (`types.ts`, `constants.ts`) should have all changes consolidated into a single early agent
- The DAG visualization helps the user understand the parallelism at a glance
