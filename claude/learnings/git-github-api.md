GitHub-specific API patterns — PR management, stacked PRs, pagination gotchas, reviews endpoint, batch operations, and bulk extraction via gh CLI.
- **Keywords:** GitHub API, gh CLI, pagination, stacked PR, PR comments, reviews endpoint, per_page, direction, cascade rebase, retarget, force-push-with-lease, inline comment reply, in_reply_to, review payload, batch metadata, sweeper detection, issue operations, body-file
- **Related:** ~/.claude/learnings/git-patterns.md, ~/.claude/learnings/cicd/gitlab.md

---

## GitHub API Pagination Hides Newest Comments

The GitHub PR comments endpoint defaults to `per_page=30` ascending — when a PR has 30+ comments, newer ones silently fall off the first page. Incremental polling that doesn't account for this misses new reviewer comments entirely.

**Fix:** Use `direction=desc` for incremental fetches (newest first, always visible within default page size). Use `--paginate` for full fetches (auto-fetches all pages). Same applies to the issues comments endpoint.

## GitHub Reviews Endpoint Has No `since` Filter

The `gh pr view --json reviews` endpoint returns all reviews every time — it doesn't support `since` or `updated_after` filtering. To detect new review submissions on incremental fetches, track `LAST_REVIEW_COUNT` and compare against the current count. Only process reviews beyond the previous count. This is distinct from inline comments and issue comments, which support timestamp-based filtering.

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

## Fixing Misordered Stacked PR Branches

When stacked PR branches were created in the wrong order (dependent branches created before dependency commits), the fix is straightforward:

1. **Reset** the branch to the correct dependency: `git branch -f <broken-branch> <correct-base>`
2. **Worktree** to avoid disturbing the working tree: `git worktree add /tmp/fix-<name> <broken-branch>`
3. **Copy** the agent's own files from the working tree into the worktree
4. **Commit and force-push**: `git -C /tmp/fix-<name> add -A && git -C /tmp/fix-<name> commit && git -C /tmp/fix-<name> push --force`
5. **Clean up**: `git worktree remove /tmp/fix-<name>`

**Key principle:** Each branch should only contain its own agent's files. Don't bundle dependency files into the commit — let the branch ancestry provide them. CI will fail until upstream PRs merge, which is expected and documented in the PR description.

**Process in topological order** — fix dependency branches before dependent ones, since dependent branches use the fixed dependency as their base.

## Stacked PR Dependency Risks

Stacked PRs compound risk: parallel work can make dependent PRs redundant before the chain resolves. When a branch carries its dependency's changes, it becomes stale if the dependency merges with a different implementation. Keep stacked branches minimal — don't carry parent changes forward; let branch ancestry provide them.

## Cascade Rebase for Stacked Branches

- `checkout -B` resets local to remote, then rebase on updated base; `--force-with-lease` for safe push
- After rebasing stacked branches, retarget: `glab mr update <N> --target-branch <new-base>` (GitLab) / `gh pr edit <N> --base <new-base>` (GitHub)
- `checkout -B` is safer than `checkout` for stacked workflows — avoids stale local state

## PR Inline Comment Reply Endpoint

Reply to an inline review comment with `POST /repos/{owner}/{repo}/pulls/{number}/comments` using `-F in_reply_to=<comment_id>`. The endpoint `/repos/{owner}/{repo}/pulls/comments/{id}/replies` does **not** exist (returns 404).

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  -f body="reply text" \
  -F in_reply_to=<comment_id>
```

## GitHub Inline Comments Rejected on Restored/Context Lines

Lines restored from the base branch (removed then re-added) appear as unchanged context in the combined diff. The review API rejects inline comments on context lines. Document these findings in the review summary body instead.

## Stacked PR Targeting for Dependency Chains

When creating a PR that builds on an unmerged dependency's branch, use `gh pr create --base <dependency-branch>` so the PR targets that branch instead of main. Add a stacking note in the PR body: `> ⚠️ Stacked PR — targets \`<branch>\`. Merge that PR first, then rebase this one onto main.` The worktree must `git fetch origin <branch>` before creation since the dependency branch only exists on the remote. After the dependency merges, rebase and retarget with `gh pr edit <N> --base main`.

## glab api Flag Case: `-f` vs `-F`

Lowercase `-f` = string field (value passed literally). Uppercase `-F` = inferred type with `@file` reading (reads file contents as the value). For file-sourced payloads, `-F body=@path` reads the file; `-f body=@path` sends the literal string `@path`. The case distinction also applies to `gh api` and is a common source of bugs in `claude -p` sessions: when a command template contains a non-functional path placeholder (e.g., `/absolute/path/to/`), agents improvise the path fix but silently swap `-F` to `-f`, posting the file path as the comment body instead of the file contents. Command templates must use `<ANGLE_BRACKET>` placeholders that match the agent's substitution convention, and should include an inline comment reinforcing the `-F`/`-f` distinction.

## Delete+Re-Post Recovery for Malformed Inline Comments

When an inline review comment has a malformed body (e.g., posted as a file path instead of content), delete and re-post — editing preserves the reply thread but requires the same `-F body=@path` care. Recovery commands:

```bash
# Delete the broken comment
gh api repos/{owner}/{repo}/pulls/comments/<broken_id> -X DELETE

# Re-post as a reply to the original (preserves thread context)
gh api repos/{owner}/{repo}/pulls/<N>/comments -X POST \
  -F body=@<abs-path-to-body.md> -F in_reply_to=<original_comment_id>
```

Note: `pulls/comments/<id>` (no PR number) for delete/patch; `pulls/<N>/comments` for create.

## PR Review Payload Format

The GitHub reviews API accepts a JSON payload via `--input`. Write to file first to avoid HEREDOC permission prompts:

```json
{
  "event": "COMMENT",
  "body": "Review summary body here",
  "comments": [
    {
      "path": "relative/file/path.md",
      "line": 42,
      "side": "RIGHT",
      "body": "Inline comment body here"
    }
  ]
}
```

- `line`: line number in the final version of the file (RIGHT side of diff)
- `side`: always `"RIGHT"` for comments on the new version
- `event`: `"COMMENT"`, `"APPROVE"`, or `"REQUEST_CHANGES"`

## Approved Reviewers Extraction

Write jq filters to file to avoid quoted-string permission prompts, then use `jq -rf`:

```bash
# jq filter: [.[] | select(.state == "APPROVED") | .user.login] | unique | .[]
gh api repos/{owner}/{repo}/pulls/<number>/reviews | jq -rf tmp/claude-artifacts/jq-filters/jq-filter.jq
```

## Sweeper Comment Detection

When scanning issue comments for bot activity, check comment ordering:
- Sweeper comment exists with no subsequent non-Sweeper comment → awaiting reply
- Sweeper comment exists with a subsequent non-Sweeper comment → re-assess eligible

Look for `Role:.*Sweeper` in comment bodies. Use `--paginate` for full fetch; don't use `--jq` with complex filters.

## Batch PR Metadata Extraction

For bulk operations like learnings extraction, use jq filter files with field templates:

```
.[] | {number, title, state, comments, user: .user.login, head_branch: .head.ref, requested_reviewers: [.requested_reviewers[].login], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], body: (.body // "(none)")[:400]}
```

Count total PRs via the `Link:` header: `gh api 'repos/{owner}/{repo}/pulls?state=all&per_page=1' -i 2>&1 | grep -i 'link:'`

## `glab mr create/update` Lack `--description-file`

Unlike `gh pr create --body-file`, `glab mr create` and `glab mr update` have no description-file flag. Using `--description "$(cat <file>)"` triggers permission prompts. Use the API directly:

```bash
# Create
glab api projects/:id/merge_requests -X POST \
  -f source_branch=<BRANCH> -f target_branch=<base> -f title="<title>" \
  -F description=@<ABSOLUTE_PATH>/body.md

# Update
glab api projects/:id/merge_requests/<IID> -X PUT \
  -F description=@<ABSOLUTE_PATH>/body.md
```

`-F field=@<file>` reads the file contents as the field value — same pattern as `-F body=@<file>` for notes.

## APPROVE Rejected on Self-Owned PRs

`gh api repos/{owner}/{repo}/pulls/<N>/reviews --input <payload>` with `"event": "APPROVE"` returns HTTP 422 `"Can not approve your own pull request"` when the authenticated user owns the PR. Fall back to `"event": "COMMENT"` with an explicit "ready to merge" signal in the body. Detect ownership before posting to avoid the round-trip.

## Cross-Refs

- `~/.claude/learnings/git-patterns.md` — core git operations, rebase, merge, worktree, commit hygiene
- `~/.claude/learnings/cicd/gitlab.md` — GitLab CI/CD patterns and configuration
