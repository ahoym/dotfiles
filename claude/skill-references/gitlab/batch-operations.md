---
description: "GitLab commands for batch MR metadata fetching (used by extract-request-learnings)."
---

# GitLab: Batch Operations

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

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
