---
name: resolve-conflicts
description: "Sync branch with base (pull main, rebase, merge) — assesses divergence, picks the right strategy, and resolves conflicts. Use when: pulling main, rebasing onto main, merging branches, or fixing merge conflicts."
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Resolve Conflicts

Sync your branch with its base branch. Assesses the situation, recommends the best strategy (merge vs rebase), and resolves any conflicts.

## Usage

- `/resolve-conflicts` - Sync current branch with its base (auto-detects strategy)
- `/resolve-conflicts <base-branch>` - Sync against specified base branch
- `/resolve-conflicts --preview` - Assess and preview only (no merge/rebase)
- `/resolve-conflicts --merge` or `--rebase` - Force a specific strategy

## Reference Files (conditional — read only when needed)

- @~/.claude/skill-references/platform-detection.md - Platform detection for GitHub/GitLab

## Instructions

### 0. Detect platform

Follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

### 1. Determine branches

- Current branch: `git branch --show-current`
- Base branch: If `$ARGUMENTS` provides one, use it. Otherwise detect:
  ```bash
  gh pr view --json baseRefName --jq '.baseRefName' 2>/dev/null || echo "main"
  ```
- Parse flags: `--preview`, `--merge`, `--rebase` from `$ARGUMENTS`

### 2. Pre-flight assessment

Gather situation data before choosing a strategy:

```bash
git fetch origin <base-branch>
```

| Signal | Command | What it tells you |
|--------|---------|-------------------|
| **Divergence** | `git log --oneline HEAD..origin/<base-branch> \| wc -l` | How many incoming commits |
| **Branch commits** | `git log --oneline origin/<base-branch>..HEAD \| wc -l` | How many local commits to replay |
| **Conflict preview** | `git merge-tree $(git merge-base HEAD origin/<base-branch>) HEAD origin/<base-branch>` | Which files conflict and why |
| **Conflict file types** | Inspect conflict preview output | Ephemeral (output/logs/tracking) vs source files |

Present the assessment:
```
## Branch Sync Assessment

Current: feature/my-branch (12 commits ahead)
Base: origin/main (8 commits behind)

Conflict preview: 3 files
  - .claude/consolidate-output/report.md (ephemeral — deleted on branch, modified on main)
  - .claude/consolidate-output/progress.md (ephemeral — same pattern)
  - src/config.py (source — both sides modified)

Strategy recommendation: merge (see below)
```

If `--preview` flag is set, stop here.

### 3. Recommend strategy

Apply these heuristics in order:

| Condition | Recommendation | Reason |
|-----------|---------------|--------|
| User forced `--merge` or `--rebase` | Use their choice | Explicit override |
| Ephemeral-file conflicts + incoming commits > ~5 | **Merge** | Rebase produces identical modify/delete conflicts on every commit — N resolutions instead of 1 |
| Few commits on both sides, no ephemeral conflicts | **Rebase** | Clean linear history, low conflict risk |
| Many local commits + source conflicts | **Merge** | Rebase conflict resolution compounds — each resolved commit changes the base for the next |
| Simple fast-forward possible | **Rebase** (fast-forward) | No conflicts at all |

Present the recommendation with reasoning. Ask user to confirm or override.

### 4. Execute strategy

**If merge:**
```bash
git merge origin/<base-branch>
```

**If rebase:**
```bash
git rebase origin/<base-branch>
```

If no conflicts → skip to step 6.

### 5. Resolve conflicts

**Monitor for repetitive patterns.** If 2+ conflicts are the same type (e.g., modify/delete on ephemeral files), flag the pattern:
```
⚠️ Seeing repetitive modify/delete conflicts on output files.
These are all the same resolution (delete). Resolving in batch.
```

For batch-resolvable conflicts (same resolution for all):
```bash
git rm <file1> <file2> <file3>
# or: git checkout --ours <file1> <file2>
# or: git checkout --theirs <file1> <file2>
```

For unique source-file conflicts — resolve individually:
- Read the file to see conflict markers
- Analyze both sides
- Ask user for resolution approach:
  - Keep ours (current branch)
  - Keep theirs (base branch)
  - Combine both
  - Custom resolution
- Apply and stage: `git add <resolved-file>`

**If rebase and conflicts are escalating** (each step produces new conflicts on different files), surface this:
```
⚠️ Rebase conflicts are compounding — each commit introduces new conflicts.
Recommend: abort rebase and switch to merge. Proceed?
```
If user agrees: `git rebase --abort` → restart with merge strategy.

### 6. Complete and push

**If merge:**
```bash
git commit -m "Merge <base-branch> into <current-branch>"
```

**If rebase:** No commit needed (rebase replays commits).

Ask: "Sync complete. Push to update remote?"
```bash
git push origin <current-branch>
```
Note: rebase after push requires `--force-with-lease`. Warn user before force-pushing.

### 7. Verify

```bash
gh pr view --json mergeable --jq '.mergeable' 2>/dev/null
```

Report whether the PR is now mergeable (if a PR exists).

## Important Notes

- Always fetch before assessing — stale refs produce wrong recommendations
- `--force-with-lease` is safer than `--force` after rebase (fails if someone else pushed)
- If the merge/rebase gets complicated, abort is always available: `git merge --abort` or `git rebase --abort`
