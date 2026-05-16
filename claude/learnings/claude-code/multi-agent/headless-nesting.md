Nested headless `claude -p` sessions — multi-tier agent hierarchies where sessions spawn their own child sessions.

**Keywords:** claude -p, nesting, headless, multi-tier, VP, Director, Worker, Subagent, --allowedTools, hierarchy
**Related:** none

## Arbitrary Nesting Depth

`claude -p` sessions have Bash tool access, so they can run `claude -p` themselves. This enables multi-tier hierarchies: VP → Director → Worker → Subagent (verified at 4 tiers). No technical ceiling — depth is bounded only by cost and latency.

## `--allowedTools` Is Mandatory at Every Level

Headless sessions auto-deny any tool not pre-allowed (no human to approve). **`settings.local.json` Write patterns do not work in headless `claude -p` sessions** — verified with controlled test (pattern present, Write denied; same session with `--allowedTools Write` succeeds). Bash patterns from `settings.local.json` DO propagate (ls, git status work). The asymmetry is tool-specific, not a general settings propagation failure. `--allowedTools` is the reliable mechanism:

```bash
cat prompt.txt | claude -p --allowedTools "Read Glob Grep Bash Write" --verbose --output-format stream-json
```

Parent prompts that instruct children to spawn grandchildren must include the `--allowedTools` flag in the launch command template they provide.

## Prompt Construction for Nested Spawning

Workers spawn subagents when their prompt includes:
1. The full artifact directory path for the subagent (`workers/worker-N/subagent/`)
2. The exact `claude -p` launch command with `--allowedTools` and stream-monitor pipeline
3. Instructions for the subagent to write `status.md` and `results.md` to its artifact dir
4. Monitoring instructions: poll `subagent/status.md` every 20-30s until `milestone: done`

Workers use `run_in_background: true` on the Bash tool call to launch subagents non-blocking, same pattern Directors use for workers.

## File-Based Coordination Scales

The artifact contract (prompt.txt, status.md, results.md, live.md) works identically at every tier. Parents read children's artifacts for monitoring and synthesis. No pipes between levels — all communication is through the filesystem.

## Model Tiering

Directors do orchestration (plan, dispatch, monitor, synthesize) — Sonnet-appropriate. Workers do domain analysis (reading complex code, making judgment calls) — Opus-appropriate. The intuition that "higher tier in hierarchy = bigger model" is backwards; match model to task complexity, not organizational rank. Use `--model` on each `claude -p` invocation.

## `--max-turns` for Long-Running Sessions

Default `claude -p` turn limit is 100. Compound Director sessions (assessment + launch + monitor + converge) easily exceed this — a 6-MR compound sweep uses ~80 turns on assessment alone. Use `--max-turns 500` for Directors running compound sweeps. Single-mode sessions (review-only or address-only) need `--max-turns 200`. Workers (invoked by runners) rarely exceed 100 turns since they handle a single MR.

## `ScheduleWakeup` Does Not Work in `claude -p`

`ScheduleWakeup` is an interactive-session tool. In `claude -p`, calling it exits the session immediately (the timer has nowhere to fire). Directors that need to wait for background tasks should use `Bash(run_in_background: true)` and receive notifications, not schedule wakeups.

## Slash-Command Syntax Fails in Headless Sessions

`/skill-name` syntax doesn't resolve in `claude -p` — use `Skill` tool calls instead. Skills designed for both interactive and headless invocation should default to `Skill("skill-name")` and only use slash-command syntax when interactive context is guaranteed. Applies to any skill an orchestrator might invoke.

## Cross-Refs

No cross-cluster references.
