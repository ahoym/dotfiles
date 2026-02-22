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

## Fixing Misordered Stacked PR Branches

When stacked PR branches were created in the wrong order (dependent branches created before dependency commits), the fix is straightforward:

1. **Reset** the branch to the correct dependency: `git branch -f <broken-branch> <correct-base>`
2. **Worktree** to avoid disturbing the working tree: `git worktree add /tmp/fix-<name> <broken-branch>`
3. **Copy** the agent's own files from the working tree into the worktree
4. **Commit and force-push**: `git -C /tmp/fix-<name> add -A && git -C /tmp/fix-<name> commit && git -C /tmp/fix-<name> push --force`
5. **Clean up**: `git worktree remove /tmp/fix-<name>`

**Key principle:** Each branch should only contain its own agent's files. Don't bundle dependency files into the commit — let the branch ancestry provide them. CI will fail until upstream PRs merge, which is expected and documented in the PR description.

**Process in topological order** — fix dependency branches before dependent ones, since dependent branches use the fixed dependency as their base.

**Discovered from:** parallel-plan:execute session where 7 of 11 PR branches were based on `main` instead of their dependency branches, causing Vercel CI failures.

## Verify Commit State Before Committing

When `git status` shows "nothing to commit, working tree clean" but you just created/edited files, check whether the changes were already committed (e.g., by hooks or auto-commit):

```bash
git show HEAD:path/to/file
```

If the file contents are already there, the commit already happened. Don't assume changes are lost or that git is confused — check HEAD first.

## Parallel Branch Rebase with Worktree Isolation

When multiple PR branches need rebasing onto an updated main, use the Task tool with `isolation: "worktree"` and `subagent_type: "Bash"` to rebase all branches simultaneously:

```
// Launch N parallel agents, one per branch
Task(isolation: "worktree", subagent_type: "Bash", prompt: `
  git fetch origin
  git checkout feat/branch-name
  git rebase origin/main
  git push --force-with-lease origin feat/branch-name
`)
```

**Why worktree isolation:** Each rebase needs its own checkout — you can't rebase multiple branches from the same working tree. Worktree isolation gives each agent its own copy.

**Tested with 9 simultaneous rebases** — all completed in ~50s wall-clock (vs ~7min sequential). Clean rebases are near-instant per agent; the overhead is worktree creation.

**Gotcha — stale worktrees:** Rebase agents leave behind worktrees in `.claude/worktrees/` that `git clean` skips (they're nested repos). Clean up after with:
```bash
# List them
git worktree list
# Remove all stale ones
git worktree remove --force .claude/worktrees/agent-XXXXXXXX
```

These accumulate across rebase rounds — clean up before they pile up, as they hold refs to old branch HEADs.
