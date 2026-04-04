---
name: prune-merged
description: "Clean up local branches that have been merged into main."
allowed-tools:
  - Read
  - Bash
  - AskUserQuestion
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

   **Method C - Cross-reference against merged PRs:**
   ```bash
   gh pr list --state merged --json headRefName --jq '.[].headRefName'
   ```
   Match against local branch names. This catches squash-merged branches that Methods A and B both miss — e.g., branches tracking `origin/main` instead of their own remote, or branches with no tracking branch at all.

   Combine all three lists, removing duplicates. This catches:
   - Branches with commits directly in origin/main history (regular merge)
   - Branches whose remote tracking branch was deleted after merge (squash merge)
   - Branches with confirmed merged PRs regardless of tracking config

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
     - "Select branches" - Let the operator choose which to delete
     - "Cancel" - Exit without deleting

5. **Delete confirmed branches**:

   For branches detected via **Method A** (regular merge):
   ```bash
   git branch -d <branch-name>
   ```

   For branches detected via **Method B** (squash merge / gone remote) or **Method C** (confirmed merged PR):
   ```bash
   git branch -D <branch-name>
   ```

   Note: Method A branches use `-d` as a safety check. Method B/C branches
   require `-D` because their commits aren't in main's history (they were
   squashed). The "gone" remote or merged PR is the indicator that the PR was merged.

   **Worktree conflicts:** If `git branch -D` fails with "used by worktree at ...",
   check `git worktree list` for stale worktrees (from completed agent sessions).
   Offer to run `git worktree remove --force <path>` for each stale worktree,
   then retry the branch deletion.

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
- **Worktrees**: Branches in use by worktrees cannot be deleted; offer to remove stale worktrees first
- **PR cross-reference**: Method C catches branches that Methods A and B miss (e.g., branches tracking `origin/main`)

## Known Edge Cases

### Branch tracking `origin/main` instead of its own remote

**Symptom**: A squash-merged branch isn't detected by Methods A or B even after `git fetch --prune`.

**Cause**: The branch was configured to track `origin/main` directly instead of `origin/<branch-name>`. Method B fails because `origin/main` still exists (no `: gone]`).

**Resolution**: Method C (`gh pr list --state merged`) catches these automatically by matching local branch names against merged PR head refs, regardless of tracking configuration.
