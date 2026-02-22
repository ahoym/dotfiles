# Git Workflows Learnings

## Retargeting PRs with gh pr edit --base

**Utility: Medium**

When stacked PRs target `main` but actually depend on a foundation branch, retarget them after rebasing:

```bash
gh pr edit <PR_NUMBER> --base <new-base-branch>
```

This updates the PR's base branch on GitHub without requiring a new PR. Combine with rebasing to ensure the diff shown in the PR is clean (only the PR's own changes, not the base branch's).

## Cascade Rebase Pattern for Stacked Branches

**Utility: High**

When a base branch is updated (e.g., lockfile fix on `feat/foundation`), rebase all dependent branches in a loop:

```bash
for branch in feat/child-1 feat/child-2 feat/child-3; do
  git checkout -B "$branch" "origin/$branch"
  git rebase feat/foundation
  git push --force-with-lease origin "$branch"
done
```

Key details:
- `checkout -B` resets the local branch to match remote, avoiding stale local state
- `--force-with-lease` is safer than `--force` — refuses if remote has new commits you haven't seen
- After rebasing, retarget PRs: `gh pr edit <N> --base feat/foundation`
- If any rebase has conflicts, the loop stops — fix conflicts, `git rebase --continue`, then resume the loop manually
- Works well when all child branches diverged from the same point on the base branch (parallel feature branches)
