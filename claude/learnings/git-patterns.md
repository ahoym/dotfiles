Git workflow patterns — rebase strategies, stacked PRs, worktree isolation, lockfile conflicts, bulk extraction, and GitHub API pagination.
- **Keywords:** rebase, stacked PR, worktree, cherry-pick, pnpm lockfile, force-push-with-lease, cascade rebase, git mv, soft reset, zsh glob, GitHub API pagination, symlink
- **Related:** ~/.claude/learnings/bash-patterns.md, ~/.claude/learnings/cicd/gotchas.md

---

## Commit-Message-Based Identification for Rebase

When you need to find and drop a specific commit during rebase, use a known commit message instead of positional logic (`tail -1`, `head -1`):

```bash
MERGE_BASE=$(git merge-base HEAD origin/main)
SYNC_COMMIT=$(git log --format="%H %s" "$MERGE_BASE"..HEAD | grep "\[auto-sync\] update dependencies" | awk '{print $1}')
git rebase --onto origin/main "$SYNC_COMMIT"
```

**Why message-based over positional:**
- Robust against extra commits between merge-base and feature commits
- Works even if someone manually commits on the branch before branching off
- Self-documenting — the grep pattern makes intent clear

**Convention:** Use bracketed prefixes in commit messages (e.g., `[auto-sync]`, `[deploy]`) to make them greppable without false positives.

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

**Gotcha — stale worktrees:** Agents leave worktrees in `claude/worktrees/` that `git clean` skips. Clean up with `git worktree list` + `git worktree remove --force`. These accumulate and hold refs to old branch HEADs.

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

## Check Untracked Dependencies Before Committing

When committing new modules, check `git status` untracked files for dependencies the new code imports. A file created in a prior session but never committed will break CI if a newly committed module imports it. Stage all untracked dependencies together with the new code.

## Split Mixed-Concern Branch via Soft Reset

When a branch has commits mixing two concerns (e.g., docs + implementation plans), split them without cherry-pick surgery:

1. Create new branch from base, `git checkout <source> -- <paths>` to grab the subset, commit
2. On original branch: `git reset --soft <base>` to collapse all commits into staged changes
3. `git reset HEAD -- <unwanted-paths>` to unstage the files that moved to the new branch
4. Commit the remaining staged files — clean single commit with only the wanted content
5. Clean up untracked files, force-push-with-lease

**Why soft-reset over interactive rebase:** When the concern boundary doesn't align with commit boundaries (e.g., first commit has files from both concerns), `reset --soft` + selective unstage is simpler than splitting commits during rebase.

## Verify Remote/Project Identity Before Cross-Repo Work

When working across repos with similar names (e.g., `foo-service` vs `foo-service-v2`), verify `git remote -v` and the project path match before committing or pushing. A wrong-repo push wastes a commit cycle and may create orphan branches/PRs on the wrong project.

**Quick check:** `git remote -v | head -1` before any push to a repo you didn't clone yourself in this session.

## Programmatic JSON Merge for Rebase Conflicts

When rebasing a branch that reformats a large JSON file (e.g., Postman collection re-exported with different indentation), git can't match lines and produces whole-file conflicts on every commit. Manual resolution is impractical for 3000+ line files.

**Strategy:** Parse both versions as JSON, take the incoming commit's version as base, then programmatically graft HEAD's additions:

```python
import json, subprocess

def get_json(ref):
    r = subprocess.run(['git', 'show', f'{ref}:path/to/file.json'], capture_output=True, text=True)
    return json.loads(r.stdout)

stopped = open('.git/rebase-merge/stopped-sha').read().strip()
child = get_json(stopped)   # incoming commit's version
head = get_json('HEAD')      # our version with additions

# Programmatically find and transplant additions from HEAD into child
# ... (domain-specific logic)

with open('path/to/file.json', 'w') as f:
    json.dump(child, f, indent='\t')
```

**Key insight:** When the same file conflicts on multiple rebase steps, extract the merge logic into a reusable function. Each step: take commit's version → apply HEAD additions → validate JSON → stage → continue.

## Zsh Glob Expansion Breaks `git add` with Brackets

Zsh interprets `[brackets]` as glob patterns. `git add app/api/accounts/[address]/route.ts` fails with "no matches found." This hits constantly in Next.js projects with dynamic route dirs like `[address]`, `[id]`, etc.

**Workarounds:** `git add -A` (if all changes are wanted), `git add -- 'app/api/accounts/\[address\]/**'` (escaped), or `noglob git add <path>`.

## Stash Pop Conflict Scenarios

`git stash pop` applies the stash as a patch against the current HEAD and conflicts when the stash was created against different content.

**Cross-branch:** Stash on branch A, pop on diverged branch B — files modified in the divergent commits conflict even if the stash didn't touch them. For delete/modify conflicts: `git rm <file>`. For text: keep the stash's changes.

**Post-rebase:** Stash dirty files to unblock rebase, pop after completion — conflicts if rebase modified those files. Resolution: keep the rebased version (post-rebase is authoritative), drop the stash.

## Stacked PR Dependency Risks

Stacked PRs compound risk: parallel work can make dependent PRs redundant before the chain resolves. When a branch carries its dependency's changes, it becomes stale if the dependency merges with a different implementation. Keep stacked branches minimal — don't carry parent changes forward; let branch ancestry provide them.

## GitHub API Pagination Hides Newest Comments

The GitHub PR comments endpoint defaults to `per_page=30` ascending — when a PR has 30+ comments, newer ones silently fall off the first page. Incremental polling that doesn't account for this misses new reviewer comments entirely.

**Fix:** Use `direction=desc` for incremental fetches (newest first, always visible within default page size). Use `--paginate` for full fetches (auto-fetches all pages). Same applies to the issues comments endpoint.

## Symlinked Dirs Revert Edits on Branch Switch

When `~/.claude/learnings/` is a symlink to a git-tracked directory (e.g., `dotfiles/.claude/learnings/`), switching branches in that repo reverts all files to the branch's state — including files you edited via the symlink path. Uncommitted edits made through the symlink are silently lost. This also affects worktree creation: `git worktree add` from a branch with uncommitted changes doesn't carry those changes to the worktree.

**Fix:** Commit or stash edits to symlinked paths before any branch operation in the underlying repo. Verify file contents after branch switches.

## Use `git mv` for File Renames to Preserve History

Use `git mv` rather than manual delete-and-create to preserve file history through renames. This matters for files that evolve over time (skills, configs, learnings). When applying a naming convention retroactively, batch all renames into a single atomic PR to avoid a transitional period.

## Verify Staged Files Before `git commit --amend`

Pre-commit hooks can stage additional files beyond what you explicitly `git add`. When amending, `--amend` picks up everything in the index — including hook-staged files — and folds them into the amended commit with no warning. This can silently bundle unrelated changes into the wrong commit.

**Fix:** Run `git diff --cached --stat` after `git add` and before `git commit --amend` to confirm only intended files are staged.

## Rebase: `--ours` and `--theirs` Are Inverted vs Merge

During `git rebase`, `--ours` refers to the **base branch** (the branch you're rebasing onto) and `--theirs` refers to the **commit being replayed** (your branch's commit). This is the opposite of merge semantics where `--ours` is your current branch. Always verify with a content check (e.g., `grep` for a known string) after `git checkout --ours/--theirs` during rebase conflict resolution.

## Dirty Working Tree Blocks `git rebase --continue`

Unstaged changes to tracked files can block `git rebase --continue` even when all merge conflicts are resolved and staged. The rebase machinery requires a clean working tree. **Fix:** `git stash` dirty files before `--continue`, then `git stash pop` after.

## Renamed Files in Rebase Show Cross-History Conflicts

When the target branch renamed a file (e.g., `skill-design.md` → `claude-authoring/skills.md`), rebase conflicts appear under the new filename but contain content referencing the old. To resolve efficiently: check what content already exists on the target branch under both old and new filenames (and any split-out files like `claude-authoring/personas.md`), then keep only genuinely new content from your commit.

## GitHub Reviews Endpoint Has No `since` Filter

The `gh pr view --json reviews` endpoint returns all reviews every time — it doesn't support `since` or `updated_after` filtering. To detect new review submissions on incremental fetches, track `LAST_REVIEW_COUNT` and compare against the current count. Only process reviews beyond the previous count. This is distinct from inline comments and issue comments, which support timestamp-based filtering.

## Cascade Rebase for Stacked Branches

- `checkout -B` resets local to remote, then rebase on updated base; `--force-with-lease` for safe push
- After rebasing stacked branches, retarget: `glab mr update <N> --target-branch <new-base>` (GitLab) / `gh pr edit <N> --base <new-base>` (GitHub)
- `checkout -B` is safer than `checkout` for stacked workflows — avoids stale local state

## Merge vs Rebase: Token-Cost Heuristic

Conflict resolution rounds drive token cost — each round requires reading markers, asking the user, applying, and staging. Merge always costs `N` rounds (N = conflicted files). Rebase can cost more because it replays each commit: if multiple commits touch the same conflicted file, that file re-conflicts per commit. Estimate: `rebase_rounds` = sum of (commits touching each conflicted file); `merge_rounds` = count of conflicted files. Pick merge when `rebase_rounds > merge_rounds × 1.5` (rebase's cleaner history is worth a small premium, but not 2×). Also pick merge unconditionally when the branch has merge commits — rebasing merge commits requires `--rebase-merges` and produces confusing conflict contexts.

## Worktree Branches Diverge from Main

When a worktree branch lives long enough for other sessions to land commits on main, `git diff main` shows phantom "deletions" — files added to main after the branch point that the branch doesn't have. This doesn't affect PR creation (GitHub computes the diff correctly against the merge base), but a naive local merge without rebase would revert those additions. Rebase onto main before merging, not before PR creation.

**PR description implication:** Before claiming a PR adds or removes a file, verify with `git log <base>..<branch> -- <file>`. A file appearing as "deleted" in `git diff main` may simply be a file that was added to main after the branch was cut — the branch never touched it. `git log` won't show it if the branch didn't commit it.

## `git add` with Embedded Git Repos

When `git add`-ing a directory that contains git worktrees (or any nested `.git` repos), git warns about "embedded git repositories" and stages them as gitlinks. Fix: `git rm --cached -rf <path>` to unstage, then add proper `.gitignore` patterns before re-adding. Always check for worktree directories before bulk-staging renamed/moved directories.

## Cross-Refs

- `~/.claude/learnings/bash-patterns.md` — shell escaping gotchas for git commands
- `~/.claude/learnings/cicd/gotchas.md` — CI pipeline git workflow patterns
