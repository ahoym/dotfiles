---
description: "Internal reference — GitLab-specific command templates using skill variables. Read by git skills after platform detection."
---

# GitLab Commands

Commands use variables set by each skill's platform detection step (e.g., `$VIEW_CMD`, `$API_CMD`).
Substitute your skill's variables before executing.

**Important:** Never use `!=` in jq expressions passed via `glab --jq` — the `!` gets shell-escaped. Use positive equivalents like `select(.body | length > 0)`.

## Fetch Review Details

```bash
$VIEW_CMD <number> --output json
```

## Fetch Inline/Review Comments

```bash
# Full fetch
$API_CMD projects/:id/merge_requests/<number>/notes \
  | jq '.[] | {id, body, author: .author.username, created_at, position}'

# Incremental fetch
$API_CMD "projects/:id/merge_requests/<number>/notes?updated_after=<TS>" \
  | jq '.[] | {id, body, author: .author.username, created_at, position}'
```

## Fetch General Review Comments

```bash
# Use discussions endpoint for threaded comments
$API_CMD projects/:id/merge_requests/<number>/discussions \
  | jq '.[] | {id, notes: [.notes[] | {id, body, author: .author.username, position}]}'
```

## Fetch Issue/Top-Level Comments

```bash
# Notes without position data are top-level comments
$API_CMD projects/:id/merge_requests/<number>/notes \
  | jq '[.[] | select(.position == null)] | .[] | {id, body, author: .author.username, created_at}'
```

## Reply to Inline Comment

Write the message body to `.gh-reply.tmp` first (avoids permission prompts from inline HEREDOC content), then pass via `-F body=@`:

```bash
# Write body to .gh-reply.tmp, then:
$API_CMD projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -F body=@.gh-reply.tmp
```

## Post Top-Level Comment

Write the message body to `.gh-reply.tmp` first, then pass via file reference:

```bash
# Write body to .gh-reply.tmp, then:
$COMMENT_CMD <number> --message "$(cat .gh-reply.tmp)"
```

## Checkout Review Branch

```bash
$CHECKOUT_CMD <number>
git pull origin <source_branch>
```

## Fetch Files Changed

```bash
$DIFF_CMD <number> --name-only
```

## Fetch Commits

```bash
$API_CMD projects/:id/merge_requests/<number>/commits \
  --jq '.[] | {sha: .short_id, message: .title}'
```

## Fetch Diff

```bash
$DIFF_CMD <number>
```

## Check for Existing Review

```bash
$LIST_CMD <branch-name>
```

## Find Approved Reviewers

```bash
$API_CMD "projects/:id/merge_requests/<number>/notes?sort=desc&per_page=100" \
  | jq -r '[.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]'
```

## Fetch Review Metadata (Batch)

For batch operations like learnings extraction:

```bash
$API_CMD "projects/:id/merge_requests?state=all&sort=asc&order_by=created_at&per_page=<SIZE>&page=<PAGE>" \
  | jq -c '.[] | {iid, title, state, user_notes_count, author: .author.username, source_branch, reviewers: [.reviewers[].username], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], description: (.description // "(none)")[:400]}'
```

## Verify Platform Access (Batch)

```bash
$API_CMD "projects/:id/merge_requests?state=all&per_page=1" | jq length
```

## Count Total Reviews

```bash
$API_CMD "projects/:id/merge_requests?state=all&per_page=1" --include 2>&1 | grep -i x-total
```
