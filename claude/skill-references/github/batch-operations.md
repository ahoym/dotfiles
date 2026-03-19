---
description: "GitHub commands for batch PR metadata fetching (used by extract-request-learnings)."
---

# GitHub: Batch Operations

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

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
