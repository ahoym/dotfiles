---
description: "Internal reference — platform-specific git command templates using skill variables. Read by git skills after platform detection."
---

# Git Platform Commands

Commands use variables set by each skill's platform detection step (e.g., `$VIEW_CMD`, `$API_CMD`).
Substitute your skill's variables before executing.

**Important:** Never use `!=` in jq expressions passed via `gh --jq` or `glab --jq` — the `!` gets shell-escaped. Use positive equivalents like `select(.body | length > 0)`.

## Fetch Review Details

**GitHub:**
```bash
$VIEW_CMD <number> --json number,title,headRefName,baseRefName
```

**GitLab:**
```bash
$VIEW_CMD <number> --output json
```

## Fetch Inline/Review Comments

**GitHub:**
```bash
# Full fetch
$API_CMD repos/{owner}/{repo}/pulls/<number>/comments \
  --jq '.[] | {id, path, line, body, user: .user.login, created_at}'

# Incremental fetch (append ?since=<LAST_FETCH_TS>)
$API_CMD "repos/{owner}/{repo}/pulls/<number>/comments?since=<TS>" \
  --jq '.[] | {id, path, line, body, user: .user.login, created_at}'
```

**GitLab:**
```bash
# Full fetch
$API_CMD projects/:id/merge_requests/<number>/notes \
  | jq '.[] | {id, body, author: .author.username, created_at, position}'

# Incremental fetch
$API_CMD "projects/:id/merge_requests/<number>/notes?updated_after=<TS>" \
  | jq '.[] | {id, body, author: .author.username, created_at, position}'
```

## Fetch General Review Comments

**GitHub:**
```bash
$VIEW_CMD <number> --json reviews \
  --jq '.reviews[] | select(.body | length > 0) | {author: .author.login, state: .state, body}'
```

**GitLab:**
```bash
# Use discussions endpoint for threaded comments
$API_CMD projects/:id/merge_requests/<number>/discussions \
  | jq '.[] | {id, notes: [.notes[] | {id, body, author: .author.username, position}]}'
```

## Fetch Issue/Top-Level Comments

**GitHub:**
```bash
$API_CMD repos/{owner}/{repo}/issues/<number>/comments \
  --jq '.[] | {id, body, user: .user.login, created_at}'
```

**GitLab:**
```bash
# Notes without position data are top-level comments
$API_CMD projects/:id/merge_requests/<number>/notes \
  | jq '[.[] | select(.position == null)] | .[] | {id, body, author: .author.username, created_at}'
```

## Reply to Inline Comment

**GitHub:**
```bash
$API_CMD repos/{owner}/{repo}/pulls/<number>/comments \
  -f body="<message>" -F in_reply_to=<comment_id>
```

**GitLab:**
```bash
$API_CMD projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -f body="<message>"
```

## Post Top-Level Comment

**GitHub:**
```bash
$COMMENT_CMD <number> --body "<message>"
```

**GitLab:**
```bash
$COMMENT_CMD <number> --message "<message>"
```

## Checkout Review Branch

**GitHub:**
```bash
$CHECKOUT_CMD <number>
git pull origin <headRefName>
```

**GitLab:**
```bash
$CHECKOUT_CMD <number>
git pull origin <source_branch>
```

## Fetch Files Changed

**GitHub:**
```bash
$VIEW_CMD <number> --json files --jq '.files[].path'
```

**GitLab:**
```bash
$DIFF_CMD <number> --name-only
```

## Fetch Commits

**GitHub:**
```bash
$VIEW_CMD <number> --json commits \
  --jq '.commits[] | {sha: .oid[0:7], message: .messageHeadline}'
```

**GitLab:**
```bash
$API_CMD projects/:id/merge_requests/<number>/commits \
  --jq '.[] | {sha: .short_id, message: .title}'
```

## Fetch Diff

```bash
$DIFF_CMD <number>
```

## Check for Existing Review

**GitHub:**
```bash
$LIST_CMD <branch-name>
```

**GitLab:**
```bash
$LIST_CMD <branch-name>
```

## Find Approved Reviewers

**GitHub:**
```bash
$API_CMD repos/{owner}/{repo}/pulls/<number>/reviews \
  --jq '[.[] | select(.state == "APPROVED") | .user.login] | unique | .[]'
```

**GitLab:**
```bash
$API_CMD "projects/:id/merge_requests/<number>/notes?sort=desc&per_page=100" \
  | jq -r '[.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]'
```

## Fetch Review Metadata (Batch)

For batch operations like learnings extraction:

**GitHub:**
```bash
$API_CMD "repos/{owner}/{repo}/pulls?state=all&sort=created&direction=asc&per_page=<SIZE>&page=<PAGE>" \
  | jq -c '.[] | {number, title, state, comments, user: .user.login, head_branch: .head.ref, requested_reviewers: [.requested_reviewers[].login], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], body: (.body // "(none)")[:400]}'
```

**GitLab:**
```bash
$API_CMD "projects/:id/merge_requests?state=all&sort=asc&order_by=created_at&per_page=<SIZE>&page=<PAGE>" \
  | jq -c '.[] | {iid, title, state, user_notes_count, author: .author.username, source_branch, reviewers: [.reviewers[].username], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], description: (.description // "(none)")[:400]}'
```

## Verify Platform Access (Batch)

**GitHub:**
```bash
$API_CMD "repos/{owner}/{repo}/pulls?state=all&per_page=1" | jq length
```

**GitLab:**
```bash
$API_CMD "projects/:id/merge_requests?state=all&per_page=1" | jq length
```

## Count Total Reviews

**GitHub:**
```bash
$API_CMD "repos/{owner}/{repo}/pulls?state=all&per_page=1" -i 2>&1 | grep -i 'link:'
```

**GitLab:**
```bash
$API_CMD "projects/:id/merge_requests?state=all&per_page=1" --include 2>&1 | grep -i x-total
```
