---
name: cleanup
description: "Clean up stale research worktrees whose branches have been merged or deleted."
disable-model-invocation: true
---

# Clean Up Ralph Worktrees

Prune stale ralph worktrees by checking if their branches have been merged or deleted on the remote.

## Usage

- `/ralph:cleanup` - Scan and offer to remove stale worktrees

## Instructions

1. **List ralph worktrees**:
   ```bash
   git worktree list
   ```
   - Filter for worktrees with paths containing `.claude/worktrees/ralph-`
   - If none found, report "No ralph worktrees found." and exit

2. **Classify each worktree**:
   For each ralph worktree, extract the branch name and check its status:

   - **MERGED**: branch is merged into main (`git branch --merged main` includes it) — safe to remove
   - **REMOTE DELETED**: branch existed on remote but was deleted (`git ls-remote --heads origin <branch>` returns nothing AND the branch has upstream tracking configured) — likely merged via PR, safe to remove
   - **LOCAL ONLY**: branch was never pushed (no upstream tracking: `git -C <worktree-path> rev-parse --abbrev-ref @{upstream}` fails) — ambiguous, prompt user
   - **ACTIVE**: branch exists on remote and is not merged — may have an open PR or ongoing work
   - **DIRTY**: worktree has uncommitted changes (`git -C <worktree-path> status --porcelain` is non-empty) — warn before removing, can combine with other statuses (e.g., "MERGED + DIRTY")

3. **Present findings**:
   Show a summary table of worktrees with their status and branch name. Example:
   ```
   Ralph worktrees:
   - ralph-my-topic (research/my-topic) — MERGED, safe to remove
   - ralph-other-topic (research/other-topic) — ACTIVE, branch on remote
   - ralph-old-thing (research/old-thing) — REMOTE DELETED, likely merged via PR
   - ralph-experiment (research/experiment) — LOCAL ONLY, never pushed
   - ralph-wip (research/wip) — ACTIVE + DIRTY, uncommitted changes
   ```

4. **Ask which to remove**:
   - **Auto-suggest** removing MERGED and REMOTE DELETED (safe to remove)
   - **Prompt individually** for LOCAL ONLY — ask whether the work is valuable or can be discarded. These are ambiguous: might be abandoned experiments or might be unpushed work the user forgot about
   - **Warn** if any are DIRTY (have uncommitted changes) — require explicit confirmation
   - **Skip** ACTIVE worktrees unless user explicitly requests

5. **Remove selected worktrees**:
   For each worktree to remove:
   ```bash
   git worktree remove <worktree-path>
   ```
   - If removal fails (locked/dirty), use `--force` only with user confirmation
   - Optionally delete the local branch: `git branch -d <branch>` (only if merged)

6. **Report results**:
   ```
   Cleaned up N ralph worktree(s).
   Remaining: M active worktree(s).
   ```
