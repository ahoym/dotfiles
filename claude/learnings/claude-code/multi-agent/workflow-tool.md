Authoring and using the `Workflow` tool — the JS-script multi-agent orchestrator (distinct from `claude -p` / the Agent tool).
- **Keywords:** Workflow tool, workflow script, agent(), parallel(), pipeline(), scriptPath, resumeFromRunId, design tournament, judge panel, synthesize, StructuredOutput schema, parse error, plain JS
- **Related:** ~/.claude/learnings/claude-code/multi-agent/orchestration.md, ~/.claude/learnings/claude-code/multi-agent/quality.md

## Workflow scripts are plain JS — two parse-error traps that waste round-trips

The script is parsed as plain JS, so two transcription mistakes recur:

- **An apostrophe inside a single-quoted string closes the string.** `'...do not reimplement (don't)...'` is a syntax error at that column. Write `do not`, or double-quote the literal.
- **Paren-balance in the `(await parallel(...))` chain.** `const xs = (await parallel(items.map(i => () => agent(...)))).filter(Boolean)` needs **four** closes before `.filter` — `agent(`, `.map(`, `parallel(`, and the wrapping `(`. Drop one and the error surfaces at the *next* top-level statement (`Unexpected token (N:0)`), not the real line.

The reported `(line:col)` points at the token *after* the unterminated construct — read it as "the statement before here didn't close," not "this line is wrong."

## Iterate via `scriptPath`, not by re-pasting the script

A failed `Workflow({script})` does **not** persist the script. After the first parse fix, `Write` the script to a file and invoke `Workflow({scriptPath})` — each subsequent edit re-runs without re-transcribing the whole thing (re-pasting is exactly where the apostrophe/paren errors creep back in). Successful runs auto-persist and return the path plus a `resumeFromRunId` for cache-resume.

## Canonical shape for an ambiguous design decision: map → design tournament → judge → synthesize

For a substantial change with genuine design ambiguity, run a four-phase workflow *before* any code:

1. parallel read-only **mappers** → a ground-truth digest of the surface (call sites, implementers, tests, blast radius);
2. 2–3 **independent designers**, each a different lens (minimal / spec-faithful / test-first), each producing a complete file-by-file plan from that digest;
3. **adversarial judges** score each design and list fatal flaws (prompt them to refute, not praise);
4. one **synthesizer** merges the winner and grafts the best ideas, dropping every fatal flaw.

**N independent designs converging on the same answer is the confidence signal** — when all three pick the same approach with zero fatal flaws, implement it without second-guessing. Pass a structured-output `schema` to each phase so results compose without parsing. Use `parallel()` only at the barriers (all designs needed before judging); `pipeline()` elsewhere.

## Execution model: always backgrounds; no `run_in_background` param

The `Workflow` tool has **no `run_in_background` param** (unlike `Agent`/`Bash`) — passing it is an `InputValidationError`. It always backgrounds: returns a `runId` + task ID immediately and auto-notifies (`<task-notification>`) on completion. To **consume the result in the same turn** instead of ending the turn, call `TaskOutput(task_id, block=true, timeout)` on the workflow's task ID — it returns the script's return value (truncated; full JSON in the `.output` file). `TaskOutput` works on `local_workflow` tasks (and Bash), NOT `local_agent` (those overflow context — rely on the notification). For a long workflow, block in ≤300s increments and re-block on timeout.

## Task `.output` files wrap the return value under `.result`

A completed workflow's persisted output file (`tasks/<id>.output`) is not the script's return value — it's a wrapper: `{agentCount, logs, result, summary, totalTokens, totalToolCalls, workflowProgress}`. `jq '.compare[]' file` fails with "Cannot iterate over null"; the correct path is `jq '.result.compare[]' file`. Check `jq 'keys'` first when extraction queries return null.

## A no-progress watchdog kills agents that run long silent calls

Workflow `agent()`s are killed by a ~180s no-progress watchdog and retried (~6×) — a single Bash call that runs minutes with no intervening tool output (a full-data backtest, a long `uv sync`, an expensive script under stash-isolate parity) reads as "stalled" and dies on every retry, burning hours/tokens before the pipeline gives up on that item. Keep each agent's steps emitting output, chunk long work, or move it out of the agent: prove a refactor's parity with pinned-expression unit tests + a cheap spot-check (relocation-identical = parity by construction) instead of re-running expensive consumers inside the agent. Agents with only fast unit tests / static checks never trip it.

## A worktree-agent's output survives the agent dying — salvage/verify it from the orchestrator

`isolation: 'worktree'` agents work in `<repo>/.claude/worktrees/<runId>-N`; both the worktree (with its uncommitted edits) and any branch the agent created **persist** after the workflow ends or the agent is killed (`git worktree remove` never deletes the branch ref). So a stalled/failed agent's work is recoverable — don't re-run from scratch: inspect `git -C .claude/worktrees/<runId>-N status` / `diff`, then finish + validate + commit from the main loop via `git -C <worktree> …`. Verify any worktree-agent's branch read-only from the main tree with `git diff main...<branch>` / `git show <branch>:<file>` — no checkout needed, and it runs concurrently while other agents still hold their worktrees.
