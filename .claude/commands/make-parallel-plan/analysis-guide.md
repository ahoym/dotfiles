# Analysis Guide: Identifying Parallelism in Plans

## File-Conflict Matrix

For each step in the plan, list every file it touches — **including test files**. Then build a matrix:

```
                   step1  step2  step3  step4  step5
src/file-a           M                    M
src/file-b                  C
test/file-a.test     C                    M
test/file-b.test            C
test/helpers         M             M             M
src/file-c                         M             M
```

Legend: M = modify, C = create, D = delete

**Conflict rules:**
- Two M's in the same row = conflict (can't run in parallel)
- C + C in the same row = conflict (same new file)
- M + C or M + D = conflict
- C in one row, M in another row = no conflict (different files)
- A step that only creates NEW files never conflicts with steps that only modify EXISTING files

**Test file ownership:** Each agent owns its test files alongside its source files. When building the matrix, include the test files the agent will create or modify. Shared test infrastructure (e.g., `conftest.py`, shared fixtures) should be consolidated into an early agent, just like shared utility files.

## Dependency Types

### Hard dependencies (`depends_on`)
Agent B needs Agent A's work to be **fully completed and verified** before starting. Use when:
- Agent B imports and calls functions that Agent A implements (not just type signatures)
- Agent B modifies files that Agent A also modifies (sequential access)
- Agent B needs Agent A's tests to pass to validate its own assumptions

### Soft dependencies (`soft_depends_on`)
Agent B only needs Agent A's **interface contract** (types, signatures, file structure) — not the full implementation. Use when:
- Agent B imports types/interfaces that Agent A creates (just needs the file to exist)
- Agent B implements against a protocol/interface that Agent A defines
- Agent B creates a component that accepts props defined by Agent A's types

The executor can start soft-dependent agents as soon as the dependency's files are written to disk, without waiting for full verification. This reduces wall-clock time on deep DAGs.

```
# Hard: B waits for A to fully complete
A (60s, verified) ──→ B (50s) → total: 110s

# Soft: B starts as soon as A's files exist (~30s into A's run)
A (60s) ──soft──→ B (50s, starts at ~30s) → total: ~80s
```

### Integration dependencies
A "wiring" agent that connects outputs from multiple agents (e.g., passing props from parent to children modified by separate agents). Integration agents almost always use hard dependencies.

### Interface-first pattern

When the plan introduces shared types or test fixtures that multiple agents depend on, create a small, fast **Agent A** dedicated solely to defining these. This agent:
- Creates type/interface definition files and shared test helpers
- Has no dependencies itself
- Completes quickly (< 60s), unblocking the rest of the DAG
- All other agents soft-depend on it (they just need the types to exist)

```
A (types, 30s) ──soft──┬──→ B (implementation)
                       ├──→ C (implementation)
                       └──→ D (implementation) ──hard──→ E (integration)
```

This is the highest-impact parallelism pattern — one fast agent unblocks many concurrent agents.

## DAG Design

### Think in swim lanes, not phases

Instead of grouping agents into sequential phases, define a dependency DAG where each agent lists its specific predecessors. This allows agents to start as soon as their individual dependencies complete, rather than waiting for an entire phase.

**Batch phases (suboptimal):**
```
Phase 1: [A(60s), C(80s)]  → wait for both → 80s
Phase 2: [B(50s)]           → B depends only on A, but waits for C too → 130s
Phase 3: [D(30s)]           → 160s total
```

**Swim lanes (optimal):**
```
A(60s) ──→ B(50s) ──→ D(30s)
C(80s) ───────────────→↑

A done at 60s → B starts immediately (doesn't wait for C)
B done at 110s, C done at 80s → D starts at 110s
Total: 140s (saved 20s)
```

### Common DAG Patterns

**Pattern 1: Fan-out / Fan-in**
Most common. Independent work fans out, then an integration agent fans in.
```
A ──┐
B ──┼──→ E (integration)
C ──┤
D ──┘
```

**Pattern 2: Pipeline with parallel branches**
A foundation agent, then parallel work, then integration.
```
A (setup) ──→ B ──┐
         └──→ C ──┼──→ E (integration)
              D ──┘
```
Here B depends on A, but C and D are independent. D can start immediately.

**Pattern 3: Diamond**
Two parallel streams that converge.
```
A ──→ B ──┐
C ──→ D ──┼──→ E
```

## Splitting Large Agents

If one agent dominates the critical path, consider splitting it:

**Before:** Agent D touches 5 files, estimated ~140s
**After:** Agent D1 (3 new files, ~60s) + Agent D2 (2 modifications, ~80s)

**Split criteria:**
- The agent creates new files AND modifies existing files → split into "create" and "modify" agents
- The agent modifies files that have no dependency between them → split by file
- The agent has a clear sequential sub-structure → split at the natural boundary

**Don't split when:**
- The files within the agent reference each other (one imports from another being created)
- The overhead of two agents exceeds the time saved
- The agent is already < 60s estimated

## Estimating Agent Time

Based on observed patterns. TDD adds ~40-60% overhead per agent due to writing tests first, verifying RED/GREEN phases, and running test commands.

| Task type | Expected time | Expected tool uses |
|-----------|---------------|-------------------|
| Single file, small edit + test | 40-55s | 6-10 |
| Single file, complex edit + test | 70-100s | 14-20 |
| Create 1 new file + test (< 100 lines) | 40-65s | 6-10 |
| Create 1 new file + test (> 200 lines) | 90-140s | 14-20 |
| Create 2-3 new files + tests + modify 1-2 | 150-220s | 25-38 |
| Integration (wire + integration tests) | 120-160s | 22-32 |

### Wall-Clock Reality

Subagents run with partial concurrency, not true parallelism. Observed behavior:
- **2 concurrent agents**: wall-clock ≈ 0.7-0.8x sum of individual times
- **3 concurrent agents**: wall-clock ≈ 0.6-0.8x sum of individual times
- **Speedup is real but modest** — expect 1.5-2x for 3 agents, not 3x

Factor this into critical path estimates. The value of parallelization comes from:
1. Speedup (even if modest)
2. Contract enforcement (agents can't accidentally couple)
3. Reduced context window pressure (each agent has focused context)

## Common Pitfalls

1. **Forgetting the integration agent**: Component agents add new props, but someone must pass them from the parent. Always plan for this.

2. **Implicit file dependencies**: Agent A modifies `types.ts` and Agent B also needs to modify `types.ts` for a different type → conflict. Solution: assign all `types.ts` changes to a single early agent.

3. **Import chain dependencies**: Agent A creates `utils/foo.ts`, Agent B modifies `component.tsx` to import from `utils/foo.ts`. These don't conflict on files, but B depends on A (the import target must exist). Mark this as a dependency.

4. **Shared utility files**: Files like `types.ts`, `constants.ts`, `index.ts` are often touched by multiple steps. Consolidate all changes to these files into a single agent.

5. **Over-splitting**: Creating 6 agents for 200 lines of total code. Agent overhead (prompt processing, file reads) means tiny agents can be slower than merging them. Minimum viable agent: ~30 lines of meaningful changes.

6. **Shared test infrastructure**: Files like test helpers, shared fixtures, or test utilities (e.g., `conftest.py`, `test-utils.ts`, `testhelpers_test.go`) are often needed by multiple agents. Consolidate all changes to shared test files into an early agent (just like shared utility files). Each agent should own its own test files but depend on the agent that sets up shared fixtures.

7. **TDD overhead in splitting decisions**: With TDD, each agent has more tool uses (write test → run test → write code → run test → refactor → run test). Factor this into the minimum viable agent size — an agent with a single 5-line edit now involves ~6-10 tool uses with TDD, so the merge threshold is higher.
