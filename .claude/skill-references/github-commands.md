---
description: "Internal reference — GitHub-specific command templates. Read by git skills after platform detection."
---

# GitHub Commands

**Important:** Never use `!=` in jq expressions passed via `gh --jq` — the `!` gets shell-escaped. Use positive equivalents like `select(.body | length > 0)`.

## Fetch Review Details

```bash
gh pr view <number> --json number,title,headRefName,baseRefName
```

## Fetch Inline/Review Comments

```bash
# Full fetch (--paginate to get all comments beyond default 30-per-page limit)
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate --jq '.[] | {id, path, line, body, user: .user.login, created_at}'

# Incremental fetch (--paginate + client-side filter to avoid query params that require quoting)
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate --jq '.[] | select(.created_at > "<TS>") | {id, path, line, body, user: .user.login, created_at}'
```

## Fetch General Review Comments

```bash
gh pr view <number> --json reviews --jq '.reviews[] | select(.body | length > 0) | {author: .author.login, state: .state, body}'
```

**Note:** This endpoint does not support `since` filtering. On incremental fetches, always re-fetch and compare the review count against `LAST_REVIEW_COUNT` to detect new review submissions.

## Fetch Issue/Top-Level Comments

```bash
# Full fetch (--paginate to get all comments beyond default 30-per-page limit)
gh api repos/{owner}/{repo}/issues/<number>/comments --paginate --jq '.[] | {id, body, user: .user.login, created_at}'

# Incremental fetch (--paginate + client-side filter to avoid query params that require quoting)
gh api repos/{owner}/{repo}/issues/<number>/comments --paginate --jq '.[] | select(.created_at > "<TS>") | {id, body, user: .user.login, created_at}'
```

## Reply to Inline Comment

Write the message body to `change-request-replies/<comment_id>.md` first (avoids permission prompts from inline HEREDOC content), then pass via `-F body=@`:

```bash
mkdir -p change-request-replies
# Write body to change-request-replies/<comment_id>.md, then:
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -F body=@change-request-replies/<comment_id>.md -F in_reply_to=<comment_id>
```

## Edit Inline Comment

Update an existing pull request review comment:

```bash
# Write updated body to .gh-reply.tmp, then:
gh api repos/{owner}/{repo}/pulls/comments/<comment_id> -X PATCH \
  -F body=@.gh-reply.tmp
```

Note: The endpoint is `pulls/comments/<comment_id>` (no PR number), not `pulls/<number>/comments/<comment_id>`.

## React to Comment

Add an emoji reaction to an inline comment or issue comment. Use for positive signals/general feedback instead of a text reply.

```bash
# React to inline/review comment (available: +1, -1, laugh, confused, heart, hooray, rocket, eyes)
# Use -f (lowercase) not -F — -F infers type and treats +1/-1 as numeric, which the API rejects
gh api repos/{owner}/{repo}/pulls/comments/<comment_id>/reactions -f content=<emoji>

# React to issue/top-level comment
gh api repos/{owner}/{repo}/issues/comments/<comment_id>/reactions -f content=<emoji>
```

## Post Top-Level Comment

Write the message body to `change-request-replies/<pr_number>-top.md` first, then pass via file reference:

```bash
mkdir -p change-request-replies
# Write body to change-request-replies/<pr_number>-top.md, then:
gh pr comment <number> --body-file change-request-replies/<pr_number>-top.md
```

## Create or Update PR (Body via File)

Write the PR body to `change-request-replies/pr-body.md` first to avoid HEREDOC/quoted string permission prompts:

```bash
mkdir -p change-request-replies
# Write body via Write tool to change-request-replies/pr-body.md, then:
gh pr create --base <base-branch> --title "<title>" --body-file change-request-replies/pr-body.md
# Or update existing:
gh pr edit <number> --body-file change-request-replies/pr-body.md
# Clean up:
rm -rf change-request-replies
```

## Post Review with Inline Comments

Write the review payload to `change-request-replies/review-<number>.json` via the Write tool, then post:

```bash
mkdir -p change-request-replies
# Write JSON payload to change-request-replies/review-<number>.json, then:
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --input change-request-replies/review-<number>.json
# Clean up:
rm change-request-replies/review-<number>.json && rmdir change-request-replies 2>/dev/null
```

**Payload format** (`change-request-replies/review-<number>.json`):
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

## Checkout Review Branch

```bash
gh pr checkout <number>
git pull origin <headRefName>
```

## Fetch Files Changed

```bash
gh pr view <number> --json files --jq '.files[].path'
```

## Fetch Commits

```bash
gh pr view <number> --json commits \
  --jq '.commits[] | {sha: .oid[0:7], message: .messageHeadline}'
```

## Fetch Diff

```bash
gh pr diff <number>
```

## Check for Existing Review

```bash
gh pr list --head <branch-name>
```

## Find Approved Reviewers

```bash
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --jq '[.[] | select(.state == "APPROVED") | .user.login] | unique | .[]'
```

## Fetch Review Metadata (Batch)

For batch operations like learnings extraction:

```bash
gh api 'repos/{owner}/{repo}/pulls?state=all&sort=created&direction=asc&per_page=<SIZE>&page=<PAGE>' \
  | jq -c '.[] | {number, title, state, comments, user: .user.login, head_branch: .head.ref, requested_reviewers: [.requested_reviewers[].login], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], body: (.body // "(none)")[:400]}'
```

## Verify Platform Access (Batch)

```bash
gh api 'repos/{owner}/{repo}/pulls?state=all&per_page=1' | jq length
```

## Count Total Reviews

```bash
gh api 'repos/{owner}/{repo}/pulls?state=all&per_page=1' -i 2>&1 | grep -i 'link:'
```
