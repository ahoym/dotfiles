---
name: resume
description: "Review consolidation loop state, handle review items, and prepare to relaunch."
disable-model-invocation: true
allowed-tools:
  - Read
  - Edit
  - Glob
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Resume Consolidation Loop

Review the state of a completed or stalled consolidation loop, handle any review items, and print the relaunch command.

## Instructions

### 1. Locate the worktree

- If `$ARGUMENTS` provided, use as the worktree path
- Otherwise, list directories matching `.claude/worktrees/consolidate-*` and prompt for selection
- If no worktrees found, error: "No consolidation worktrees found. Run `/ralph:consolidate:init` first."

### 2. Read state

Read from `<worktree>/.claude/consolidate-output/`:

| File | What to extract |
|------|-----------------|
| `progress.md` | State variables (SWEEP_COUNT, ROUND, CONTENT_TYPE, ROUND_CLEAN, CLEAN_ROUND_STREAK), iteration log, round summary, notes |
| `report.md` | Summary table, total actions, status |
| `review.md` | Any review items (LOWs, blocked MEDIUMs, loop limits) |
| `decisions.md` | Last 10 rows (recent actions for context) |

### 3. Present status

```markdown
# Resume: Consolidation <date>

## State
- **Round**: N
- **Content Type**: LEARNINGS / SKILLS / GUIDELINES
- **Sweep Count**: N
- **Clean Round Streak**: N/1
- **Status**: IN_PROGRESS / MAX_ITERATIONS_HIT / COMPLETE

## Summary

| Content Type | Sweeps | HIGHs Applied | MEDIUMs Applied | MEDIUMs Blocked |
|...|

## Review Items (N)

[L-1] Title — ambiguous classification...
[BM-1] Title — blocked MEDIUM, options: ...

(If none: "No review items — loop can resume as-is.")

## Recent Decisions (last 5)

| Iter | Action | Source | Target | Decision |
|...|
```

### 4. Handle review items

If there are review items in `review.md`:

1. Present each item with its title, context, tag, and options
2. Use `AskUserQuestion` to collect the user's decision for each
3. Update review.md: append `**Status**: RESOLVED (<chosen option>)` to the item
4. If the resolution requires an action (e.g., "apply option A"), add guidance to progress.md's `Notes for Next Iteration` section so the next loop iteration picks it up

If the user wants to skip an item, leave it without a Status line.

**Recommendation framing**: When presenting options, prefer recommending the option that fixes root cause (wire, restructure, merge) over the option that accepts dysfunction (delete, skip). Deletion is irreversible; wiring is reversible. Only recommend cleanup when the content is stale, incorrect, or has no identifiable consumers.

### 5. Prepare for relaunch

Calculate suggested iterations based on pre-flight cadence (from progress.md) and remaining work:
- Read `Cadence` and `Suggested iterations` from the Pre-Flight section
- Base: `max(5, <init_suggested> - SWEEP_COUNT)` where `<init_suggested>` is the value from pre-flight (default 20 if not present)

If COMPLETE or MAX_ROUNDS_HIT signal is present in progress.md:
- **Clean up working files**: Remove `consolidate-output/` from the branch — these are working state, not deliverables. Run `git rm -r .claude/consolidate-output/` and commit with message `consolidate: remove working files before merge`.
- Ask if the user wants to review the diff: `git diff main -- .claude/`
- Suggest merging: `git checkout main && git merge <branch>`
- Do NOT suggest relaunching

Otherwise:

```
Ready to resume. Run:
  cd <worktree>
  bash ~/.claude/ralph/consolidate/wiggum.sh <suggested_iterations>
```

## Design Notes

- **Does not auto-launch** — prints the command for the user to run, since `wiggum.sh` invokes `claude --print` (cannot be called from within Claude)
- **Review item resolution feeds back through progress.md** — the next loop iteration reads Notes and acts on resolved items
- **COMPLETE state** — when the loop finished successfully, resume shifts to review/merge guidance instead of relaunch
