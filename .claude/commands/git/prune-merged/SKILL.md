---
description: "Clean up local branches that have been merged into main."
---

# Prune Merged Branches

Remove local branches that have already been merged into remote main.

## Usage

- `/git:prune-merged` - List and prune merged branches (with confirmation)
- `/git:prune-merged --dry-run` - Only list branches that would be pruned

## Instructions

1. **Fetch latest from remote**:
   ```bash
   git fetch origin main --prune
   ```

2. **Find merged branches** (store as `MERGED_BRANCHES`):

   Detect branches merged via two methods:

   **Method A - Regular merges:**
   ```bash
   git branch --merged origin/main | grep -v '^\*' | grep -v 'main' | grep -v 'master'
   ```

   **Method B - Squash merges (remote branch deleted after PR merge):**
   ```bash
   git branch -vv | grep ': gone]' | awk '{print $1}'
   ```

   Combine both lists, removing duplicates. This catches:
   - Branches with commits directly in origin/main history (regular merge)
   - Branches whose remote tracking branch was deleted after merge (squash merge)

3. **Handle dry-run mode**:
   - If `$ARGUMENTS` contains `--dry-run`:
     - Display the list of branches that would be pruned
     - Exit without deleting

4. **Display branches for confirmation**:
   - If `MERGED_BRANCHES` is empty:
     ```
     No merged branches to prune. All local branches have unmerged commits.
     ```
     Exit here.

   - Otherwise, display:
     ```
     Found merged branches to prune:

     | Branch | Last Commit |
     |--------|-------------|
     | feature/auth | 3 days ago |
     | fix/login-bug | 1 week ago |
     ```

   - Use `AskUserQuestion` to confirm:
     - "Delete all" - Delete all listed branches
     - "Select branches" - Let user choose which to delete
     - "Cancel" - Exit without deleting

5. **Delete confirmed branches**:

   For branches detected via **Method A** (regular merge):
   ```bash
   git branch -d <branch-name>
   ```

   For branches detected via **Method B** (squash merge / gone remote):
   ```bash
   git branch -D <branch-name>
   ```

   Note: Method A branches use `-d` as a safety check. Method B branches
   require `-D` because their commits aren't in main's history (they were
   squashed). The "gone" remote is the indicator that the PR was merged.

6. **Report results**:
   ```
   Pruned branches:
   - feature/auth
   - fix/login-bug

   Kept branches:
   - (none)

   Remaining local branches: 3
   ```

## Example Output

```
$ /git:prune-merged

Fetching latest from origin...

Found merged branches to prune:

| Branch | Last Commit |
|--------|-------------|
| docs/update-readme | 2 days ago |
| feature/add-auth | 1 week ago |
| fix/typo | 3 weeks ago |

? Delete these branches?
> Delete all
  Select branches
  Cancel

Pruned branches:
- docs/update-readme
- feature/add-auth
- fix/typo

Remaining local branches: 2 (main, feature/in-progress)
```

## Important Notes

- **Squash merge support**: Detects branches whose remote was deleted after PR merge, even if squash-merged
- **Safe deletion**: Regular merges use `-d`; squash merges use `-D` (safe because remote deletion confirms merge)
- **Protected branches**: Never deletes `main`, `master`, or the current branch
- **Remote cleanup**: Run `git fetch --prune` separately to clean up stale remote-tracking references
- **Worktrees**: Branches in use by worktrees cannot be deleted; detach the worktree first

## Known Edge Cases

### Branch tracking `origin/main` instead of its own remote

**Symptom**: A squash-merged branch isn't detected even after `git fetch --prune`.

**Cause**: The branch was configured to track `origin/main` directly instead of `origin/<branch-name>`. When checking `git branch -vv`, it shows `[origin/main: ahead X]` instead of `[origin/<branch-name>: gone]`.

**Detection**: Method B (`git branch -vv | grep ': gone]'`) fails because `origin/main` still exists.

**Resolution**: These branches require manual identification. Check `git branch -vv` for branches showing `[origin/main: ahead X]` where the remote branch no longer exists:
```bash
# Check if the branch's expected remote exists
git branch -r | grep "<branch-name>"
# If no output, the branch was likely merged and can be deleted with -D
```

**Example**: Branch `feature/user-settings` tracked `origin/main` instead of `origin/feature/user-settings`. After the PR was squash-merged and the remote deleted, it showed `[origin/main: ahead 3]` instead of `: gone]`.
