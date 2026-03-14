---
name: resolve-conflicts
description: "Resolve merge or rebase conflicts between branches."
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Resolve Conflicts

Resolve merge or rebase conflicts between your PR branch and its base branch.

## Usage

- `/resolve-conflicts` - Resolve conflicts via merge (default)
- `/resolve-conflicts --rebase` - Resolve via rebase (rewrites history, requires force push)
- `/resolve-conflicts <base-branch>` - Resolve against specified base branch
- `/resolve-conflicts --preview` - Preview conflicts only (no merge or rebase)

Flags can be combined: `/resolve-conflicts --rebase main`

## Reference Files (conditional — read only when needed)

- `~/.claude/skill-references/platform-detection.md` — read if platform not yet detected this session

## Instructions

0. **Detect platform** — if not already detected this session, read `~/.claude/skill-references/platform-detection.md` and follow its logic to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns accordingly. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

1. **Parse arguments**:
   - If `$ARGUMENTS` contains `--preview`, set `PREVIEW_ONLY=true`
   - If `$ARGUMENTS` contains `--rebase`, set `STRATEGY=rebase`, otherwise `STRATEGY=merge`
   - Remaining args = base branch override

2. **Determine branches**:
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

5. **Preview conflicts**:
   ```bash
   git merge-tree $(git merge-base HEAD origin/<base-branch>) HEAD origin/<base-branch>
   ```
   Show which files will conflict. If `PREVIEW_ONLY=true`, stop here.

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

   - Ask user: "How should this conflict be resolved?"
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

- **Default to merge** when changes are independent of feature code
- **Use rebase** when you want clean linear history on a feature branch
- Always fetch the latest base branch before starting
- Abort if needed: `git merge --abort` or `git rebase --abort`
- Rebase rewrites history — requires `--force-with-lease` push
