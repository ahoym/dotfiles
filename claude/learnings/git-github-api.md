GitHub-specific API patterns — PR management, stacked PRs, pagination gotchas, reviews endpoint, batch operations, and bulk extraction via gh CLI.
- **Keywords:** GitHub API, gh CLI, pagination, stacked PR, PR comments, reviews endpoint, per_page, direction, cascade rebase, retarget, force-push-with-lease, inline comment reply, in_reply_to, review payload, batch metadata, sweeper detection, issue operations, body-file, issue split, blocker dependency update, issue close, issue triage, auto-close keywords, Closes Fixes Resolves, not planned reason
- **Related:** ~/.claude/learnings/git-patterns.md, ~/.claude/learnings/cicd/gitlab.md

---

## `gh api -f` vs `-F` for File-Read Body

- `gh api --method POST ... -f body=@path` — lowercase `-f` sends the literal string `"@path"` as the JSON value (broken, silent).
- `gh api --method POST ... -F body=@path` — uppercase `-F` reads the file content and sends it as the value (correct).

This is easy to miss because other CLIs use `-f` for file-read. When posting reply bodies from a file (standard pattern for long comments), always verify the flag is capital. Symptom: a posted comment whose body is literally `@./reply.md`.

## GitHub Inline Review Comments Must Target Diff-Hunk Lines

The `POST /pulls/{n}/comments` `line` parameter must reference a line that appears in one of the PR's diff hunks (or within 3 lines of a hunk — the "context" range). Targeting a pre-existing, unmodified line returns 422 Unprocessable Entity.

- Brand-new files: every line is valid.
- Modified files: only lines within diff hunks (and their context) are valid.
- For summary-only findings on unchanged code: post a top-level PR comment, not an inline comment.

When an orchestrator computes line numbers from a structured review payload, validate each line against the hunk ranges before posting. 422 errors block the entire review batch on some API paths.

## Branch Names with `/` Need URL-Encoding in Contents API

`gh api repos/{owner}/{repo}/contents/{path}?ref=sweep/97-foo` fails: the `/` in `sweep/97-foo` is interpreted as a path separator in the URL. Encode as `sweep%2F97-foo`. `gh pr diff` and `gh pr view` handle this automatically — the asymmetry catches orchestrators that mix `gh pr` commands with raw `gh api` contents calls.

## Multi-Hunk Line Number Tracking

When posting inline comments on a file with 4+ hunks, compute new-file line numbers by tracking cumulative net-line delta per hunk. Hunk-by-hunk: `new_line = old_line + sum(+added − -removed for each preceding hunk)`. Don't assume the hunk header's `@@ -N,M +P,Q @@` is absolute — it's the *starting* position after prior hunks have already been applied.

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

## `gh api --paginate --jq '.[]'` Returns NDJSON, Not a JSON Array

`gh api --paginate --jq '.[] | {…}'` outputs one JSON object per line (NDJSON) — pages are concatenated, not merged into a single array. Downstream `jq length` or `jq '.[]'` will fail or produce per-object output. To consume as an array, slurp with `jq -s`:

```bash
gh api repos/{owner}/{repo}/pulls/<n>/comments --paginate --jq '.[] | {id, body}' \
  | jq -s 'length'   # array length, not 22 separate "1"s
```

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

## Inline Comment Reply Endpoint Requires Pull Number

GitHub's REST endpoint for replying to an inline review comment is `POST /repos/{owner}/{repo}/pulls/{pull_number}/comments/{comment_id}/replies`. The shorter `/repos/{owner}/{repo}/pulls/comments/{comment_id}/replies` (without `{pull_number}`) returns 404. The pull number is redundant given the comment ID uniquely identifies the thread, but the API requires it anyway.

```bash
# Correct
gh api repos/owner/repo/pulls/123/comments/456789/replies -X POST -f body="..."

# 404
gh api repos/owner/repo/pulls/comments/456789/replies -X POST -f body="..."
```

## Cross-Refs

- `~/.claude/learnings/git-patterns.md` — core git operations, rebase, merge, worktree, commit hygiene
- `~/.claude/learnings/cicd/gitlab.md` — GitLab CI/CD patterns and configuration

## `gh pr view <N>` fails when N is an issue number

Issues and PRs share a number space, so `gh pr view 98` returns `GraphQL: Could not resolve to a PullRequest with the number of 98` if 98 is an *issue*. Use `gh issue view <N>` for issues and `gh pr view <N>` for PRs — guess wrong and the error doesn't tell you which it is.

To check whether a dependency tracked by an issue # has shipped, look at the issue's `closedAt` and `state`. The merge commit references the issue (`Fixes #98`) but uses the PR's own number in the title.

## Splitting an existing tracked issue: edit-in-place + file-new

When breaking a single issue into two (e.g., B2 → B2a + B2b), prefer **edit-in-place + file-new** over close-and-file-two:

1. `gh issue view N --json body --jq .body > body.md` → Edit → `gh issue edit N --body-file body.md --title "<new>"` (narrowed scope)
2. `gh issue create --title "<other half>" --label X --milestone Y --body-file other.md` (new issue)
3. **Walk downstream blockers** — any ticket whose body says `Blocked by: #N` may now block on only one half. Update those bodies too (e.g., a deploy-config ticket should block on the wiring half, not the inert library half).

Why: preserves the original issue's comment history, label, milestone, and any external references (#N in PRs, commits, other issues). Closing and re-filing two breaks all of that.

Body-edit pattern: `gh issue view N --json body --jq .body` returns the raw body (no metadata wrapper), letting you round-trip through a file with Read/Edit tools instead of inline `sed`.

## Closing an issue with a comment: two calls, not one

`gh issue close` has no `--body-file` flag, and `--comment "<text with spaces>"` parses each space-separated token as a positional arg (`accepts 1 arg(s), received N`). Two-call pattern:

```bash
gh issue comment N --body-file path/to/comment.md
gh issue close N --reason completed       # or: --reason "not planned"
```

`--reason` accepts `completed` or `not planned` — use the latter for issues superseded by a different approach (preserves the distinction in GitHub's UI: green check vs grey X).

## PR title `(#N)` does NOT auto-close issue N

Only `Closes #N` / `Fixes #N` / `Resolves #N` keywords (case-insensitive) inside the **PR body** trigger GitHub's auto-close on merge. A trailing `(#N)` in the PR title is just a number reference — no link, no auto-close. Common cause of stale-open issues whose work has fully shipped: the PR-creation skill embedded the issue number in the title but not as a closing keyword in the body.

When triaging, cross-reference each open issue's acceptance criteria against codebase symbols (grep for files/functions named in the issue) and against merged-PR titles — title `(#N)` is a strong signal but not a state change.

## PR review inline comments: `line: null` with populated `position` is normal

When posting via `gh api ... pulls/N/reviews` with the `line` field, the API response often shows `"line": null, "original_line": null` but populated `"position": <int>, "original_position": <int>`. The comment IS positioned correctly at the right file line — `position` is the legacy diff-line-position field GitHub still uses for some inline comments. Verify by visiting `html_url` rather than panicking and re-posting (which creates duplicates).

```bash
gh api repos/.../pulls/comments/<id> --jq '{path, line, position, html_url}'
# {"path":"foo.py","line":null,"position":14,"html_url":"...#discussion_r..."}
# Render the html_url — it will land at the correct file line.
```

## Read PR files via `contents?ref=<branch>` when CWD is on a different branch

When CWD is on branch X but reviewing a PR on branch Y, local `Read(file)` calls return X's version — likely the BASE content, not the PR's. Two safe options:

1. Fetch via the API: `gh api repos/{owner}/{repo}/contents/{path}?ref={branch} --jq .content | base64 -d` (URL-encode `/` in branch names as `%2F`).
2. Reconstruct line numbers from diff hunks — count `+` and ` ` (context) lines from the `@@ -a,b +c,d @@` header; skip `-` lines.

## Reaction endpoint shape: `pulls/comments/{id}/reactions` (no PR number)

PR review-comment reactions live at `repos/{owner}/{repo}/pulls/comments/{id}/reactions` — no `/pulls/{N}` segment. The intuitive `repos/{owner}/{repo}/pulls/{N}/comments/{id}/reactions` form returns 404. Same shape applies to issue comments: `repos/{owner}/{repo}/issues/comments/{id}/reactions`.

## `gh api -F` vs `-f` for file expansion

`-f body=@file.txt` sends the literal string `@file.txt`. Use `-F body=@file.txt` for file expansion (`-F` does type inference + `@` resolution; `-f` is string-only). Easy miss when copying between `gh` and `curl` patterns.

## Reviews require full 40-char SHA in `commit_id`

`gh api repos/.../pulls/N/reviews -F commit_id=abc1234` returns 422 — short SHAs are rejected. Always pass the full OID. Same for `pulls/N/comments` when creating inline review comments tied to a specific commit.

## Inline comments on lines outside the target commit's diff post with `line: null`

Posting an inline comment with `line=42, commit_id=<sha>` succeeds even if line 42 isn't in `<sha>`'s diff — but the comment is created with `line: null` (silently unanchored). Visible in `gh api .../comments/<id>` as `"line": null, "position": <N>, "html_url": "...#discussion_r..."`. Anchor renders by `html_url`, but watermark/diff-tooling that depends on `line` breaks. Cause for re-review subagents: they use new-file line numbers from the cumulative diff, but the runtime POST happens against the latest commit's diff which may not include those lines.

Do NOT trust local file line numbers when CWD ≠ PR branch. Subagents that read local files in this state will compute wrong line numbers and post inline comments at the wrong position. Symptom to watch for: comments landing on adjacent functions or stale code that's no longer in the PR.

## Stacked PRs unanchor inline comments regardless of position strategy

When a PR's base is a non-main branch (e.g., the head of an upstream PR in a stack), `POST /pulls/{N}/reviews` returns `line: null` on every inline comment in the payload — even when `line + side` are valid for the latest commit's diff and even when using `position` instead. The comments attach to the review thread (visible in the PR conversation tab) but never anchor to specific diff lines. Affects any review tooling that depends on `line` for diff-positioning. Workaround: post stacked-PR review findings as bullet points in the review body rather than inline.

## `gh api -f body=@file` posts literal `@file`; use `-F body=@<absolute-path>`

`-f` (lowercase) treats `@path` as a 7-character literal string and posts it as-is. `-F` (uppercase) reads the file and sends its content. The fix is one character — `-f` → `-F`. Do NOT reach for the `jq -n --arg body "$(cat file)" | gh api ... --input -` "workaround"; the `$(cat ...)` subshell defeats the `Bash(jq *)` allowlist and you'll cascade into permission denials. For top-level comments, `gh pr comment --body-file <absolute-path>` handles file expansion natively.

Canonical script: `~/.claude/skill-references/github/commands/reply-to-inline-comment.sh` — copy verbatim, substitute placeholders only.

## `pulls/N/comments` `commit_id` mutates with new pushes; `created_at` is the cycle discriminator

The `commit_id` field on inline review comments updates as new commits push — a comment posted at SHA `4a604cf3` shows `commit_id = 6d00e2ba` (current HEAD) on subsequent fetches. Use `created_at` (immutable) to discriminate which review cycle a comment belongs to. Filtering by `commit_id` for "comments from cycle N" silently rolls everything forward to the latest SHA.

## `pulls/N/reviews` returns inline-only submissions with `body: ""`

Posting inline comments via `pulls/N/reviews` creates a review record with empty body. When scanning for the most recent Team-Reviewer review summary (e.g., to fetch context for re-review), filter `body != ""` AND check the role footnote — otherwise the most recent non-empty review is masked by intervening empty inline-only review submissions.

## `?` is a zsh glob — `gh api .../comments?per_page=100` fails

zsh refuses the unquoted `?` with `no matches found: repos/.../comments?per_page=100`. Use `gh api -X GET <path> -F per_page=100` instead — gh appends `?per_page=100` server-side without exposing the `?` to the shell. Quoting the URL works too, but quoted strings can break `Bash(gh api *)` allowlist matching, so prefer `-F`.

## `gh api ... --paginate > file.json` can produce 0 bytes

Empirically observed: `gh api repos/.../comments --paginate > file.json` writes an empty file even when the endpoint has data, while the same command piped to stdout works. Root cause unclear (CLI buffering quirk on stdout-redirect?). Workaround: drop `--paginate` and use `-X GET <path> -F per_page=100` for one-shot fetches — covers most PR-comment workloads at typical scales.

## GitHub native sub-issues: GraphQL `addSubIssue`, requires node IDs

GitHub's "Sub-issues" feature creates a structured parent/child relationship distinct from a markdown checklist — renders as a Sub-issues panel with progress bar on the parent and a "Parent" backlink on the sub. `gh issue create` has no `--parent` flag; use the GraphQL mutation, which takes **node IDs** (not issue numbers).

```bash
PARENT_ID=$(gh api repos/{owner}/{repo}/issues/<PARENT_N> --jq '.node_id')
SUB_ID=$(gh api repos/{owner}/{repo}/issues/<SUB_N> --jq '.node_id')
gh api graphql -F parent="$PARENT_ID" -F sub="$SUB_ID" \
  -f query='mutation($parent: ID!, $sub: ID!) { addSubIssue(input: {issueId: $parent, subIssueId: $sub}) { subIssue { number } } }'
```

`removeSubIssue` is the symmetric mutation for unlinking. Canonical scripts: `~/.claude/skill-references/github/commands/{link,unlink}-sub-issue.sh`.

## `gh milestone create` doesn't exist — use REST API

No native `gh milestone` subcommand. Create via REST, then reference by title in `gh issue create --milestone <TITLE>`:

```bash
gh api repos/{owner}/{repo}/milestones --method POST \
  -f title=<TITLE> -f description=<DESC> --jq '{number, title, html_url}'
```

Canonical script: `~/.claude/skill-references/github/commands/create-milestone.sh`.

## Inline Review Comments Returning `line: null` Are Unanchored

`POST /pulls/{n}/reviews` accepts `comments[].line` but the value must match the **GitHub diff position** that the API can resolve — not just any line in or near a hunk. Lines computed from `@@ -old,count +new,start @@` hunk-header context (without verifying against the file's actual position in the rendered diff) often return `line: null` in the API response: the comment is stored, but renders as a review-level item not anchored to a specific line.

The 422 path covered above (line outside hunk + 3-line context) is the strict-error case. The `line: null` path is the silent-failure case — comments post successfully but lose the file/line anchoring that makes review feedback actionable.

**Reliable patterns:**
- `position` (1-indexed within the full diff output) — deprecated but anchors reliably for first-pass reviews on large diffs.
- `line` + `side: RIGHT` + verified file-line read (`Read(file, offset=line-3, limit=7)` after writing the payload, before posting).

Reviewer subagents working from a 100KB+ raw diff without checking the worktree are the typical caller — they infer line numbers from hunk math and skip verification. Either checkout the PR branch + verify each line, or fall back to `position`.

## Cross-Referencing Issue Updates: New-Issue-First, Then Sed-Replace

When updating multiple issues that reference each other (e.g., umbrella + sub-issues, where a new sub-issue gets inserted into the umbrella's body):

1. **File the new issue first** with `gh issue create --body-file ...`. Captures the assigned number from stdout (e.g., `#184`).
2. **Sed-replace placeholders** (`#<NEW>` → `#184`) across the staged body files for the cross-referencing issues:
   ```bash
   sed -i.bak 's/#<NEW>/#184/g' tmp/claude-artifacts/issue-edits/*.md && rm tmp/claude-artifacts/issue-edits/*.bak
   ```
3. **Push body edits in batch**: `gh issue edit <N> --body-file ...` per issue.

Stage all bodies in `tmp/claude-artifacts/issue-edits/` first; review before pushing. GitHub assigns issue numbers sequentially — there's no pre-allocation API, so the new-issue-first ordering is forced.
