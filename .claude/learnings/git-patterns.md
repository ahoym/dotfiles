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

## Fixing Misordered Stacked PR Branches

When stacked PR branches were created in the wrong order (dependent branches created before dependency commits), the fix is straightforward:

1. **Reset** the branch to the correct dependency: `git branch -f <broken-branch> <correct-base>`
2. **Worktree** to avoid disturbing the working tree: `git worktree add /tmp/fix-<name> <broken-branch>`
3. **Copy** the agent's own files from the working tree into the worktree
4. **Commit and force-push**: `git -C /tmp/fix-<name> add -A && git -C /tmp/fix-<name> commit && git -C /tmp/fix-<name> push --force`
5. **Clean up**: `git worktree remove /tmp/fix-<name>`

**Key principle:** Each branch should only contain its own agent's files. Don't bundle dependency files into the commit — let the branch ancestry provide them. CI will fail until upstream PRs merge, which is expected and documented in the PR description.

**Process in topological order** — fix dependency branches before dependent ones, since dependent branches use the fixed dependency as their base.

## Verify Commit State Before Committing

When `git status` shows "nothing to commit, working tree clean" but you just created/edited files, check whether the changes were already committed (e.g., by hooks or auto-commit):

```bash
git show HEAD:path/to/file
```

If the file contents are already there, the commit already happened. Don't assume changes are lost or that git is confused — check HEAD first.

## Parallel Branch Rebase with Worktree Isolation

When multiple independent PR branches need rebasing onto updated main, launch one Task agent per branch with `isolation: "worktree"` and `subagent_type: "Bash"`. Each agent: fetch, checkout, rebase, force-push-with-lease. Worktree isolation is required because each rebase needs its own checkout.

**Performance:** 9 simultaneous rebases completed in ~50s vs ~7min sequential.

**Gotcha — stale worktrees:** Agents leave worktrees in `.claude/worktrees/` that `git clean` skips. Clean up with `git worktree list` + `git worktree remove --force`. These accumulate and hold refs to old branch HEADs.

## Bulk PR Content Extraction Without Checkout

Use `git fetch origin <branch>` + `git show origin/<branch>:<path>` to extract files from unmerged PR branches without checkout. Prefix output files with `pr{N}-` to avoid collisions when multiple PRs touch the same filename.

```bash
for pr in 2 3 4 5; do
  branch=$(gh pr view $pr --json headRefName -q .headRefName)
  git fetch origin "$branch" --quiet
  git show "origin/$branch:docs/topic.md" > "pr${pr}-topic.md"
done
```

**Why this over merging:** Avoids merge conflicts between branches, works with stale branches, and lets downstream tools handle deduplication. Clean up after with `gh pr close $pr --comment "Content extracted." --delete-branch`.

## pnpm Lockfile Rebase Conflicts

When rebasing causes conflicts in `pnpm-lock.yaml`, don't attempt manual merge. Instead:

```bash
git checkout --theirs pnpm-lock.yaml
pnpm install --frozen-lockfile=false
git add pnpm-lock.yaml
git rebase --continue
```

This accepts the upstream lockfile, then regenerates it with your branch's added/modified dependencies. Works because the lockfile is deterministically generated from `package.json`.

## `git add <file>` Can Commit Unintended Files

When `git add <specific-file>` is followed by `git commit`, pre-commit hooks or other mechanisms may auto-stage additional modified files. Verify with `git status` after committing that only intended files were included. If unexpected files were committed, use `git reset HEAD~1` to undo and re-stage selectively.

## Pre-Commit Hooks Can Alter Commits Silently

Pre-commit hooks may modify staged files (formatting, linting) or change the commit message. After committing, verify with `git log --oneline -1` that the message matches expectations. If the hook modifies files post-stage, those changes appear as new unstaged modifications — not a sign that the commit failed.

## Worktrees for Claude Code Settings Isolation

Git worktrees provide natural isolation for `.claude/settings.local.json`. Each worktree gets its own copy of the file at checkout, so hooks/permissions injected there don't affect the main repo or other worktrees.

**How it works:** Claude Code loads **user-level** (`~/.claude/settings.local.json`) + **project-level** (`<cwd-project-root>/.claude/settings.local.json`). A worktree is its own project root, so `claude --print` run from a worktree picks up the worktree's settings — not the main repo's.

**Use case:** Inject PreToolUse security hooks into a worktree's settings for unattended loops (`--dangerously-skip-permissions`), then remove on exit. The main repo's settings are never touched.

**Workflow benefit:** Eliminates the fragile `git stash → checkout → branch → stash pop → commit → push → checkout back` dance. With worktrees: `git worktree add` → loop in worktree → commit+push from worktree → `git worktree remove`. No stashing, no branch switching in the main tree, concurrent-safe.

```bash
# Inject hooks into worktree settings (preserves existing keys like permissions)
jq --argjson hooks "$HOOKS_JSON" '.hooks = $hooks' "$WORKTREE/.claude/settings.local.json" > tmp && mv tmp "$_"
# Remove on exit
jq 'del(.hooks)' "$WORKTREE/.claude/settings.local.json" > tmp && mv tmp "$_"
```
