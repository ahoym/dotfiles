---
name: resolve-conflicts
description: "Resolve merge or rebase conflicts between branches."
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Resolve Conflicts

Resolve merge or rebase conflicts between your PR branch and its base branch.

## Usage

- `/resolve-conflicts` - Auto-select strategy (rebase preferred, merge when cheaper)
- `/resolve-conflicts --rebase` - Force rebase (skip auto-selection)
- `/resolve-conflicts --merge` - Force merge (skip auto-selection)
- `/resolve-conflicts <PR-number>` - Resolve conflicts on a specific PR (checks out the branch)
- `/resolve-conflicts <base-branch>` - Resolve against specified base branch
- `/resolve-conflicts --preview` - Preview conflicts only (no merge or rebase)

Flags can be combined: `/resolve-conflicts --merge main`

## Instructions

0. **Platform commands** — platform-specific commands are inlined below via `!` preprocessing. No detection needed.

1. **Parse arguments**:
   - If `$ARGUMENTS` contains `--preview`, set `PREVIEW_ONLY=true`
   - If `$ARGUMENTS` contains `--merge`, set `STRATEGY=merge` (skip auto-selection in step 5)
   - If `$ARGUMENTS` contains `--rebase`, set `STRATEGY=rebase` (skip auto-selection in step 5)
   - If neither `--merge` nor `--rebase`, set `STRATEGY=auto`
   - If remaining arg is a number, treat it as a PR/MR number (set `PR_NUMBER`)
   - Otherwise, remaining arg = base branch override

2. **Determine branches**:

   **If PR_NUMBER is set:**
   ```bash
   gh pr view <PR_NUMBER> --json headRefName,baseRefName --jq '{head: .headRefName, base: .baseRefName}'
   ```
   - Set base branch from `baseRefName`
   - If current branch != `headRefName`, check out the PR branch:
     ```bash
     gh pr checkout <PR_NUMBER>
     ```
   - Current branch is now the PR's head branch

   **Otherwise:**
   - Current branch: `git branch --show-current`
   - Base branch: If override provided, use it. Otherwise, detect from PR or default to `origin/main`
     ```bash
     gh pr view --json baseRefName --jq '.baseRefName' 2>/dev/null || echo "main"
     ```

3. **Check for dirty working tree**:
   ```bash
   git status --porcelain
   ```
   If dirty files exist, stash them before proceeding:
   ```bash
   git stash push -m "resolve-conflicts: stash before <STRATEGY>"
   ```
   Set `STASHED=true` to restore later.

4. **Fetch latest**:
   ```bash
   git fetch origin <base-branch>
   ```

5. **Preview conflicts and select strategy**:

   Preview which files will conflict:
   ```bash
   git merge-tree $(git merge-base HEAD origin/<base-branch>) HEAD origin/<base-branch>
   ```
   Extract the list of conflicted files from the output. If `PREVIEW_ONLY=true`, show conflicts and stop here.

   **If STRATEGY=auto**, analyze the branch to select the best strategy:

   Run these in parallel:
   ```bash
   # (a) Check for merge commits on the branch
   git log --merges --oneline origin/<base-branch>..HEAD

   # (b) Count commits on the branch
   git rev-list --count origin/<base-branch>..HEAD

   # (c) For each commit, list which files it touches (intersect with conflicted files)
   git log --name-only --pretty=format:--- origin/<base-branch>..HEAD
   ```

   Then compute:
   - `has_merge_commits` = whether (a) returned any results
   - `commit_count` = result of (b)
   - `rebase_rounds` = for each conflicted file, count how many commits touch it (from c). Sum across all conflicted files.
   - `merge_rounds` = number of conflicted files

   **Decision logic:**
   1. If `has_merge_commits` → **MERGE**. Rebasing merge commits requires `--rebase-merges` and produces confusing conflict contexts — strictly worse for token cost.
   2. If `rebase_rounds > merge_rounds × 1.5` → **MERGE**. Multiple commits touching the same conflicted files means rebase will re-conflict on the same file repeatedly, multiplying resolution rounds.
   3. Otherwise → **REBASE**. Clean linear history is worth the small overhead when conflict rounds are comparable.

   **Announce the selection with the estimate:**
   ```
   Strategy: auto → <REBASE|MERGE>
   Reason: <why>
   Estimated resolution rounds: rebase=<N>, merge=<N>
   ```

6. **Start the operation**:

   **If STRATEGY=merge:**
   ```bash
   git merge origin/<base-branch>
   ```

   **If STRATEGY=rebase:**
   ```bash
   git rebase origin/<base-branch>
   ```

   **Rebase note:** Conflicts appear per-commit, not all at once. After resolving each commit's conflicts, `git rebase --continue` advances to the next. Be prepared for multiple conflict rounds.

7. **For each conflicted file**:
   - Locate conflict markers surgically — don't read the full file:
     ```bash
     grep -n '<<<<<<' <file>
     ```
   - Read only the conflict regions using offset+limit (±10 lines around each marker). Full file reads on large files (400+ lines) waste context budget when only 20-30 lines are conflicted.
   - Analyze both sides of the conflict

   **Rebase-specific: `--ours`/`--theirs` are inverted.** During rebase, `--ours` = the base branch (what you're rebasing onto), `--theirs` = your commit being replayed. This is the opposite of merge. Always verify with a content check after using `git checkout --ours/--theirs`.

   **Rebase-specific: check for file renames.** If the base branch renamed files, conflicts appear under the new filename but contain content from the old. Check both filenames on the base branch to determine what content is already covered before resolving.

   - Ask the operator: "How should this conflict be resolved?"
     - Keep ours (current branch in merge / base branch in rebase)
     - Keep theirs (base branch in merge / your commit in rebase)
     - Combine both
     - Custom resolution
   - Apply the resolution and stage the file:
   ```bash
   git add <resolved-file>
   ```

8. **Complete the operation**:

   **If STRATEGY=merge:**
   ```bash
   git commit -m "Merge <base-branch> into <current-branch>"
   ```

   **If STRATEGY=rebase:**
   ```bash
   git rebase --continue
   ```
   Repeat steps 7-8 for each commit with conflicts until rebase completes.

9. **Restore stashed changes** (if `STASHED=true`):
   ```bash
   git stash pop
   ```
   If stash pop itself conflicts (common after rebase — stash has pre-rebase content), resolve by keeping the post-rebase version (authoritative), then `git stash drop`.

10. **Push to update the PR**:

    **If STRATEGY=merge:**
    Ask: "Conflicts resolved. Push to update the PR?"
    ```bash
    git push origin <current-branch>
    ```

    **If STRATEGY=rebase:**
    Ask: "Rebase complete. This requires a force push (history was rewritten). Push?"
    ```bash
    git push --force-with-lease origin <current-branch>
    ```

11. **Verify PR status**:
    ```bash
    gh pr view --json mergeable --jq '.mergeable'
    ```
    Report whether the PR is now mergeable.

## Example (auto-selection → rebase)

```
Resolving conflicts: feature/my-branch vs main

Strategy: auto → REBASE
Reason: no merge commits, low conflict overlap (2 rounds either way)
Estimated resolution rounds: rebase=2, merge=2

Rebasing (3/5) — conflict in src/config.py
...
```

## Example (auto-selection → merge)

```
Resolving conflicts: feature/my-branch vs main

Strategy: auto → MERGE
Reason: 4 commits touch the same 2 conflicted files (rebase=7 rounds vs merge=2)
Estimated resolution rounds: rebase=7, merge=2

Conflicts detected in 2 files:
  1. src/config.py
  2. src/utils.py
...
```

## Example (merge)

```
Resolving conflicts (merge): feature/my-branch ← main

Conflicts detected in 2 files:
  1. src/config.py
  2. README.md

--- Conflict 1/2: src/config.py ---
How should this be resolved?
> Combine both

All conflicts resolved. Push to update PR? → Pushed. PR #8 is now mergeable.
```

## Example (rebase)

```
Resolving conflicts (rebase): feature/my-branch onto main

Rebasing (3/5) — conflict in src/config.py

--- Conflict: src/config.py ---
Note: during rebase, "ours" = main, "theirs" = your commit
How should this be resolved?
> Combine both

Resolved. Continuing rebase...
Rebasing (4/5) — clean
Rebasing (5/5) — clean

Rebase complete. Force push to update PR? → Pushed. PR #8 is now mergeable.
```

## Important Notes

- **Default is auto-selection** — prefers rebase for clean history, falls back to merge when it's cheaper (merge commits on branch, or rebase would re-conflict the same files across multiple commits)
- **Use `--rebase` or `--merge`** to skip auto-selection and force a strategy
- Always fetch the latest base branch before starting
- Abort if needed: `git merge --abort` or `git rebase --abort`
- Rebase rewrites history — requires `--force-with-lease` push
