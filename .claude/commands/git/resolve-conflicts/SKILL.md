---
description: "Resolve merge conflicts between branches."
---

# Resolve Conflicts

Resolve merge conflicts between your PR branch and its base branch.

## Usage

- `/resolve-conflicts` - Resolve conflicts for current branch against its base
- `/resolve-conflicts <base-branch>` - Resolve against specified base branch

## Reference Files (conditional — read only when needed)

- @_shared/platform-detection.md - Platform detection for GitHub/GitLab

## Instructions

0. **Detect platform** — follow `@_shared/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns accordingly. All commands below use GitHub (`gh`) syntax; substitute GitLab equivalents if on GitLab.

1. **Determine branches**:
   - Current branch: `git branch --show-current`
   - Base branch: If `$ARGUMENTS` provided, use it. Otherwise, detect from PR or default to `origin/main`

   ```bash
   gh pr view --json baseRefName --jq '.baseRefName' 2>/dev/null || echo "main"
   ```

2. **Fetch latest**:
   ```bash
   git fetch origin <base-branch>
   ```

3. **Preview conflicts first**:
   ```bash
   git merge-tree $(git merge-base HEAD origin/<base-branch>) HEAD origin/<base-branch>
   ```

   Show which files will conflict before starting the merge.

4. **Start the merge**:
   ```bash
   git merge origin/<base-branch>
   ```

5. **For each conflicted file**:
   - Read the file to see conflict markers
   - Analyze both sides of the conflict
   - Ask user: "How should this conflict be resolved?"
     - Keep ours (current branch)
     - Keep theirs (base branch)
     - Combine both
     - Custom resolution
   - Apply the resolution and stage the file:
   ```bash
   git add <resolved-file>
   ```

6. **Complete the merge**:
   ```bash
   git commit -m "Merge <base-branch> into <current-branch>"
   ```

7. **Push to update the PR**:
   Ask: "Conflicts resolved. Push to update the PR?"
   ```bash
   git push origin <current-branch>
   ```

8. **Verify PR status**:
   ```bash
   gh pr view --json mergeable --jq '.mergeable'
   ```

   Report whether the PR is now mergeable.

## Example

```
Resolving conflicts: feature/my-branch ← main

Fetching origin/main...

Conflicts detected in 2 files:
  1. src/config.py
  2. README.md

Starting merge...

--- Conflict 1/2: src/config.py ---

<<<<<<< HEAD (your changes)
MAX_RETRIES = 5
=======
MAX_RETRIES = 3
TIMEOUT = 30
>>>>>>> origin/main

How should this be resolved?
> Combine both (keep MAX_RETRIES = 5, add TIMEOUT = 30)

Resolved and staged src/config.py

--- Conflict 2/2: README.md ---
[... continues for each file ...]

All conflicts resolved. Committing merge...
Push to update PR? (y/n)
> y

Pushed. PR #8 is now mergeable.
```

## Important Notes

- Use merge (not rebase) when changes are independent of feature code
- Always fetch the latest base branch before starting
- If the merge gets complicated, you can abort with `git merge --abort`
