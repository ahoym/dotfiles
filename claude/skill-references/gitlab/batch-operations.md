---
description: "DEPRECATED — Commands extracted to commands/*.sh files. Retained as human-readable reference."
---

# GitLab: Batch Operations (Deprecated — see commands/)

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Fetch Review Metadata (Batch)

For batch operations like learnings extraction:

```bash
# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first (avoids quoted string permission prompt):
#   .[] | {iid, title, state, user_notes_count, author: .author.username, source_branch, reviewers: [.reviewers[].username], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], description: (.description // "(none)")[:400]}
# Then:
glab api "projects/:id/merge_requests?state=all&sort=asc&order_by=created_at&per_page=<SIZE>&page=<PAGE>" \
  | jq -cf tmp/claude-artifacts/jq-filters/jq-filter.jq
```

## Verify Platform Access (Batch)

```bash
glab api "projects/:id/merge_requests?state=all&per_page=1" | jq length
```

## Count Total Reviews

```bash
glab api "projects/:id/merge_requests?state=all&per_page=1" --include 2>&1 | grep -i x-total
```
