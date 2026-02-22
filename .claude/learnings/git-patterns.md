# Git Patterns

## Commit-Message-Based Identification for Rebase

When you need to find and drop a specific commit during rebase, use a known commit message instead of positional logic (`tail -1`, `head -1`):

```bash
MERGE_BASE=$(git merge-base HEAD origin/main)
SKILLS_COMMIT=$(git log --format="%H %s" "$MERGE_BASE"..HEAD | grep "\[web-session\] sync skills" | awk '{print $1}')
git rebase --onto origin/main "$SKILLS_COMMIT"
```

**Why message-based over positional:**
- Robust against extra commits between merge-base and feature commits
- Works even if someone manually commits on the branch before branching off
- Self-documenting — the grep pattern makes intent clear

**Convention:** Use bracketed prefixes in commit messages (e.g., `[web-session]`) to make them greppable without false positives.

## rsync --delete Auto-Removes Renamed Directories

When using `rsync --delete` to sync directories, renaming a source directory (e.g., `git-address-mr-review` → `git-address-pr-review`) automatically deletes the old-named directory from the target. This is because `--delete` removes anything in the target that doesn't exist in the source.

**Implication:** For repo migrations that rename multiple directories (e.g., MR→PR skill renaming), a single rsync with `--delete` handles both copying new dirs and removing old dirs — no need for separate `rm -rf` cleanup commands.

## Verify Commit State Before Committing

When `git status` shows "nothing to commit, working tree clean" but you just created/edited files, check whether the changes were already committed (e.g., by hooks or auto-commit):

```bash
git show HEAD:path/to/file
```

If the file contents are already there, the commit already happened. Don't assume changes are lost or that git is confused — check HEAD first.
