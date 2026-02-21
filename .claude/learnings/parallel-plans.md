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
