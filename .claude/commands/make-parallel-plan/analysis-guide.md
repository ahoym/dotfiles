# Analysis Guide: Identifying Parallelism in Plans

## File-Conflict Matrix

For each step in the plan, list every file it touches. Then build a matrix:

```
         step1  step2  step3  step4  step5
file-a     M                    M
file-b            C
file-c                   M             M
file-d            C      C
```

Legend: M = modify, C = create, D = delete

**Conflict rules:**
- Two M's in the same row = conflict (can't run in parallel)
- C + C in the same row = conflict (same new file)
- M + C or M + D = conflict
- C in one row, M in another row = no conflict (different files)
- A step that only creates NEW files never conflicts with steps that only modify EXISTING files

## Dependency Types

### Data dependencies
Agent B reads output produced by Agent A (e.g., B imports a type that A creates).

### Interface dependencies
Agent B implements an interface that Agent A defines (e.g., B creates a component accepting props that A's type defines).

### Integration dependencies
A "wiring" agent that connects outputs from multiple agents (e.g., passing props from parent to children modified by separate agents).

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

Based on observed patterns:

| Task type | Expected time | Expected tool uses |
|-----------|---------------|-------------------|
| Single file, small edit | 20-30s | 3-5 |
| Single file, complex edit | 45-60s | 8-12 |
| Create 1 new file (< 100 lines) | 20-40s | 3-6 |
| Create 1 new file (> 200 lines) | 60-90s | 8-12 |
| Create 2-3 new files + modify 1-2 | 100-150s | 18-25 |
| Integration (wire props in 2-3 files) | 80-100s | 15-22 |

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
