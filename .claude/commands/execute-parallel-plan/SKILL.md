---
description: Execute a structured parallel plan using concurrent subagents with DAG-based scheduling. Use when the user says "execute this plan", "run this parallel plan", "execute parallel", or references a parallel plan file to execute.
---

# Execute Parallel Plan

Execute a structured parallel plan produced by `/make-parallel-plan`. Acts as a coordinator — launches subagents, verifies outputs, unblocks dependents, and handles failures.

## Usage

- `/execute-parallel-plan <plan-file>` — Execute a parallel plan file
- `/execute-parallel-plan` — Execute the most recently discussed parallel plan

## Reference Files

- `agent-prompting.md` — Read before crafting agent prompts for best practices on speed, landmarks, and boundaries

## Role: Coordinator

You are a **team lead**, not an implementer. Your job is to:
- Launch subagents when their dependencies are satisfied
- Read and verify each agent's output on completion
- Unblock dependent agents by launching them
- Resolve failures (fix dependencies, re-prompt agents)
- Track progress and report results

You should **never write implementation code directly**. All code changes go through subagents. This keeps your context focused on orchestration and lets you react to agent completions without blocking.

## Instructions

### Step 1: Parse the plan

Read the parallel plan file. It must follow the structured format from `/make-parallel-plan`:
- **Shared Contract** section with types, API contracts, import paths
- **Agents** section with lettered agents, each having `depends_on`, file lists, descriptions, and prompts
- **DAG Visualization**

If the plan doesn't follow this format, ask the user to run `/make-parallel-plan` first.

### Step 1.5: Check for existing execution state

**Resumption check**: Look for an `## Execution State` section in the plan file.

- **If present with non-pending agents** — this is a **resumed execution**. Read the state to determine:
  - `completed` agents: skip these entirely — their work is already done. Create their tasks as already-completed so the DAG tracks them.
  - `in_progress` agents with an Agent ID: attempt to resume the agent using the `resume` parameter on the Task tool. If the agent completed, read output and verify. If stale (no recent progress in output file), re-launch with the same prompt.
  - `failed` agents: read the notes column for context, diagnose the failure, attempt to fix the underlying issue, then re-launch.
  - `pending` agents whose dependencies are all `completed`: these are ready to launch immediately.
- **If absent or all agents are pending** — this is a **fresh execution**. Initialize the Execution State section in the plan file using the Edit tool, populating one row per agent with status `pending` and noting `blocked by: <deps>` where applicable. Set `Started` to the current timestamp and `Last updated` to the same.

**State vocabulary**:
- `pending` — not yet started, may be blocked by dependencies
- `in_progress` — agent launched, awaiting completion
- `completed` — agent finished successfully, output verified
- `failed` — agent finished with errors, needs intervention or re-launch

### Step 2: Create the task DAG

Use `TaskCreate` for each agent. Set `blockedBy` according to each agent's `depends_on` list. This gives the user visibility into progress and maps the DAG into the task system.

Record the start timestamp (`date +%s`).

### Step 3: Launch ready agents

Identify all agents with `depends_on: []` (no dependencies). Launch them **all simultaneously** in a single message using `Task` with `run_in_background: true`.

Read `agent-prompting.md` before crafting prompts if you haven't already.

Each agent prompt must include:
1. The agent's specific task description
2. The shared contract (types, interfaces, API shapes) — copied from the plan, not referenced
3. Explicit file scope — what to create/modify and what NOT to touch
4. Code landmarks for edits (exact strings to match, not vague descriptions)

### Step 4: Monitor and advance (the scheduling loop)

When an agent completes:

1. **Read the output** — verify the agent completed successfully
2. **Verify contract compliance** — read the key files the agent created/modified. Check:
   - Types match the shared contract
   - Exports are named correctly
   - File paths match what the plan specified
3. **Update task status** — mark the agent's task as completed
4. **Persist execution state** — use the Edit tool to update the plan file's Execution State table:
   - Set the agent's row: status → `completed` (or `failed`), Agent ID, Duration, and Notes
   - Update the `Last updated` timestamp
   - This ensures the plan file always reflects current progress, enabling resumption if the session is interrupted
5. **Check for newly unblocked agents** — find agents whose `depends_on` are ALL completed
6. **Launch newly unblocked agents** — immediately, in parallel if multiple are ready. When launching, update the agent's row to `in_progress` with the new Agent ID.
7. **Repeat** until all agents are complete

**Key principle: launch agents as soon as their specific dependencies complete.** Don't wait for unrelated agents to finish. This is swim-lane scheduling, not batch phases.

### Step 5: Handle failures

If an agent produces bad output:

1. **Diagnose** — read the output, identify what went wrong
2. **Fix dependencies** — if the issue is a missing type, wrong import path, or incorrect file created by a predecessor agent, fix the dependency file first
3. **Re-prompt the agent** — resume the agent with additional context, or launch a new agent with a corrected prompt
4. **If unresolvable** — try to fix the issue directly (small fixes only), or escalate to the user

**Don't let a failed agent block the entire DAG.** If agent B fails but agent C is independent, C should still proceed.

### Step 6: Verify and report

After all agents complete:

1. Run the project's build command (e.g., `pnpm build`) to verify compilation
2. If build fails, diagnose and fix — launch a targeted subagent for non-trivial fixes
3. Record the end timestamp
4. **Finalize execution state** — use the Edit tool to update the plan file:
   - Set `Build` to `pass` or `fail (N attempts)`
   - Ensure all agent rows reflect their final status
   - Update `Last updated` to the final timestamp
5. Report the execution scorecard:

```
## Execution Scorecard

| Agent | Task | Time | Tool Uses | Status |
|-------|------|------|-----------|--------|
| A     | ...  | 64s  | 10        | pass   |
| B     | ...  | 46s  | 8         | pass   |
| C     | ...  | 80s  | 10        | pass   |
| D     | ...  | 45s  | 7         | pass   |

| Metric | Value |
|--------|-------|
| Wall-clock time | Xs |
| Sum-of-parts time | Ys |
| Effective speedup | Y/X = Z.Zx |
| Build | pass/fail (attempts) |
| Contract violations | none / description |
| Failure escalations | none / description |
| Max concurrency achieved | N agents |
```

## Important Notes

- **You are the coordinator, not an implementer** — delegate all code changes to subagents
- **Verify after every agent** — catch contract violations before they cascade to dependent agents
- **Launch eagerly** — as soon as an agent's dependencies are satisfied, launch it. Don't batch.
- **Prompts are self-contained** — each agent prompt includes everything the agent needs. Don't assume agents can read the plan file or see other agents' work.
- **Use haiku model** for simple agents (single file, small edit, < 30 lines changed) to minimize cost and latency
