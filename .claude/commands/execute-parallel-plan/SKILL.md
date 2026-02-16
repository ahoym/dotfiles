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

### Step 0: Pre-execution verification

Before launching any agents, verify the project's toolchain works. Read the plan's **Pre-Execution Verification** section and run the listed commands.

If any command fails, stop and report to the user — don't waste agent cycles on a broken toolchain.

### Step 1: Parse the plan

Read the parallel plan file. It must follow the structured format from `/make-parallel-plan`:
- **Shared Contract** section with types, API contracts, import paths
- **Agents** section with lettered agents, each having `depends_on`, `soft_depends_on`, file lists, descriptions, and prompts
- **Pre-Execution Verification** section
- **Integration Tests** section
- **DAG Visualization**

If the plan doesn't follow this format, ask the user to run `/make-parallel-plan` first.

### Step 2: Check for existing execution state

Look for an `## Execution State` section in the plan file.

- **If present with non-pending agents** — this is a **resumed execution**. Read the state to determine:
  - `completed` agents: skip these entirely — their work is already done. Create their tasks as already-completed so the DAG tracks them.
  - `in_progress` agents with an Agent ID: attempt to resume the agent using the `resume` parameter on the Task tool. If the agent completed, read output and verify. If stale (no recent progress in output file), re-launch with the same prompt.
  - `failed` agents: read the notes column for attempt history and checkpoint. Diagnose the failure, attempt to fix the underlying issue, then re-launch. If a checkpoint was recorded, instruct the new agent to resume from that step.
  - `pending` agents whose dependencies are all `completed`: these are ready to launch immediately.
- **If absent or all agents are pending** — this is a **fresh execution**. Initialize the Execution State section in the plan file using the Edit tool, populating one row per agent with status `pending` and noting `blocked by: <deps>` where applicable. Set `Started` to the current timestamp and `Last updated` to the same.

**State vocabulary**:
- `pending` — not yet started, may be blocked by dependencies
- `in_progress` — agent launched, awaiting completion
- `completed` — agent finished successfully, output verified
- `failed` — agent finished with errors, needs intervention or re-launch

### Step 3: Create the task DAG

Use `TaskCreate` for each agent. Set `blockedBy` according to each agent's `depends_on` list. This gives the user visibility into progress and maps the DAG into the task system.

Record the start timestamp (`date +%s`).

### Step 4: Launch ready agents

Identify all agents whose dependencies are satisfied and launch them **all simultaneously** in a single message using `Task` with `run_in_background: true`.

**Important: Background agents can use Bash but cannot prompt for permissions.** If a Bash command doesn't match a pre-configured allow pattern in settings, the agent silently fails. Before launching agents, verify that the project's test/build/lint commands have matching allow patterns in `.claude/settings.local.json` (e.g., `Bash(uv run pytest *)`). This is checked in Step 0's pre-execution verification.

An agent is **ready** when:
- All `depends_on` (hard) agents are `completed` (verified), AND
- All `soft_depends_on` agents have their files written to disk (the agent is at least `in_progress` and has created its output files — it doesn't need to be verified)

For soft dependencies, check that the dependency agent's `creates` files exist on disk before launching. If the soft dependency agent is still running but its files don't exist yet, wait.

Read `agent-prompting.md` before crafting prompts if you haven't already.

Each agent prompt must include:
1. The agent's specific task description
2. The shared contract (types, interfaces, API shapes) — copied from the plan, not referenced
3. Explicit file scope — what to create/modify and what NOT to touch
4. Code landmarks for edits (exact strings to match, not vague descriptions)
5. Test commands to run (must match pre-configured allow patterns)

### Step 5: Monitor and advance (the scheduling loop)

When an agent completes:

1. **Read the output** — verify the agent completed successfully. Look for the **Completion Report** at the end of the agent's output:
   - Files created/modified
   - TDD steps completed (N/N)
   - Checkpoint (last completed step)
   - Discoveries (gotchas, learnings for other agents or future work)
2. **Verify contract compliance** — read the key files the agent created/modified. Check:
   - Types match the shared contract
   - Exports are named correctly
   - File paths match what the plan specified
   - Tests exist for the agent's implementation (TDD was followed)
   - Test file paths match what the plan's `tdd_steps` specified
3. **Capture discoveries** — if the agent reported discoveries in its Completion Report, note them in the Execution State Notes column. If a discovery affects a pending agent's work, incorporate it into that agent's prompt when launching.
4. **Update task status** — mark the agent's task as completed
5. **Persist execution state** — use the Edit tool to update the plan file's Execution State table:
   - Set the agent's row: status → `completed` (or `failed`), Agent ID, Duration, and Notes (include checkpoint and discoveries)
   - Update the `Last updated` timestamp
   - This ensures the plan file always reflects current progress, enabling resumption if the session is interrupted
6. **Check for newly unblocked agents** — an agent is unblocked when:
   - All its `depends_on` (hard) agents are `completed`, AND
   - All its `soft_depends_on` agents have their output files on disk
7. **Launch newly unblocked agents** — immediately, in parallel if multiple are ready. When launching, update the agent's row to `in_progress` with the new Agent ID.
8. **Repeat** until all agents are complete

**Key principle: launch agents as soon as their specific dependencies are satisfied.** Don't wait for unrelated agents to finish. This is swim-lane scheduling, not batch phases.

**Soft dependency acceleration:** While waiting for hard-dependent agents to complete, periodically check if soft-dependent agents can start. A soft dependency is satisfied as soon as the dependency's `creates` files exist on disk — even if the dependency agent is still running (e.g., still in its REFACTOR phase). This lets downstream agents start sooner.

### Step 6: Handle failures

If an agent produces bad output:

1. **Diagnose** — read the output, identify what went wrong. Check the agent's Completion Report for its checkpoint (last completed step) and any error context.
2. **Record the attempt** — update the Execution State Notes column with a structured record:
   `attempt 1: <what failed and why>`. This prevents retrying the same approach and gives context if escalating to the user.
3. **Fix dependencies** — if the issue is a missing type, wrong import path, or incorrect file created by a predecessor agent, fix the dependency file first
4. **Re-prompt the agent** — resume the agent with additional context, or launch a new agent with a corrected prompt. If the agent reported a checkpoint, instruct the new agent to resume from that step rather than starting over.
5. **Max 3 attempts** — after 3 failed attempts for the same agent, mark it as `failed` in the Execution State with all attempt notes, and escalate to the user with the full attempt history.
6. **If unresolvable** — try to fix the issue directly (small fixes only), or escalate to the user

**Don't let a failed agent block the entire DAG.** If agent B fails but agent C is independent, C should still proceed.

### Step 7: Verify and report

After all agents complete:

1. **Run the project's build/compile command** to verify compilation
2. **Run integration tests** — execute the tests listed in the plan's **Integration Tests** section. These verify the pieces work together across agent boundaries, catching issues that per-agent TDD can't.
3. If build or integration tests fail, diagnose and fix — launch a targeted subagent for non-trivial fixes
4. Record the end timestamp
5. **Collect discoveries** — gather all discoveries reported by agents (from Completion Reports captured in the Notes column). Report these to the user as a consolidated list — they may be worth saving as project learnings.
6. **Finalize execution state** — use the Edit tool to update the plan file:
   - Set `Build` to `pass` or `fail (N attempts)`
   - Set `Integration` to `pass` or `fail (details)`
   - Ensure all agent rows reflect their final status
   - Update `Last updated` to the final timestamp
7. Report the execution scorecard:

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
| Integration tests | pass/fail (details) |
| Contract violations | none / description |
| Failure escalations | none / description |
| Max concurrency achieved | N agents |
| Discoveries | N items (see below) |

## Agent Discoveries
<Consolidated list of discoveries from all agents' Completion Reports.
 Each entry notes which agent reported it.>
```

## Important Notes

- **You are the coordinator, not an implementer** — delegate all code changes to subagents
- **Verify after every agent** — catch contract violations before they cascade to dependent agents
- **Launch eagerly** — as soon as an agent's dependencies are satisfied, launch it. Don't batch.
- **Prompts are self-contained** — each agent prompt includes everything the agent needs. Don't assume agents can read the plan file or see other agents' work.
- **Use haiku model** for simple agents (single file, small edit, < 30 lines changed) to minimize cost and latency
