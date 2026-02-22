# Parallel Plan Execution Learnings

## DAG Shape Bounds Speedup

Parallel plan speedup is bounded by the **DAG shape** (critical path), not by tooling or agent speed. Before optimizing agent prompts or model selection, analyze the critical path to know the ceiling.

**How to analyze:**
1. Compute the critical path: the longest chain of hard-dependent agents
2. Sum their durations — this is the minimum wall-clock time (theoretical floor)
3. Compare to actual wall-clock — if they're close, the scheduler is already near-optimal
4. Speedup = sum-of-all-agents / critical-path-time

**Example from credential management (4 agents):**
```
A (242s) ──→ B (77s)     ← off critical path (leaf)
A (242s) ──┐
            ├──→ D (117s) ← critical path: A→D = 359s
C (235s) ──┘
```
- Critical path: 359s, actual: ~370s (near-optimal)
- Sum of parts: 671s → speedup: 1.8x
- The 1.8x is a property of the work distribution, not a missed optimization

**How to improve speedup:**
- Split agents on the critical path (e.g., split A into A1+A2 so downstream starts sooner)
- Use soft dependencies to start agents before hard deps fully verify
- Design features with more independent pieces (wider DAG = more parallelism)
- Note: features with inherent layering (types → logic → UI) have natural parallelism ceilings

## Soft Deps for Type-Appending Agents

When Agent A **modifies** (appends to) an existing type file like `lib/types.ts`, downstream agents that import those types in **new files** they create should use `soft_depends_on`, not `depends_on`.

**Why soft works:** The file already exists on disk. Once A writes its additions, the updated types are immediately available for import. Soft dep means "start once A's files are written" — the downstream agent doesn't need to wait for A's full build-verify to pass.

**When hard is needed instead:** If the downstream agent also **modifies** the same file (file conflict), or if it needs verified behavior (not just type signatures) from A's output.

**Example:**
```
A modifies: lib/types.ts (appends AmmPoolInfo interface)
G creates:  app/components/pool-panel.tsx (imports AmmPoolInfo)
→ G soft_depends_on A ✓ (G creates a new file, only needs types on disk)

A modifies: lib/api.ts (extends txFailureResponse signature)
D creates:  app/api/create/route.ts (calls txFailureResponse)
→ D depends_on A ✓ (D needs the actual function to compile, hard is safer)
```


## Context Continuation Loses File Contents

When a session is continued from a compacted conversation (context overflow), **all file contents read in the prior session are lost**. The conversation summary preserves metadata (file paths, line numbers, key findings) but not the actual file text.

**Impact on `/parallel-plan:make`:** The planner must re-read all source files to get accurate landmarks (line numbers, surrounding code context) for agent prompts. Budget 2-5 minutes for re-reading depending on codebase size.

**Mitigation:** The conversation summary should capture critical landmarks explicitly (e.g., "txFailureResponse is at line 200-209 in lib/api.ts"). This reduces re-reading to verification rather than discovery.
