---
description: "Playbook for directing sweep workflows: loop setup, monitoring, convergence, directives, and common patterns."
---

# Director Sweep Playbook

Structured guidance for the director (operator + main agent) when orchestrating review and address sweep loops.

## Prerequisites Checklist

Before starting any sweep session:
1. `gh auth status` succeeds
2. `~/.claude/settings.json` has all required permission patterns (see sweep skill prerequisites sections)
3. `tmp/claude-artifacts/change-request-replies/` write access — address sessions write reply payloads here. Verify the Write permission pattern matches at runtime (known friction point: tilde-path patterns may not resolve)
4. `tmp/claude-artifacts/sweep-reviews/` and `tmp/claude-artifacts/sweep-address/` exist or can be created

## Loop Setup: Offset Cadence

Run review and address sweeps on offset schedules:
- Review: :00, :05, :10, ...
- Address: :03, :08, :13, ...

The 3-minute offset ensures review findings are posted before the address sweep reads them. Same-time firing wastes a full cycle on handoff.

Launch review first. While review sessions run, assess address candidates and generate address artifacts. This parallelizes cycle 0.

## Monitoring Table Format

After each cycle, read all `pr-*/status.md` files and present:

| PR | State | Mergeable | Milestone | Last Activity | Directives |
|----|-------|-----------|-----------|---------------|------------|
| #51 | OPEN | MERGEABLE | done | 2m ago | -- |
| #50 | OPEN | CONFLICTING | done | 5m ago | conflict resolution |
| #49 | MERGED | -- | skipped | -- | -- |

First cycle: full table. Subsequent cycles: delta-only (changed rows), with a one-line "N unchanged" summary.

## Convergence Rules

### Review Loop
- **Converged**: all sessions skip (no new activity) for 30m wall-clock
- **Not converged**: any session produced findings this cycle
- **Auto-cancel**: after 30m of all-skip inactivity — reviews are reactive to changes

### Address Loop
- **Converged**: all PRs terminal (MERGED or CLOSED)
- **Not converged**: any open PR exists, even if all sessions skipped — main can advance and create conflicts at any time
- **Conflict watch**: each cycle, check `mergeable` in status.md. If CONFLICTING on an open PR, write a conflict resolution directive
- **Auto-cancel**: only when all PRs terminal

### What Is NOT Convergence
- "All sessions skipped" alone — if any open PR has `mergeable: CONFLICTING`, the loop must continue
- A single cycle of skips — wait for the convergence window (30m for review, all-terminal for address)

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

### Sensitive File Escalation
**When:** addresser escalates a finding on a protected/sensitive file.
**Write to:** per-PR directives, after operator reviews and approves.

```markdown
## <ISO timestamp>
Director-approved fix for <file>. <description of approved change>. Post a top-level PR comment flagging the sensitive file edit after committing.
```

### Directive Lifecycle
- Directives are append-only (dated sections, never overwrite)
- To mark a directive as satisfied, append a new section:
  ```markdown
  ## <ISO timestamp>
  Directive from <original timestamp> satisfied. No further action needed.
  ```
- Sessions should check whether directives are already satisfied before acting — prevents redundant invocations

## Re-Assessment Triggers

Re-run the sweep skill (not just the runner) when:
- New PRs opened since last assessment
- PRs closed/merged that need cleanup from the eligible set
- Fundamental scope change (different PR filter, new repo)

Do NOT re-assess just because a cycle skipped — that is normal convergence behavior. Re-running the runner script is sufficient for ongoing cycles.

## Active-Branch Workaround

When the director's session is on a branch that is also a PR target, `git worktree add` fails ("branch already checked out"). The address sweep skill detects and reuses existing worktrees. For PRs on the director's active branch where no worktree exists, use `Agent(isolation: "worktree")` to work from an isolated context.

## Single Source of Truth

| Concern | Lives in | Not duplicated in |
|---------|----------|-------------------|
| Classification logic (skip/process) | `sweep-scaffold.md` + sweep skill files | runner template, this playbook |
| Watermark comparison | `sweep-scaffold.md` (prompt steps 1-4) | runner template (only does cheap pre-flight) |
| Reaction targets & emoji | `review-comment-classification.md` | re-review-mode.md files |
| Convergence rules | this playbook | individual sessions (they don't decide convergence) |
| Directive patterns | this playbook | learnings (learnings capture discovery, playbook operationalizes) |
