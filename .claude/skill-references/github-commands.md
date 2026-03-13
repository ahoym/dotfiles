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
# Full fetch
gh api "repos/{owner}/{repo}/pulls/<number>/comments?per_page=100" \
  --jq '.[] | {id, path, line, body, user: .user.login, created_at}'

# Incremental fetch (newest first so new comments aren't hidden by pagination)
gh api "repos/{owner}/{repo}/pulls/<number>/comments?since=<TS>&direction=desc" \
  --jq '.[] | {id, path, line, body, user: .user.login, created_at}'
```

## Fetch General Review Comments

```bash
gh pr view <number> --json reviews \
  --jq '.reviews[] | select(.body | length > 0) | {author: .author.login, state: .state, body}'
```

## Fetch Issue/Top-Level Comments

```bash
# Full fetch
gh api "repos/{owner}/{repo}/issues/<number>/comments?per_page=100" \
  --jq '.[] | {id, body, user: .user.login, created_at}'

# Incremental fetch (newest first)
gh api "repos/{owner}/{repo}/issues/<number>/comments?since=<TS>&direction=desc" \
  --jq '.[] | {id, body, user: .user.login, created_at}'
```

## Reply to Inline Comment

Write the message body to `.gh-replies/<comment_id>.md` first (avoids permission prompts from inline HEREDOC content), then pass via `-F body=@`:

```bash
mkdir -p .gh-replies
# Write body to .gh-replies/<comment_id>.md, then:
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -F body=@.gh-replies/<comment_id>.md -F in_reply_to=<comment_id>
```

## Edit Inline Comment

Update an existing pull request review comment:

```bash
# Write updated body to .gh-reply.tmp, then:
gh api repos/{owner}/{repo}/pulls/comments/<comment_id> -X PATCH \
  -F body=@.gh-reply.tmp
```

Note: The endpoint is `pulls/comments/<comment_id>` (no PR number), not `pulls/<number>/comments/<comment_id>`.

## Post Top-Level Comment

Write the message body to `.gh-replies/<pr_number>-top.md` first, then pass via file reference:

```bash
mkdir -p .gh-replies
# Write body to .gh-replies/<pr_number>-top.md, then:
gh pr comment <number> --body-file .gh-replies/<pr_number>-top.md
```

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
gh api "repos/{owner}/{repo}/pulls?state=all&sort=created&direction=asc&per_page=<SIZE>&page=<PAGE>" \
  | jq -c '.[] | {number, title, state, comments, user: .user.login, head_branch: .head.ref, requested_reviewers: [.requested_reviewers[].login], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], body: (.body // "(none)")[:400]}'
```

## Verify Platform Access (Batch)

```bash
gh api "repos/{owner}/{repo}/pulls?state=all&per_page=1" | jq length
```

## Count Total Reviews

```bash
gh api "repos/{owner}/{repo}/pulls?state=all&per_page=1" -i 2>&1 | grep -i 'link:'
```
