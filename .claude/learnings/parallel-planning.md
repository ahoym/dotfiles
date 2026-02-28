# Parallel Planning Patterns

## Leaf/Orphaned Agent Tradeoff

When an agent has no downstream dependents (`depends_on` from other agents), it's "orphaned" — its failure only surfaces during final verification.

**Decision criteria:**
- **Keep separate** if parallel speedup > ~40s AND agent has its own tests (failures caught by final `pytest`)
- **Merge into adjacent agent** if agent is tiny (<50 lines) or the parallelism gain is negligible
- **Always document in Review Notes** — flag the tradeoff explicitly so the executor can re-evaluate

Example: Agent D (fireblocks destination config, ~70s) runs parallel with B+C. Merging into E would serialize it after C, adding ~40s to critical path. Keep separate, flag as leaf.

## Context Continuation for parallel-plan:make

When `/parallel-plan:make` spans a context boundary (session compaction or continuation), the session summary captures DAG design decisions (agent ownership, dependency types, speedup) but NOT file-level details needed for agent prompts (line numbers, surrounding code, exact function signatures).

**Impact:** The agent must re-read all target files (~15 reads for a 5-agent plan) to produce concrete landmarks. Budget ~5 minutes of file reads before writing the plan.

**Mitigation:** If the plan is large, consider writing the DAG structure and shared contract first (they don't need line-level detail), then the agent prompts in a second pass after re-reading files.
