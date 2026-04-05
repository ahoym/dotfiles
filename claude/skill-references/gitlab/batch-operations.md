---
description: "GitLab commands for batch MR metadata fetching (used by extract-request-learnings)."
---

# GitLab: Batch Operations

## Section Index
<!-- Offsets are 1-indexed line numbers. After editing sections below, verify by running: Read(file, offset, limit) for each slug -->
| Slug | Offset | Limit |
|------|--------|-------|
| fetch-review-metadata-batch | 17 | 11 |
| verify-platform-access-batch | 29 | 5 |
| count-total-reviews | 35 | 5 |

**Use these templates verbatim** ��� substitute placeholders but don't simplify, reformat, or drop parameters.

## Fetch Review Metadata (Batch)

For batch operations like learnings extraction:

```bash
# Write jq filter to tmp/jq-filter.jq via Write tool first (avoids quoted string permission prompt):
#   .[] | {iid, title, state, user_notes_count, author: .author.username, source_branch, reviewers: [.reviewers[].username], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], description: (.description // "(none)")[:400]}
# Then:
glab api "projects/:id/merge_requests?state=all&sort=asc&order_by=created_at&per_page=<SIZE>&page=<PAGE>" \
  | jq -cf tmp/jq-filter.jq
```

## Verify Platform Access (Batch)

```bash
glab api "projects/:id/merge_requests?state=all&per_page=1" | jq length
```

## Count Total Reviews

```bash
glab api "projects/:id/merge_requests?state=all&per_page=1" --include 2>&1 | grep -i x-total
```
