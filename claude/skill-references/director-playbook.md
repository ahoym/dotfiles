---
description: "Playbook for directing parallel claude -p sessions: observability, monitoring, convergence, directives, intervention, and common patterns."
---

# Director Playbook

Structured guidance for the director (operator + main agent) when orchestrating parallel `claude -p` sessions. See `artifact-contract.md` for the standard structure skills must produce to be director-managed.

## Director Principles

**Agents demonstrate understanding before acting.** Implementation requires passing through a confirm gate — no exceptions. The lifecycle is: clarify (questions/analysis) → confirm (understanding + plan) → implement. This applies to any skill that orchestrates autonomous agents making code changes. Currently implemented in sweep:work-items; other orchestration skills (sweep:review-prs, sweep:address-prs) don't have this lifecycle because they review/address rather than implement changes.

**Directors observe and direct — they don't touch the working tree.** All code changes flow through agents via directives or targeted `Agent(isolation: "worktree")` launches. The director writes only: directives, monitoring state, and sweep artifacts. This eliminates `git stash` friction from mixing local edits with agent-pushed commits on the same branch.

**Standard path: director runs from `main`.** This avoids the active-branch workaround entirely — `git worktree add` works for every PR branch when the director isn't on one of them.

**Review and address must be separate `claude -p` sessions.** Never have the same agent both review and address an MR. A reviewer that knows it will also address goes easy; an addresser that wrote its own findings rubber-stamps them. The director presents review findings to the operator for sign-off before launching the address session. This is not a guideline — it is a structural requirement for review integrity.

## Decision Framework

Extracted to `~/.claude/skill-references/director-decision-matrix.md` — a standalone file loadable independently from this playbook. Read it at the start of Phase 4 and apply it to every action.

## Prerequisites Checklist

Before starting any sweep session:
1. `glab auth status` succeeds (or `gh auth status` for GitHub repos)
2. `~/.claude/settings.json` has all required permission patterns (see sweep skill prerequisites sections)
3. `tmp/claude-artifacts/change-request-replies/` write access — address sessions write reply payloads here. Verify the Write permission pattern matches at runtime (known friction point: tilde-path patterns may not resolve)
4. `tmp/claude-artifacts/sweep-reviews/` and `tmp/claude-artifacts/sweep-address/` exist or can be created
5. `~/.claude/skill-references/stream-monitor.sh` exists and is executable — the runner falls back to plain `claude -p` if missing, but `live.md` observability requires it

## Concurrency: match explicit item count

When the operator names N items (`/director review+address 47 48 49`), pass `--concurrency=N` to each sweep skill. The skill default of 3 is for "all open" sweeps where the count is unknown — explicit selection signals "I want exactly these N running in parallel." Capping below the named count serializes later items unnecessarily.

If the operator passes `--concurrency=N` explicitly, honor it as-is regardless of item count.

## Loop Setup: Offset Cadence

Run review and address sweeps on offset schedules:
- Review: :00, :05, :10, ...
- Address: :03, :08, :13, ...

The 3-minute offset ensures review findings are posted before the address sweep reads them. Same-time firing wastes a full cycle on handoff.

**Cycle 0 launch sequence:**
1. Assess review candidates and generate review artifacts
2. Launch review runner immediately (in background)
3. Assess address candidates and generate address artifacts (while review runs)
4. After review reaches `posted`/`done`, launch address runner

Launching review before address assessment parallelizes address artifact generation with review execution, reducing total wall-clock time. The address assessment may show "no comments" if review hasn't posted yet — this is expected. Address sessions handle no-op gracefully and pick up comments on the next cycle.

## Session Observability

`claude -p` sessions are fire-and-forget. The runner pipes through `stream-monitor.sh` for visibility:

```
cat prompt.txt \
  | sh -c 'echo $$ > $PR_DIR/session.pid; exec claude -p --verbose --output-format stream-json' \
  | stream-monitor.sh $PR_DIR \
  | tee $PR_DIR/raw.jsonl
```

The monitor appends typed events to `live.md` as a side effect. Reference docs live in `~/.claude/learnings/claude-code/multi-agent/director/`:
- **Channel model + state.md/status.md split + live.md entry types + stream-json event schema** → `observability.md`
- **Per-PR file inventory** (`prompt.txt`, `state.md`, `status.md`, `results.md`, `learnings.md`, `directives.md`, `session.pid`, `live.md`, `raw.jsonl`) → `observability.md`

### Director Intervention

The runner handles inactivity detection and single-retry recovery automatically. The director only intervenes after the runner exhausts retries and escalates via `state.md`. Read logs only when investigating an escalation — never as a primary monitoring channel.

**Log inspection — always via the allowlisted helper:**
```
bash ~/.claude/skill-references/sweep-status-summary.sh <RUN_DIR> --logs N
```
Tails each item's `output.log` (stream-json: tool calls, errors, `rate_limit_event`, `is_error`). Do NOT `tail`/`cat` `live.md` or `output.log` directly — those aren't allowlisted and prompt the operator. Need turn text or full event history? See `failure-modes.md` for the `raw.jsonl` deep-inspection path.

| Detection (from state.md) | Action |
|---------------------------|--------|
| `state: errored` + `escalation: needs-director` | `sweep-status-summary.sh --logs 30` for that run, investigate root cause, write directive for next launch |
| `state: rate-limited` | Check `.rate-limited` sentinel, advise operator on retry timing |
| `escalation: permission_denial` | Fix permission in settings, write directive |
| `escalation: repeated_errors` | Investigate root cause, write directive or escalate |

**Failure-mode shortcut:** if `state: completed` but `output.log` (via `sweep-status-summary.sh --logs N`) shows `"is_error":true` + `context_used_tokens: 0` + short duration on multiple sessions same cycle, that's the **rate-limit storm** — fresh-timestamp restart, not in-place retry. See `failure-modes.md`.

## Monitoring Table Format

Gather state via `bash ~/.claude/skill-references/sweep-status-summary.sh <run-dir>` (adds `--retro` to also include `results.md` + `learnings.md` — use for convergence evaluation). Reading `pr-*/state.md` and `pr-*/status.md` file-by-file via Bash `cat` triggers a permission prompt per file; the script is already allowlisted under `Bash(bash ~/.claude/skill-references/**)` so one call returns the full cross-PR summary without prompting.

The script prints per-PR sections — build the monitoring table from its output:

| PR | State | Mergeable | Milestone | Runner State | Attempt | Directives |
|----|-------|-----------|-----------|--------------|---------|------------|
| #51 | OPEN | MERGEABLE | done | completed | 1/2 | -- |
| #50 | OPEN | CONFLICTING | running | running | 1/2 | conflict resolution |
| #49 | MERGED | -- | skipped | -- | -- | -- |
| #48 | OPEN | MERGEABLE | errored | errored | 2/2 | needs-director |

First cycle: full table. Subsequent cycles: delta-only (changed rows), with a one-line "N unchanged" summary.

**Lock the column set at cycle 0.** Whatever columns you present in the first table, keep across the session — adding/removing columns mid-session loses the cross-cycle delta view. If a new dimension becomes relevant later, add it to the trailing context, not by reshaping the table.

## Convergence Rules

### Review Loop
- **Converged**: all sessions skip (no new activity) for 30m wall-clock
- **Not converged**: any session produced findings this cycle
- **Auto-cancel**: after 30m of all-skip inactivity — reviews are reactive to changes
- **Attended-session collapse**: for sessions where the operator is watching, an explicit additional review-runner invocation that hits the watermark-skip path (no new SHA, no new comment ID, ~60s exit) is sufficient convergence signal — no need to wait the full 30m. Reserve the wall-clock window for unattended/looping runs. The operator can interrupt if more activity arrives.

### Address Loop
- **Converged**: all PRs terminal (MERGED or CLOSED)
- **Not converged**: any open PR exists, even if all sessions skipped — main can advance and create conflicts at any time
- **Conflict watch**: each cycle, check `mergeable` in status.md. If CONFLICTING on an open PR, write a conflict resolution directive
- **Auto-cancel**: only when all PRs terminal

### Compound Mode Relaunch Sequence

After every runner completion in compound mode, the director executes this decision tree automatically — no operator prompt needed:

1. **Address runner completes** → read review `results.md`. If findings > 0 this cycle → relaunch review to verify resolution. If all resolved → check address convergence (all PRs terminal?).
2. **Review runner completes** → read `results.md`. If findings posted (inline comments > 0 OR thread replies > 0) → relaunch address. If skipped or 0 findings → review converging, start 30m skip window.
3. **Both converged** → proceed to Phase 5.

"Runner completed" ≠ "converged." A completed runner means one cycle finished — convergence requires the domain rules above to be satisfied.

### What Is NOT Convergence
- "All sessions skipped" alone — if any open PR has `mergeable: CONFLICTING`, the loop must continue
- A single cycle of skips — wait for the convergence window (30m for review, all-terminal for address)
- A single cycle completing — convergence requires evaluating the domain rules, not just the runner state

## Directive Patterns

### Conflict Resolution
**When:** `mergeable: CONFLICTING` on an open PR in address sweep.
**Write to:** `<ADDRESS_RUN_DIR>/pr-<N>/directives.md`

```markdown
## <ISO timestamp>
PR has merge conflicts with base branch. Invoke `/git:resolve-conflicts <base-branch>` before addressing comments.
```

### Conciseness / Focus Review
**When:** review findings indicate verbose or unfocused content.
**Write to:** `<REVIEW_RUN_DIR>/pr-<N>/directives.md` or global `directives.md`

```markdown
## <ISO timestamp>
Review for conciseness: identify verbose prose, duplication, and extraction candidates. Post findings as inline comments.
```

### Summary-Only Review Finding
**When:** latest review results.md has `findings > inline_comments` — at least one finding lives in the review body only, not as an inline comment. Covers both the all-summary case (`inline_comments == 0`) and the mixed case (e.g. 10 inline + 1 summary-only).
**Why:** the address loop's watermark tracks inline comment IDs. Inline-attached findings will trigger processing, but any summary-only finding rides along invisibly — without a directive it gets silently dropped.
**Write to:** `<ADDRESS_RUN_DIR>/pr-<N>/directives.md`

```markdown
## <ISO timestamp>
Review found a summary-only finding (no inline comment). Finding: <description from review summary>. Expected fix: <what to change and where>. This directive overrides skip logic.
```

### Sensitive File Escalation
**When:** addresser escalates a finding on a protected/sensitive file.
**Write to:** per-PR directives, after operator reviews and approves.

```markdown
## <ISO timestamp>
Director-approved fix for <file>. <description of approved change>. Post a top-level PR comment flagging the sensitive file edit after committing.
```

### Reviewer Dissent — Override vs Persona-Resolve
**When:** review surfaces a HIGH/INFO dissent that holds after deliberation between reviewer personas.
**Decide:**
- **Override** — write directive instructing the addresser which side to take. Use when the dissent has a clear technical winner the addresser persona might miss.
- **Persona-resolve** — record dissent context-only in `pr-<N>/directives.md` (informational, **not** override). Default for taste-based dissents when the addresser persona is well-matched to the domain. The addresser then chooses fix / agree-and-defer-with-reply / pushback / escalate-with-proposed-wording via its lens.

Either path requires a `decisions.md` entry per the decision matrix. The director's "decide" doesn't have to mean overriding the addresser — sometimes the persona's lens resolves better than a pre-committed call. **Validated:** PR #183 left both held positions to a fintech-ledger-engineer addresser; agree-and-defer + pushback both panned out (next review cycle withdrew the disputed finding).

### Watermark Skip Override
**When:** addresser silently skipped a cycle despite known new inline comments — typically a preflight watermark detection bug (e.g., `--paginate --jq 'last | .id'` returning a page-bounded value rather than the true latest).
**Why:** preflight skip happens before normal comment classification, so the addresser exits without seeing the new findings. The override directive is read in step 1 (before the skip check) and forces processing.
**Write to:** `<ADDRESS_RUN_DIR>/pr-<N>/directives.md`

```markdown
## <ISO timestamp>
Previous cycle skipped despite new comments. Process inline comment IDs [<id1>, <id2>, ...] this cycle. <Per-id: severity, finding summary, expected fix>. This directive overrides skip logic.
```

### Directive Lifecycle
- Directives are append-only (dated sections, never overwrite)
- To mark a directive as satisfied, append a new section:
  ```markdown
  ## <ISO timestamp>
  Directive from <original timestamp> satisfied. No further action needed.
  ```
- Sessions should check whether directives are already satisfied before acting — prevents redundant invocations
- **Director-side dedup:** Before writing a new directive, read existing directives for the same PR and check whether the target is already covered by a prior directive (satisfied or not). Duplicate directives cause redundant session launches — the session reads all directives and acts on each one independently

## Re-Assessment Triggers

Re-run the sweep skill (not just the runner) when:
- New PRs opened since last assessment
- PRs closed/merged that need cleanup from the eligible set
- Fundamental scope change (different PR filter, new repo)

Do NOT re-assess just because a cycle skipped — that is normal convergence behavior. Re-running the runner script is sufficient for ongoing cycles.

**Watermark propagation across session boundaries.** When re-invoking a sweep skill for a new cycle (new run_dir), the new session starts without the prior run's watermarks — triggering full comment re-analysis for every PR. To avoid this: before relaunching, copy each item's `status.md` from the prior run_dir into the new run_dir. The new session reads the watermark and skips items with no changes since the last pass. For quick reruns (same run_dir), this is handled automatically — the runner reuses existing `status.md` files.

## Branch-Position Patterns

**Main is still the preferred standard path** — cleanest, fewest gotchas. The two patterns below cover the cases where main isn't where the work is happening.

### Active-branch sweeps (supported via worktree reuse)

When the director is on a branch that IS one of the PR targets, the project root itself shows up in `git worktree list` as the worktree for that branch. The address sweep skill's worktree-discovery step picks this up automatically (`worktree_reused: true` pointing at the project root). The address worker `cd`s in and runs commits + pushes there. **No `git worktree add` needed; no separate `Agent` needed.**

Discipline (must hold for this to work):
- The director only reads `tmp/claude-artifacts/.../state.md`, `status.md`, `results.md` — never working-tree files. The agent's commits don't disturb the director's view because the director's view is just `tmp/`.
- The director must not make its own commits mid-session that interleave with agent commits — sequential is fine, concurrent breaks.

This is **not a workaround** — it's the supported active-branch pattern. Main is still preferred for the cleanliness it gives you (no chance of accidentally touching the working tree, no concurrent-write risk), but active-branch sessions converged across an 8-cycle compound loop without issue.

### Off-branch work while sweeping (use `Agent(isolation: "worktree")`)

When you need to work on a *different* branch while sweeps are running on the active one — e.g., spinning up a fresh feature PR off `main` while a compound sweep is iterating on a different branch — that's a different problem and needs `Agent(isolation: "worktree")`. The Agent gets its own worktree on its own branch, completely isolated from the director's working tree, and the sweep workers continue undisturbed.

This is the pattern used for the framework PR (PR 79) built mid-session on its own branch while PR 78's sweeps were still running. Don't conflate the two cases — active-branch sweeps don't need an isolated agent.

## Worker Learnings Triage

During convergence wrap-up (Phase 5), the director must triage worker learnings before closing the session:

1. **Read** each completed run's `*/learnings.md` files.
2. **Assess** each observation for promotion:
   - Does it encode reusable knowledge (pattern, gotcha, convention)? → candidate for persistent learning
   - Is it project-specific or broadly applicable? → determines scope (project-local vs global/learnings-team)
   - Is it verified or a hypothesis? → frame accordingly
   - Is it a one-off observation (dead code, missing route)? → skip
3. **Present** candidates to the operator in a table with Type/Scope/Utility columns (same format as `/learnings:compound`).
4. **Save** approved learnings to the appropriate location.

Workers generate domain-specific insights that the director wouldn't independently discover — particularly when workers load learnings-team learnings that connect to their findings (e.g., a precision learning predicting a parseFloat bug). These insights are lost if not promoted during the session.

## Director State

After each cycle, update `<RUN_DIR>/director-state.md`:

```yaml
cycle: <N>
review_cycles: <N>
address_cycles: <N>
convergence:
  review: converged | not-converged | auto-cancelled
  address: converged | not-converged
context_tokens_approx: <estimate from task outputs>
last_updated: <ISO timestamp>
```

Followed by the current monitoring table snapshot. This persists the director's view across cycles — useful for handoff to a fresh session if context runs low. The `context_tokens_approx` field signals when to consider compounding learnings and handing off.

## Single Source of Truth

| Concern | Lives in | Not duplicated in |
|---------|----------|-------------------|
| Classification logic (skip/process) | `sweep-scaffold.md` + sweep skill files | runner template, this playbook |
| Watermark comparison | `sweep-scaffold.md` (prompt steps 1-4) | runner template (only does cheap pre-flight) |
| Reaction targets & emoji | `review-comment-classification.md` | re-review-mode.md files |
| Convergence rules | this playbook | individual sessions (they don't decide convergence) |
| Directive patterns | this playbook | learnings (learnings capture discovery, playbook operationalizes) |
| Process lifecycle (running, retry, timeout) | runner (`state.md`) | director (reads, doesn't write) |
| Stream-json event schema, file inventory, channel model | `~/.claude/learnings/claude-code/multi-agent/director/observability.md` | this playbook (cross-refs only) |
| Runner template gotchas (EXIT trap, stale branch, schema drift, fill-template gaps) | `director/runner-design.md` | this playbook |
| Watermark/skip mechanics (single-pass, dual-signal, self-comment, post-action) | `director/watermarks-and-skip.md` | this playbook |
| Failure modes (rate-limit storm, oscillation, TOCTOU) | `director/failure-modes.md` | this playbook |
| Director meta-process (decision-matrix-is-trust, orchestrate-not-replicate) | `director/process-and-meta.md` | this playbook |
| Artifact contract (directory structure, manifest schema) | `artifact-contract.md` | this playbook, learnings, sweep-scaffold |

## Related Learnings

- `~/.claude/learnings/claude-code/multi-agent/director/CLAUDE.md` — sub-cluster index (5 focused files, split from former `director-patterns.md`)
