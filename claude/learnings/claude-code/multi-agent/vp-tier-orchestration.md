VP-tier orchestration — patterns for managing multiple Director sessions across repos from a single coordinating session.
- **Keywords:** VP, multi-repo, multi-director, claude -p, event-driven, monitoring, convergence, turn limits, compound sweep
- **Related:** ~/.claude/learnings/claude-code/multi-agent/headless-nesting.md, ~/.claude/learnings/claude-code/multi-agent/director/CLAUDE.md

---

## VP Architecture: Coordinating Directors Across Repos

The VP is a live interactive session that launches Director `claude -p` sessions, one per repo. Each Director invokes `/director` via the Skill tool, which handles assessment, artifact generation, runner launch, and convergence. The VP monitors Directors and handles cross-repo convergence.

```
VP (interactive session)
├── Director A (claude -p, CWD=repo-A) → /director review+address
│   ├── Review runner (let-it-rip.sh) → N review workers (claude -p)
│   └── Address runner (let-it-rip.sh) → N address workers (claude -p)
└── Director B (claude -p, CWD=repo-B) → /director review+address
    ├── Review runner → N review workers
    └── Address runner → N address workers
```

## Event-Driven, Not Polling

**Neither the VP nor Directors should poll.** The entire chain is event-driven via `Bash(run_in_background: true)`:

1. VP launches each Director via `Bash(run_in_background: true)` → gets notified on Director completion
2. Director launches runner via `Bash(run_in_background: true)` → gets notified on runner completion
3. Runner blocks on `xargs` until workers finish → exits → triggers Director notification
4. Director evaluates convergence, relaunches if needed → eventually exits → triggers VP notification

**After launching, wait for the notification.** Do not poll — the notification arrives automatically when the child exits.

**Use `Bash(run_in_background: true)`, not bash `&`.** `run_in_background` gives a notification channel. `&` is fire-and-forget with no notification, which forces polling.

## `--max-turns` Is Critical for Directors

Default `claude -p` turn limit is 100. A compound review+address Director spends turns on:
- Learnings search: ~8 turns
- Bootstrap (session.json, decisions.md): ~12 turns
- `sweep:review-prs` assessment: ~30-35 turns (fetching MR metadata, generating artifacts)
- `sweep:address-prs` assessment: ~30-35 turns
- Runner launch + monitoring: remaining turns

100 turns is barely enough for assessment of 6 MRs. No turns left for Phase 4 monitoring. **Use `--max-turns 500` minimum** for compound sweeps. For single-mode sweeps (review only or address only), `--max-turns 200` suffices.

```bash
cat prompt.txt | claude -p --max-turns 500 --verbose --output-format stream-json
```

## VP Launch Pattern

```bash
# Launch Director in background — VP gets notified on completion
cat director-prompt.txt \
  | sh -c "echo \$\$ > session.pid; exec claude -p --max-turns 500 --verbose --output-format stream-json" \
  | stream-monitor.sh director-dir \
  | tee director-dir/raw.jsonl > /dev/null
```

Use `Bash(run_in_background: true)` for this command. When the Director completes, read its `status.md` and `results.md`. If not converged, relaunch with a Phase 4 continuation prompt.

## Director Prompt for VP-Launched Sessions

The Director `claude -p` prompt should:
1. Instruct to invoke `/director` via `Skill` tool (not manually replicate the lifecycle)
2. Specify mode and PR numbers: `skill="director", args="review+address --prs=#73,#74,..."`
3. Include VP reporting paths for status.md and results.md
4. Set convergence expectation: "run to full convergence"

The `/director` skill handles the full Phase 1-5 lifecycle including convergence loop when it detects "converge" in the args. The VP prompt doesn't need to embed playbook logic.

## CWD Matters: One Director Per Repo

Each Director must run from its repo root. Git, glab/gh, and worktree operations resolve relative to CWD. The VP launches each Director from the correct directory:

```bash
cd repo-A && cat prompt.txt | claude -p ...
```

## Concurrency: Override the Default

Sweep skills default to `CONCURRENCY=3`. For 5-6 MRs, this means batch 1 (3 MRs) runs while batch 2 waits. Override by passing `--concurrency=6` to the sweep skill, or patch `let-it-rip.sh` post-generation:

```
CONCURRENCY=6  # was 3
```

The runner can be relaunched to pick up remaining PRs — pre-flight skip handles already-running/completed items. Duplicate sessions from overlapping runner launches are handled by watermark dedup (second session sees the review was already posted and skips).

## Permission Patterns for VP Sessions

VP-launched Directors need these `settings.json` patterns:
```json
"Skill(director *)",
"Skill(sweep:review-prs *)",
"Skill(sweep:address-prs *)",
"Skill(set-persona *)",
"Read(~/.claude/settings.json)",
"Bash(mkdir:*)"
```

Without Skill patterns, Directors silently work around by doing assessment manually (incorrectly). Without `mkdir:*`, Directors fail on absolute-path mkdir and waste turns retrying.

## Director Session Resumption

When a Director hits its turn limit mid-lifecycle:
- Review/address artifacts are already generated (persistent on disk)
- Runners may still be running (independent bash processes)
- A new Director session can pick up by reading existing artifacts

Write a Phase 4 continuation prompt that:
1. Points to existing artifact directories (don't regenerate)
2. Instructs to read worker state.md files for current status
3. Handles the remaining lifecycle (monitor → converge → address launch → re-review)

## VP → Director Directive Channel

The Director playbook defines a three-channel interface (down: directives, up: status, sideways: kill/observe). The VP extends this one tier up with the same pattern:

- **VP writes** `director-lms/directives.md` (append-only dated sections)
- **Director reads** directives at each phase gate (before launching runners, before evaluating convergence)
- **VP reads** `director-lms/status.md` and `director-lms/results.md` for monitoring

VP directives can instruct Directors to:
- Override concurrency: "Set CONCURRENCY=6 for the next runner launch"
- Force convergence: "Mark review converged, proceed to address"
- Add scope: "Include MR !79 in the next cycle"
- Adjust model: "Use opus for review workers on MRs with large diffs"

The Director prompt must include: "Read `<VP_DIR>/director-<name>/directives.md` before each phase transition."

## Warm Sessions via `--resume` (Context Reuse)

The runner template already supports warm session resume:

1. After a successful worker session, the runner writes `session.state` (session_id, cost, cycle)
2. On relaunch, the runner checks `session.state` — if fresh (<6h), launches with `--resume <session_id>`
3. Resumed sessions receive a short continuation prompt ("Check directives. Continue.") instead of the full `prompt.txt`
4. The worker retains its full conversation context: diff, learnings, persona, prior findings

**This saves significant context and cost.** A cold-start review worker spends ~30 turns on preflight + learnings loading + diff fetching. A warm-resumed worker skips all of that — it already has the context and just checks for new activity.

**Requirements for warm resume to work:**
- Rerun the same `let-it-rip.sh` (same run_dir) — don't regenerate artifacts
- Don't delete `session.state` files between cycles
- Sessions must complete successfully (the runner only writes `session.state` on success)
- Director can force cold start by writing `session.reset` to the item directory

**VP impact:** When the VP relaunches a Director for a new convergence cycle, instruct it to rerun the existing runner (`bash <same-run-dir>/let-it-rip.sh`) rather than re-invoking the sweep skill. Re-invoking creates a new run_dir, which loses all `session.state` files and forces cold starts.

## Open Question: VP Tier vs Background Agents

Whether multi-repo orchestration needs a dedicated VP tier (`claude -p` Directors) or just `Agent(run_in_background: true)` from the main session is unresolved. Key unknowns: can background Agents invoke skills? Do permissions propagate? Does CWD change work? Does the `!` preprocessor resolve? An empirical test comparing the two approaches is needed before committing to either architecture.

## Cross-Refs

- `headless-nesting.md` — `--allowedTools` propagation, Skill tool in headless sessions
- `director/CLAUDE.md` — Director-layer sub-cluster (observability, runner-design, watermarks-and-skip, failure-modes, process-and-meta)
- `background-agent-capabilities.md` — empirical answer to the bg-agent capability questions above
