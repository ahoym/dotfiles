---
name: resume
description: "Review consolidation loop state, handle blockers, and prepare to relaunch."
disable-model-invocation: true
allowed-tools:
  - Read
  - Edit
  - Glob
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Resume Consolidation Loop

Review the state of a completed or blocked consolidation loop, handle any open blockers, and print the relaunch command.

## Instructions

### 1. Locate the worktree

- If `$ARGUMENTS` provided, use as the worktree path
- Otherwise, list directories matching `.claude/worktrees/consolidate-*` and prompt for selection
- If no worktrees found, error: "No consolidation worktrees found. Run `/ralph:consolidate:init` first."

### 2. Read state

Read from `<worktree>/.claude/consolidate-output/`:

| File | What to extract |
|------|-----------------|
| `progress.md` | State variables (SWEEP_COUNT, CONTENT_TYPE, PASS, CLEAN_SWEEP_STREAK), iteration log, notes |
| `report.md` | Summary table, total actions, status |
| `blockers.md` | Any items with `Status: OPEN` |
| `decisions.md` | Last 10 rows (recent actions for context) |

### 3. Present status

```markdown
# Resume: Consolidation <date>

## State
- **Pass**: N/2
- **Content Type**: LEARNINGS / SKILLS / GUIDELINES
- **Sweep Count**: N
- **Clean Streak**: N/2
- **Status**: IN_PROGRESS / MAX_ITERATIONS_HIT / COMPLETE

## Summary

| Content Type | Sweeps | HIGHs Applied | MEDIUMs Applied | MEDIUMs Blocked |
|...|

## Open Blockers (N)

[B-1] Title — options: ...
[B-2] Title — options: ...

(If none: "No open blockers — loop can resume as-is.")

## Recent Decisions (last 5)

| Iter | Action | Source | Target | Decision |
|...|
```

### 4. Handle blockers

If there are OPEN blockers:

1. Present each blocker with its title, context, and options
2. Use `AskUserQuestion` to collect the user's decision for each
3. Update blockers.md: change `Status: OPEN` to `Status: RESOLVED (<chosen option>)`
4. If the resolution requires an action (e.g., "apply option A"), add guidance to progress.md's `Notes for Next Iteration` section so the next loop iteration picks it up

If the user wants to skip a blocker, leave it as OPEN.

### 5. Prepare for relaunch

Calculate suggested iterations: `max(5, 20 - SWEEP_COUNT)`.

If COMPLETE signal is present in progress.md:
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
- **Blocker resolution feeds back through progress.md** — the next loop iteration reads Notes and acts on resolved blockers
- **COMPLETE state** — when the loop finished successfully, resume shifts to review/merge guidance instead of relaunch
