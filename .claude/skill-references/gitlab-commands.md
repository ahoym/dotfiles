---
description: "Internal reference — GitLab-specific command templates. Read by git skills after platform detection."
---

# GitLab Commands

**Important:** Never use `!=` in jq expressions passed via `glab --jq` — the `!` gets shell-escaped. Use positive equivalents like `select(.body | length > 0)`.

## Fetch Review Details

```bash
glab mr view <number> --output json
```

## Fetch Inline/Review Comments

```bash
# Full fetch
glab api projects/:id/merge_requests/<number>/notes | jq '.[] | {id, body, author: .author.username, created_at, position}'

# Incremental fetch (filter client-side to avoid query params that require quoting)
glab api projects/:id/merge_requests/<number>/notes | jq '.[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at, position}'
```

## Fetch General Review Comments

```bash
# Use discussions endpoint for threaded comments
glab api projects/:id/merge_requests/<number>/discussions \
  | jq '.[] | {id, notes: [.notes[] | {id, body, author: .author.username, position}]}'
```

## Fetch Issue/Top-Level Comments

```bash
# Full fetch — notes without position data are top-level comments
glab api projects/:id/merge_requests/<number>/notes | jq '[.[] | select(.position == null)] | .[] | {id, body, author: .author.username, created_at}'

# Incremental fetch (filter client-side to avoid query params that require quoting)
glab api projects/:id/merge_requests/<number>/notes | jq '[.[] | select(.position == null)] | .[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at}'
```

## Reply to Inline Comment

Write the message body to `change-request-replies/<note_id>.md` first (avoids permission prompts from inline HEREDOC content), then pass via `-F body=@`:

```bash
mkdir -p change-request-replies
# Write body to change-request-replies/<note_id>.md, then:
glab api projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -F body=@change-request-replies/<note_id>.md
```

## Post Top-Level Comment

Write the message body to `change-request-replies/<mr_number>-top.md` first, then pass via file reference:

```bash
mkdir -p change-request-replies
# Write body to change-request-replies/<mr_number>-top.md, then:
glab mr comment <number> --message "$(cat change-request-replies/<mr_number>-top.md)"
```

## Create or Update MR (Body via File)

Write the MR body to `change-request-replies/request-body-<BRANCH_NAME>.md` first to avoid quoting issues:

```bash
mkdir -p change-request-replies
# Write body via Write tool to change-request-replies/request-body-<BRANCH_NAME>.md, then:
glab mr create --target-branch <base-branch> --title "<title>" --description "$(cat change-request-replies/request-body-<BRANCH_NAME>.md)"
# Or update existing:
glab mr update <number> --description "$(cat change-request-replies/request-body-<BRANCH_NAME>.md)"
# Clean up:
rm change-request-replies/request-body-<BRANCH_NAME>.md && rmdir change-request-replies 2>/dev/null
```

## Checkout Review Branch

```bash
glab mr checkout <number>
git pull origin <source_branch>
```

## Fetch Files Changed

```bash
glab mr diff <number> --name-only
```

## Fetch Commits

```bash
glab api projects/:id/merge_requests/<number>/commits \
  --jq '.[] | {sha: .short_id, message: .title}'
```

## Fetch Diff

```bash
glab mr diff <number>
```

## Check for Existing Review

```bash
glab mr list --source-branch <branch-name>
```

## Find Approved Reviewers

```bash
glab api "projects/:id/merge_requests/<number>/notes?sort=desc&per_page=100" \
  | jq -r '[.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]'
```

## Fetch Review Metadata (Batch)

For batch operations like learnings extraction:

```bash
glab api "projects/:id/merge_requests?state=all&sort=asc&order_by=created_at&per_page=<SIZE>&page=<PAGE>" \
  | jq -c '.[] | {iid, title, state, user_notes_count, author: .author.username, source_branch, reviewers: [.reviewers[].username], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], description: (.description // "(none)")[:400]}'
```

## Verify Platform Access (Batch)

```bash
glab api "projects/:id/merge_requests?state=all&per_page=1" | jq length
```

## Count Total Reviews

```bash
glab api "projects/:id/merge_requests?state=all&per_page=1" --include 2>&1 | grep -i x-total
```
