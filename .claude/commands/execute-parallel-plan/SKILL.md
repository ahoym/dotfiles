---
description: Execute a structured parallel plan using concurrent subagents with DAG-based scheduling. Use when the user says "execute this plan", "run this parallel plan", "execute parallel", or references a parallel plan file to execute.
---

# Execute Parallel Plan

Execute a structured parallel plan produced by `/make-parallel-plan`. Acts as a coordinator — launches subagents, verifies outputs, unblocks dependents, and handles failures.

## Usage

- `/execute-parallel-plan <plan-file>` — Execute a parallel plan file
- `/execute-parallel-plan` — Execute the most recently discussed parallel plan

## Role: Coordinator

You are a **team lead**, not an implementer. Your job is to:
- Launch subagents when their dependencies are satisfied
- Read and verify each agent's output on completion
- Unblock dependent agents by launching them
- Resolve failures (fix dependencies, re-prompt agents)
- Track progress and report results

You should **never write implementation code directly**. All code changes go through subagents. This keeps your context focused on orchestration and lets you react to agent completions without blocking.

## Instructions

### Step 0: Fresh-eyes plan review

Before doing anything else, perform a structured review of the plan with fresh eyes. You are reading this plan for the first time — use that perspective to catch issues the planner may have missed due to context fatigue or tunnel vision.

1. **Read the full plan** — internalize the context, shared contract, DAG structure, and every agent prompt. Understand the overall shape of the change.
2. **Re-read source files** — for each agent that modifies existing files, read those files and verify:
   - Code landmarks in the prompt still match the actual code (function names, line numbers, surrounding context)
   - The file structure hasn't changed since the plan was written
   - Import paths referenced in the plan are correct
3. **Audit dependencies** — for each `depends_on` (hard dependency), ask: does the downstream agent truly need the upstream to be fully completed and verified, or would it suffice for the upstream's files to exist on disk (soft dependency)? Flag any hard dependencies that could be downgraded.
4. **Check agent scope balance** — flag agents that seem too large (> 200s estimated, touching 5+ files) or too small (< 30 lines of changes). Suggest splits or merges.
5. **Review the Review Notes** — if the planner included a **Review Notes** section, examine each flagged uncertainty and form your own judgment.
6. **Check Required Bash Permissions** — read the plan's **Required Bash Permissions** section. Verify each listed command pattern has a matching allow rule in `.claude/settings.local.json`. If any are missing, stop and tell the user — agents will silently fail without these permissions.
7. **Present findings** — report your review to the user:
   - Issues found (stale landmarks, wrong dependencies, scope imbalances)
   - Proposed adjustments (with rationale)
   - Planner's flagged uncertainties and your assessment
   - Permission gaps (if any)
   - Or: "Plan looks good, no issues found" — don't invent problems
8. **Get approval** — wait for the user to approve the plan (with or without your suggested adjustments) before proceeding. If the user approves adjustments, apply them to the plan file before continuing.

Do NOT skip this step. The value of a fresh session is the fresh perspective — use it.

### Step 1: Pre-execution verification

Before launching any agents, verify the project's toolchain works. Read the plan's **Pre-Execution Verification** section and run the listed commands.

Also check for a code formatter:
- Look for `.prettierrc`, `.prettierrc.json`, `biome.json`, or a `format`/`format:check` script in `package.json` (or equivalents for other ecosystems)
- If found, note the format command — you'll need to either include it in each agent's prompt or run it as a post-completion step in Step 8

**Check Edit/Write permissions:** Background agents cannot prompt for tool permissions. Read `.claude/settings.local.json` and verify that `"Edit"` and `"Write"` appear in the `permissions.allow` array. If either is missing, stop and tell the user — agents need these to modify files and will silently fail without them.

If any command fails or permissions are missing, stop and report to the user — don't waste agent cycles on a broken toolchain.

### Step 2: Parse the plan

Read the parallel plan file. It must follow the structured format from `/make-parallel-plan`:
- **Shared Contract** section with types, API contracts, import paths
- **Prompt Preamble** section (optional) with process instructions common to all agents (TDD workflow, project commands, completion report format, general rules). This does NOT contain the shared contract — the contract is a separate section.
- **Agents** section with lettered agents, each having `depends_on`, `soft_depends_on`, file lists, descriptions, and prompts
- **Pre-Execution Verification** section
- **Integration Tests** section
- **DAG Visualization**
- **Required Bash Permissions** section
- **Review Notes** section (optional — planner's flagged uncertainties)

Extract and store the **Shared Contract** and **Prompt Preamble** sections — you will prepend these to every agent prompt in Step 5.

If the plan doesn't follow this format, ask the user to run `/make-parallel-plan` first.

### Step 3: Check for existing execution state

Execution state is tracked in a **lightweight state file** (`.parallel-plan-state.json`) alongside the plan file, not by editing the plan markdown. This avoids fragmenting the coordinator's attention with repeated plan edits.

**State file location:** Same directory as the plan file, named `.parallel-plan-state.json`.

**State file schema:**
```json
{
  "started": "2026-02-18 12:00:00",
  "lastUpdated": "2026-02-18 12:05:00",
  "build": "not yet run",
  "integration": "not yet run",
  "agents": {
    "A": { "status": "pending", "agentId": null, "duration": null, "notes": "" },
    "B": { "status": "pending", "agentId": null, "duration": null, "notes": "blocked by: A" }
  }
}
```

- **If the state file exists with non-pending agents** — this is a **resumed execution**. Read the state to determine:
  - `completed` agents: skip these entirely — their work is already done. Create their tasks as already-completed so the DAG tracks them.
  - `in_progress` agents with an Agent ID: attempt to resume the agent using the `resume` parameter on the Task tool. If the agent completed, read output and verify. If stale (no recent progress in output file), re-launch with the same prompt.
  - `failed` agents: read the notes field for attempt history and checkpoint. Diagnose the failure, attempt to fix the underlying issue, then re-launch. If a checkpoint was recorded, instruct the new agent to resume from that step.
  - `pending` agents whose dependencies are all `completed`: these are ready to launch immediately.
- **If the state file doesn't exist** — this is a **fresh execution**. Create the state file with one entry per agent, all `pending`, noting `blocked by: <deps>` where applicable.

Update the state file whenever an agent's status changes (batch updates when multiple things happen at once). At the end of execution, also update the plan file's `## Execution State` section with the final results for archival.

**State vocabulary**:
- `pending` — not yet started, may be blocked by dependencies
- `in_progress` — agent launched, awaiting completion
- `completed` — agent finished successfully, output verified
- `failed` — agent finished with errors, needs intervention or re-launch

### Step 4: Create the task DAG

Use `TaskCreate` for each agent. Set `blockedBy` according to each agent's `depends_on` list. This gives the user visibility into progress and maps the DAG into the task system.

Record the start timestamp (`date +%s`).

### Step 5: Launch ready agents

Identify all agents whose dependencies are satisfied and launch them **all simultaneously** in a single message using `Task` with `run_in_background: true`.

**Important: Background agents cannot prompt for permissions.** If a Bash command doesn't match a pre-configured allow pattern, or if `Edit`/`Write` tools aren't in the allow list, the agent silently fails. This is verified during Step 0 (plan review) and Step 1 (pre-execution verification) — do not skip those checks.

An agent is **ready** when:
- All `depends_on` (hard) agents are `completed` (verified), AND
- All `soft_depends_on` agents have their files written to disk (the agent is at least `in_progress` and has created its output files — it doesn't need to be verified)

For soft dependencies, check that the dependency agent's `creates` files exist on disk before launching. If the soft dependency agent is still running but its files don't exist yet, wait.

**Model selection:** Before launching each agent, evaluate its complexity and choose the appropriate model. The plan may suggest models, but the coordinator makes the final call based on actual scope. Override aggressively.
- **haiku**: Single file, small edit (< 30 lines), straightforward test. Also good for agents that follow an existing pattern or have only `build-verify` TDD steps.
- **sonnet**: Default for most agents. Handles TDD workflow reliably.
- **opus**: Complex logic, large new files (> 200 lines), or non-trivial test design (async behavior, complex mocking).

**Discovery propagation:** Before launching each agent, review discoveries reported by all completed predecessor agents (from the state file's notes). If any discovery is relevant to the agent being launched, incorporate it into the prompt. For example, if Agent A discovered "the API returns dates as ISO strings," and Agent B consumes that API, add that fact to Agent B's prompt.

**Formatting:** If a project formatter was detected in Step 1, include the format command in each agent's prompt as a final step before the test suite. Alternatively, you may run formatting once as a post-completion step in Step 8 — but per-agent is preferred because it catches issues earlier and keeps each agent's output clean.

**Prompt construction:** For each agent, build the full prompt by concatenating:
1. **Shared Contract** — the full Shared Contract section from the plan (types, API contracts, import paths)
2. **Prompt Preamble** — the Prompt Preamble section from the plan (TDD workflow, project commands, completion report format), if present
3. **Agent prompt** — the agent's `prompt` field from the plan

This ensures every agent sees the shared contract and common instructions without the planner having to duplicate them in each agent's prompt. The agent's `prompt` field focuses on agent-specific work: task description, landmarks, TDD steps, file scope, and DO NOT MODIFY boundaries.

If the plan has no Prompt Preamble section, fall back to the previous behavior: each agent's prompt must be self-contained with all necessary context.

### Step 6: Monitor and advance (the scheduling loop)

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
5. **Persist execution state** — update the state file (`.parallel-plan-state.json`):
   - Set the agent's status → `completed` (or `failed`), agentId, duration, and notes (include checkpoint and discoveries)
   - Update the `lastUpdated` timestamp
   - Batch multiple updates when possible (e.g., marking agent complete + noting newly unblocked agents)
   - This ensures the state file always reflects current progress, enabling resumption if the session is interrupted
6. **Check for newly unblocked agents** — an agent is unblocked when:
   - All its `depends_on` (hard) agents are `completed`, AND
   - All its `soft_depends_on` agents have their output files on disk
7. **Launch newly unblocked agents** — immediately, in parallel if multiple are ready. When launching, update the agent's row to `in_progress` with the new Agent ID.
8. **Repeat** until all agents are complete

**Key principle: launch agents as soon as their specific dependencies are satisfied.** Don't wait for unrelated agents to finish. This is swim-lane scheduling, not batch phases.

**Soft dependency acceleration:** While waiting for hard-dependent agents to complete, periodically check if soft-dependent agents can start. A soft dependency is satisfied as soon as the dependency's `creates` files exist on disk — even if the dependency agent is still running (e.g., still in its REFACTOR phase). This lets downstream agents start sooner.

### Step 7: Handle failures

If an agent produces bad output, follow the **escalation ladder** — each attempt increases coordinator involvement:

1. **Diagnose** — read the output, identify what went wrong. Check the agent's Completion Report for its checkpoint (last completed step) and any error context.
2. **Record the attempt** — update the state file notes with a structured record:
   `attempt 1: <what failed and why>`. This prevents retrying the same approach and gives context if escalating to the user.
3. **Fix dependencies** — if the issue is a missing type, wrong import path, or incorrect file created by a predecessor agent, fix the dependency file first.

**Attempt 1: Resume with error context.** Resume the agent using its agent ID with a message explaining what went wrong. Often the agent just hit a transient issue or made a small mistake it can self-correct. Tell it to start from its checkpoint.

**Attempt 2: Relaunch with corrected prompt.** Launch a fresh agent with a *corrected* prompt — incorporate what went wrong, adjust the approach (e.g., different import path, simpler type cast, explicit code snippet for the failing section), and tell it to start from the checkpoint rather than step 1.

**Attempt 3: Reduce scope.** Split the failing agent's remaining work into a smaller piece. Do the blocking part manually (small fix only — you're the coordinator, not the implementer, but a 1-2 line fix to unblock is acceptable), then relaunch for the rest. Or split into two simpler agents.

**After 3 attempts:** Mark as `failed` in the state file with all attempt notes, and escalate to the user with the full attempt history.

**Don't let a failed agent block the entire DAG.** If agent B fails but agent C is independent, C should still proceed.

### Step 8: Verify and report

After all agents complete:

1. **Run the project formatter** (if detected in Step 1) on all changed files. This catches formatting inconsistencies across agents before the build step. If you didn't include the formatter in each agent's prompt, this is your safety net.
2. **Run the project's build/compile command** to verify compilation
3. **Run integration tests** — execute the tests listed in the plan's **Integration Tests** section. These verify the pieces work together across agent boundaries, catching issues that per-agent TDD can't.
4. If build, formatting, or integration tests fail, diagnose and fix — launch a targeted subagent for non-trivial fixes
5. Record the end timestamp
6. **Collect discoveries** — gather all discoveries reported by agents (from the state file notes). Report these to the user as a consolidated list — they may be worth saving as project learnings.
7. **Finalize execution state** — update the state file, then sync the final results to the plan file's `## Execution State` section using the Edit tool (for archival):
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
- **Prompts are self-contained** — each agent receives `Shared Contract + Prompt Preamble + Agent Prompt`, which together include everything the agent needs. Don't assume agents can read the plan file or see other agents' work.
