Director-observed failure patterns: rate limits, races, scope drift, and convergence pathologies.
- **Keywords:** rate-limit, storm, parallel, TOCTOU, oscillation, halve-per-cycle, deferred-runs, discovery-scope, fresh-timestamp
- **Related:** watermarks-and-skip.md, process-and-meta.md

---

## Rate-Limit Sentinel Persists Across Reruns

`let-it-rip.sh` creates `.rate-limited` in the run directory when any session hits limits. On rerun, all sessions skip immediately without even trying. Clear manually (`rm <RUN_DIR>/.rate-limited`) before retrying.

## Parallel Session Rate Limit Competition

Launching 4+ `claude -p` sessions simultaneously reliably exhausts API rate limits. The first 2-3 sessions complete; later ones hit limits mid-execution. Mitigations: lower concurrency (2-3 for heavy sessions like team reviews), stagger launches, or accept that reruns will be needed. The `.rate-limited` sentinel prevents wasted retries but must not overwrite completed sessions (see runner pre-flight order).

## Parallel Implementer File-Overlap: Surface, Log, Default Parallel

When two eligible work-items in a sweep will modify the same file (detected from Sweeper-Confirm scope blocks naming a path or function), the director:

1. Marks in `manifest.json.warnings[]` with the overlapping path
2. Surfaces in the assessment summary table
3. Logs to `decisions.md` (cost-time): *"parallel at operator's explicit concurrency — mechanical conflict, merge-time resolution faster than launch-time sequencing"*

Default to parallel. Sequence only when operator explicitly asks — `--concurrency=N` signals tolerance for parallel risk; a mechanical merge-conflict resolves in ~2min via rebase or `/git:resolve-conflicts`, vs ~10-15min waiting on the first PR before launching the second.

**Detection signal:** path-string match across Sweeper-Confirm scope sections. Function-name overlap alone is weak (different functions in same file often don't conflict in practice). Distinct from "Parallel Session Rate Limit Competition" above — this is about *merge* conflicts, not API contention.

## Compound-Mode Rate-Limit Storm: Fresh-Timestamp Restart, Not In-Place Retry

When a `claude -p` cycle exhausts the model's token budget mid-flight, sessions exit with `is_error: true` (visible in stream-json `completed` events) but the runner reports `state: completed` because it only sees process exit. Worse, partial state lands in `status.md` (`milestone: started`, no `last_<mode>_sha` update) — corrupting the watermark for the next pass.

The recovery pattern: **don't rerun the same `let-it-rip.sh`**. Re-invoke the sweep skill at a fresh timestamp to get clean status.md files, and reuse adjacent artifacts that don't need regeneration:
- Worktrees from the prior sweep persist — new artifacts can reference them via `worktree-cases.txt` without re-creating
- Per-PR `directives.md` written at the run-dir level (e.g., `Fixes #N` body keyword) carry over only if you keep using the same address run-dir; for fresh address artifacts, copy the directive over

Symptoms that say "you hit the storm": `context_used_tokens: 0` + `duration_seconds < 60` + `"is_error":true` in `output.log`'s `completed` event, on multiple PRs in the same cycle. Distinguishes from genuine rate limits (which produce `rate_limit` events and `.rate-limited` sentinel).

**Diagnosis — prompt-free path:**
```
bash ~/.claude/skill-references/sweep-status-summary.sh <RUN_DIR> --logs 30
```
Tails each item's `output.log` (the stream-json record) — contains `rate_limit_event`, `is_error`, `context_used_tokens`. Allowlisted under `Bash(bash ~/.claude/skill-references/**)`. Do NOT use `tail`/`cat` on `live.md` or `output.log` directly — those aren't allowlisted and prompt the operator on every call.

## 30-Second Exit Diagnosis: raw.jsonl Turn-Text First

A `claude -p` session exiting in <60s has multiple distinct failure modes that look identical at the event-tag level. **Always read `raw.jsonl` turn text before hypothesizing the cause** — `live.md`'s synthesis can mislead.

| Cause | duration | is_error | context_tokens | event tag | raw.jsonl turn_text reveals |
|-------|----------|----------|---------------|-----------|----------------------------|
| Genuine 5h rate limit | <60s | false | 0 | `rate_limit` | API blocked turn 1 |
| Compound-mode storm | <60s | **true** | 0 | `completed is_error: true` | session never ran |
| **Resume-cache short-circuit** | ~30s | false | ~40k | `rate_limit` (informational) | *"already posted, nothing to do"* |
| Watermark match (legitimate skip) | <30s | false | ~10k | none | session wrote `milestone: skipped` |

The **resume-cache short-circuit** is the trap: `claude -p --resume <session_id>` carries cached context from prior cycles, so the model "remembers" cycle N-1's `milestone: posted` and self-skips without reading directives or re-checking watermarks. The `rate_limit_event` in stream-json is informational (`status: allowed`) and unrelated to the bail-out — but its presence in `live.md` makes it look causal.

**Diagnostic gate (pre-action):**
1. **First pass — allowlisted summary:** `bash ~/.claude/skill-references/sweep-status-summary.sh <RUN_DIR> --logs 60`. Greps the output.log dump for `rate_limit_event`, `"is_error":true`, `"already posted"`, `"complete"`, `"nothing to do"`. Often resolves the diagnosis without going deeper.
2. **Deep pass — turn text:** if step 1 is ambiguous, read `raw.jsonl` directly: `cat raw.jsonl | jq -c '{type, turn_text: .message.content[0].text, result}'`. May prompt for permission if `Bash(cat:*)` isn't allowlisted — accept the prompt only when step 1 was inconclusive.
3. If turn_text contains "already posted", "complete", "nothing to do" → resume-cache short-circuit, **not rate limit**.
4. Recovery: fresh-timestamp restart (same as compound storm), since `claude --resume` keeps reading the same `session_id` even with directives present.

**Anti-pattern:** jumping to the rate-limit hypothesis based on the `live.md` `rate_limit` tag without reading turn text. One real session lost ~4 hours waiting for a 5h quota reset that wasn't actually blocking.

## In-Place Finalize-WIP Recovery (work-items mode)

Refines the fresh-timestamp recipe above for a different storm shape: sessions died **after** producing substantive WIP — files are written, not committed; branches exist but no PR. Worktrees and branches are intact; only `state.md`/`status.md` are corrupted.

| Symptom | Recovery |
|---------|---------|
| `context_used_tokens: 0` + `duration < 60s` + no WIP | Fresh timestamp (above) |
| `is_error: true` + sizable `git diff` in worktree + no commits | **In-place finalize directive** |

Pattern: write per-issue `directives.md` in the existing run dir, then re-run the same `let-it-rip.sh`. The 6h `session.state` TTL means resume falls back to fresh prompt — but the directive short-circuits expensive phases:

```markdown
# Director Directive — Finalize WIP

Previous session died on rate limits with WIP in your worktree:
<git diff --stat output>

**Skip Step 9 (Explore).** Already done last cycle.
**Skip Step 10 (Plan).** Existing WIP is the plan-in-flight.
**Skip Step 11b (Post Intent).** Already posted.

Finalize sequence:
1. Review WIP, fix known blockers (e.g., F811 dup function)
2. Run validation (ruff, pytest)
3. Step 14 git workflow (commit, push, gh pr create)
4. Step 15 write artifacts
```

Empirically: ~50% context use vs. blowout, single attempt convergence vs. multi-cycle thrash. Only viable in work-items mode (sweep/review/address don't hold WIP across cycles).

## TOCTOU in Orchestration Pre-Filters

When an orchestration skill reads state at Phase N for an optimization decision (e.g., pre-filter unchanged items) and re-reads at Phase M for an authoritative decision (e.g., convergence check), items excluded at Phase N could have new activity by Phase M. Classic time-of-check/time-of-use applied to skill orchestration: either re-check excluded items at the authoritative phase, or accept that the optimization can miss state changes between phases.

## Deferred Runs Need Event-Triggered Reassessment

When a director defers a run ("no eligible items — reassess after X completes"), it records the reason but has no mechanism to auto-resume when the blocking condition clears. The next cycle requires manual re-invocation. Deferral reasons should map to observable events (new review comments posted, PR state change, issue reply) so the director can reassess without operator intervention.

## Discovery During Clarify Doesn't Feed Back Into Scope

When a clarify pass discovers the actual blast radius differs from the plan (e.g., 7 files with references vs 4 originally listed), that finding lives only in the clarify output. Subsequent assessment and implement passes use the original scope. Directors should read clarify outputs and update the manifest's scope metadata so downstream passes inherit discoveries.

## Compound Findings Halve Per Cycle When Author Fixes Root Causes

Substantive PRs in compound review+address mode follow a predictable trajectory: findings count roughly halves each cycle (e.g., 10 → 5 → 0). Three cycles is typical for a PR with 3 HIGH findings; clean re-review (0 new findings) is the convergence signal. If findings don't shrink between cycles, the addresser is patching symptoms rather than root causes — write a directive or escalate.

## Oscillation Exception: Substantive Refactor PRs May Never Converge

The halving-per-cycle pattern assumes the PR has a bounded set of findings. For PRs that introduce significant new abstraction (new Protocol, new module boundary, new error path), reviewers can legitimately surface new edge cases in each cycle — because each fix reveals *new* surface area that wasn't previously testable.

Observed pattern on one session's PR: 8 → 5 → 5 → 8 → 10 new findings per cycle, with every prior cycle's findings cleanly resolved each time. Code *was* improving; reviewers *were* being thorough; neither side was patching symptoms. But the loop never converges under the standard 5-cycle cap.

**Heuristic:** If after 2 cycles the finding count hasn't decayed (or is growing), stop the auto-relaunch and surface to the operator. Give them the option to (a) accept current state as technical debt, (b) scope the next cycle narrowly (HIGH-only), or (c) keep cycling explicitly. Silent continuation past the cap wastes API cost and can widen the surface as reviewers find more.

## CI-Verification Stall: Address Cycle No-Op on New Inline Comment

Symptom: address session completes cleanly with `duration_seconds < 120` + `last_addressed_sha` unchanged + new inline comment ID exists past `last_comment_id` in `status.md` + no new section appended to `results.md`. Session reads state, decides "CI verification only," exits without acting on the finding. `state: completed`, `is_error: false` — silent. The watermark stays stale; the next cycle may repeat the no-op.

Distinct from the deferred-only-stall pattern: the addresser never posted a public reply either (404 on `pulls/comments/<id>/replies`), so the watermark-advance-via-public-reply heuristic doesn't kick in.

**Diagnostic:** compare `status.md` `last_comment_id` against `gh api repos/{owner}/{repo}/pulls/<N>/comments --jq '.[-1].id'`. If watermark < latest AND PR HEAD unchanged → stall confirmed.

**Recovery:** per-PR `directives.md` citing the inline comment ID + recommended fix or explicit "post public-reply defer" instruction. The "overrides skip logic" clause forces the addresser to process the comment. Empirically the addresser will pick "implement" when a clean fix exists, even when offered the defer option.

## Permission-Denial Loop: `repeated_errors` Climbing on Same Command

When `live.md` shows `repeated_errors count` climbing on identical or near-identical commands (e.g., `git merge-tree …` retried 13 times before runner kill), the cause is a **missing allow pattern in project `.claude/settings.local.json`**, not a logic bug or API issue. The `claude -p` session can't prompt for approval, so it loops until the inactivity threshold trips.

Diagnostic markers in `live.md` tail:
- Same tool + near-identical command across 5+ retries
- Each retry tagged `escalation: type: repeated_errors (count: N)` with N climbing
- Tool results: `"Cancelled: parallel tool call"`, `"This command requires approval"`

The agent will cycle through variants if one is denied: subshell `$(…)`, redirect `2>&1`, pipe `| head`, compound `&&`. None work without the base pattern. Read `raw.jsonl` tail to see the canonical (un-decorated) command and derive the pattern.

**Recovery:** add the missing pattern (e.g., `Bash(git merge-tree:*)`) to project-level `.claude/settings.local.json` (user-level patterns aren't inherited by background `claude -p` sessions). Write a per-PR directive noting the fix landed and relaunch the same runner.

## Single-Session API-Retry Hang: Distinct from Rate-Limit Storm

`claude -p` session terminates with `state: errored, exit_reason: timeout` after the runner's inactivity threshold, but `live.md` and `raw.jsonl` show the model was making *valid* progress until a `system, subtype: api_retry` event with `error: "unknown"`. After that event, no further tool calls; eventually the pipe hangs and the runner kills it.

| Signature | Storm | Single-session API hang |
|-----------|-------|-------------------------|
| Duration | <60s | minutes to hours of progress |
| `is_error` | true | n/a (timed out before completion event) |
| `context_used_tokens` | 0 | non-trivial |
| Spread | multiple sessions same cycle | one session in isolation |
| Last event | `completed is_error: true` | `api_retry error: "unknown"` |

**Recovery:** fresh-timestamp restart usually clears it (same playbook as storm, even though signature differs). The transient API issue is gone by retry time. If two consecutive restarts hit it on the same PR, escalate — the agent may be triggering a deterministic API failure (huge tool result, malformed input).

## In-Place Retry Viable When Worker Has `Role:*` Self-Filter

The default storm recovery (above) is fresh-timestamp restart because corrupted `status.md` re-triggers full reprocessing. Exception: when the worker prompt classifies its own prior posts via a `Role:` footnote (e.g., `sweep:address-prs` filters `Role:.*Addresser` to skip self-replies), an in-place rerun of the same `let-it-rip.sh` recovers cleanly. The runtime watermark logic re-fetches state from the API (steps 1-3 of `addresser-prompt.md`) and the Role filter prevents duplicate replies on already-addressed threads. Cheaper than fresh-timestamp because no artifact regeneration.

**Test before in-place retry:** confirm every worker prompt has a self-filter (e.g., `grep -l "Role:.*<Mode>" <run_dir>/<entity>-*/prompt.txt`). Without it, in-place retry double-replies on already-processed comments — fall back to fresh-timestamp.

**Race on watermark patches.** Manual `Write` to a worker's `status.md` between launch and worker step-2 read is timing-dependent: the runner setup writes `milestone: launching` on launch, and the worker overwrites again at step 4 (`milestone: started`). Patches landed mid-launch are clobbered. If a patch is required (e.g., to seed a watermark the worker will respect), write *before* `bash let-it-rip.sh`, not after.
