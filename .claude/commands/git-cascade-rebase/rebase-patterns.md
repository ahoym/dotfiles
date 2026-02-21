# Rebase Patterns Reference

## Rebase --onto for Removing Ancestor Commits

When a commit to remove is an **ancestor** of the current branch (not a commit unique to it), a plain `git rebase main` will silently no-op ("already up to date"). You must use `--onto` with the commit-to-skip as the "upstream" argument:

```bash
# This does NOT work when <commit> is an ancestor:
git rebase main

# This DOES work - replays commits after <commit-to-skip> onto <new-base>:
git rebase --onto <new-base> <commit-to-skip>
```

**Why**: `git rebase main` checks if main is an ancestor of HEAD. If it is (because the commit is in the shared history), git considers the branch already based on main and does nothing. `--onto` explicitly tells git where to start replaying from.

## Cascade Rebase --onto Syntax

In the cascade rebase context, the three-argument form is:

```bash
git rebase --onto <new_hash_prev> <old_hash_prev> <branchN>
```

- `<new_hash_prev>`: Where to attach (tip of rebased previous branch)
- `<old_hash_prev>`: Old fork point to detach from (pre-rebase hash)
- `<branchN>`: Branch being rebased

The old hash is critical — it tells git which commits belong to branchN (everything after old_hash_prev) versus which belong to the previous branch (everything up to and including old_hash_prev). Without recording old hashes before rebasing, subsequent `--onto` operations would use the wrong fork point.

## Commit Extraction Workflow

Full pattern for moving a commit from one branch to a new standalone branch:

```bash
# 1. Create a new branch to preserve the commit
git branch <new-branch> <commit-hash>

# 2. Reset the base branch to before the commit
git checkout main
git reset --hard <commit-before>

# 3. Rebase the feature branch, skipping the extracted commit
git checkout <feature-branch>
git rebase --onto main <extracted-commit>

# 4. Push all changes to remote
git push --force-with-lease origin main
git push --force-with-lease origin <feature-branch>
git push -u origin <new-branch>
```

**Key gotcha**: Step 3 requires `--onto` (see above). A plain rebase will silently do nothing because the extracted commit is an ancestor.
