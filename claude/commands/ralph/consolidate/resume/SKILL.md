---
name: resume
description: "Evaluate consolidation run quality, handle review items, and prepare to merge or relaunch."
disable-model-invocation: true
allowed-tools:
  - Read
  - Edit
  - Glob
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Resume Consolidation Loop

Evaluate the quality of a completed or stalled consolidation loop, handle any review items, and print the relaunch command.

## Instructions

### 1. Locate the worktree

- If `$ARGUMENTS` provided, use as the worktree path
- Otherwise, list directories matching `claude/worktrees/consolidate-*` and prompt for selection
- If no worktrees found, error: "No consolidation worktrees found. Run `/ralph:consolidate:init` first."

### 2. Read state

Read from `<worktree>/claude/consolidate-output/`:

| File | What to extract |
|------|-----------------|
| `progress.md` | State variables (SWEEP_COUNT, CONTENT_TYPE, PHASE), iteration log, notes |
| `report.md` | Summary table, total actions, status |
| `review.md` | Any review items (LOWs, blocked MEDIUMs, loop limits) |
| `decisions.md` | Last 10 rows (recent actions for context) |

### 3. Evaluate run

| Dimension | Check | Source |
|-----------|-------|--------|
| **Broad sweep yield** | Finding count, clean or messy? | Iteration log |
| **Action quality** | HIGHs genuine? MEDIUMs well-calibrated? | decisions.md rationales |
| **Deep dive yield** | Substantive vs clean ratio | Iteration log |
| **Compounding** | Insights compounded? If zero, why? | Iteration log notes |
| **Spec compliance** | SWEEP_COUNT matches log file count? | progress.md + Glob on logs/ |
| **Adjacent patterns** | Deep dives noting patterns for unprocessed files? | Notes for Next Iteration |
| **Carryover framing** | MAX_DEEP_DIVES_HIT: periodic review or unfinished? | DEEP_DIVE_CANDIDATES, tracker |

Flag anything warranting discussion. Spec compliance uses `Glob` (not Bash).

### 4. Present status

```markdown
# Resume: Consolidation <date>

## State
- **Content Type**: LEARNINGS / SKILLS / GUIDELINES
- **Sweep Count**: N
- **Phase**: BROAD_SWEEP / DEEP_DIVE
- **Status**: IN_PROGRESS / COMPLETE

## Summary

| Content Type | Sweeps | HIGHs Applied | MEDIUMs Applied | MEDIUMs Blocked |
|...|

## Evaluation

[Structured analysis from step 3. Flag items warranting discussion.]

## Review Items (N)

[L-1] Title — ambiguous classification...
[BM-1] Title — blocked MEDIUM, options: ...

(If none: "No review items — loop can resume as-is.")

## Recent Decisions (last 5)

| Iter | Action | Source | Target | Decision |
|...|
```

### 5. Handle review items

If there are review items in `review.md`:

1. Present each item with its title, context, tag, and options
2. Use `AskUserQuestion` to collect the user's decision for each
3. Update review.md: append `**Status**: RESOLVED (<chosen option>)` to the item
4. If the resolution requires an action (e.g., "apply option A"), add guidance to progress.md's `Notes for Next Iteration` section so the next loop iteration picks it up

If the user wants to skip an item, leave it without a Status line.

**Changes belong on the consolidation branch, not main.** Any file edits made while resolving review items should be committed to the consolidation branch — not to main. The consolidation branch is the PR unit; direct commits to main bypass review. Use `~/.claude/` tilde paths for Edit/Write (they land on the shared filesystem), then stage and commit from the worktree's git context.

**Recommendation framing**: When presenting options, prefer recommending the option that fixes root cause (wire, restructure, merge) over the option that accepts dysfunction (delete, skip). Deletion is irreversible; wiring is reversible. Only recommend cleanup when the content is stale, incorrect, or has no identifiable consumers.

### 6. Prepare for relaunch

Calculate suggested iterations based on pre-flight cadence (from progress.md) and remaining work:
- Read `Cadence` and `Suggested iterations` from the Pre-Flight section
- Base: `max(5, <init_suggested> - SWEEP_COUNT)` where `<init_suggested>` is the value from pre-flight (default 20 if not present)

If COMPLETE or MAX_DEEP_DIVES_HIT signal is present in progress.md:
- MAX_DEEP_DIVES_HIT: carryover candidates are staleness-eligible periodic review, not unfinished work — merge path applies with a note about what carries over
- **Clean up working files**: Remove `consolidate-output/` from the branch — these are working state, not deliverables. Run `git rm -r claude/consolidate-output/` and commit with message `consolidate: remove working files before merge`.
- Ask if the user wants to review the diff: `git diff main -- claude/`
- Suggest merging: `git checkout main && git merge <branch>`
- Do NOT suggest relaunching

Otherwise:

```
Ready to resume. Run:
  cd <worktree>
  bash ~/.claude/ralph/consolidate/wiggum.sh <suggested_iterations>
```

## Design Notes

- **Does not auto-launch** — `wiggum.sh` invokes `claude --print` (cannot be called from within Claude)
- **Review item resolution** feeds back through progress.md Notes
- **COMPLETE state** → review/merge guidance instead of relaunch
- **Evaluation before interaction** — surfaces quality patterns before review decisions
