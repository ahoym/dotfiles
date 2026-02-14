# Parallel Execution Learnings

## Resumable In-File Execution State

When running parallel plans with multiple subagents (via `/execute-parallel-plan`), execution can be interrupted by session ends, user pauses, or agent failures requiring manual triage. To enable resumability, persist an `## Execution State` section directly in the plan file.

### The Pattern

Add a state table to the plan file that tracks each agent's lifecycle:

| Agent | Status | Agent ID | Duration | Notes |
|-------|--------|----------|----------|-------|
| A | completed | agent-abc123 | 45s | |
| B | in_progress | agent-def456 | — | |
| C | pending | — | — | blocked by: B |

Plus metadata:
- `Started`: timestamp of first execution
- `Last updated`: timestamp of most recent state change
- `Build`: `not yet run` / `pass` / `fail (N attempts)`

### Why In-File (Not Separate State)

- **Single source of truth** — the plan file already contains the agent definitions, DAG, and prompts. Adding state keeps everything together.
- **Human-readable** — a user can open the plan file and immediately see what completed, what's stuck, and what's next.
- **No cleanup needed** — no separate state files to track or delete.
- **Git-friendly** — state changes show up in diffs if the plan is version-controlled.

### State Vocabulary

- `pending` — not yet started, may be blocked by dependencies
- `in_progress` — agent launched, awaiting completion (Agent ID stored for resume)
- `completed` — agent finished successfully, output verified
- `failed` — agent finished with errors, needs intervention or re-launch

### Resumption Logic

On startup, the executor checks the Execution State section:
1. **All pending** → fresh execution, initialize timestamps
2. **Mixed states** → resumed execution:
   - Skip `completed` agents (create tasks as already-done for DAG tracking)
   - Resume `in_progress` agents via Task tool's `resume` parameter; re-launch if stale
   - Diagnose and re-launch `failed` agents
   - Launch `pending` agents whose dependencies are all `completed`

### Update Discipline

State must be persisted after **every** agent event (launch, completion, failure) — not just at the end. This ensures that even if the session dies mid-execution, the plan file reflects the last known good state.
