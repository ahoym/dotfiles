GitLab batch API patterns — field mappings, jq filter templates, and pagination differences from GitHub.
- **Keywords:** GitLab API, glab, batch operations, merge requests, jq filter, field mapping, pagination, x-total
- **Related:** ~/.claude/learnings/git-github-api.md

---

## GitLab vs GitHub Field Name Mapping

GitLab API responses use different field names than GitHub. Key differences for batch metadata extraction:

| GitHub field | GitLab equivalent |
|-------------|-------------------|
| `number` | `iid` |
| `comments` | `user_notes_count` |
| `user.login` | `author.username` |
| `head.ref` | `source_branch` |
| `requested_reviewers[].login` | `reviewers[].username` |

## Batch MR Metadata jq Filter Template

Write jq filter to file first (avoids quoted-string permission prompts), then use `jq -cf`:

```
.[] | {iid, title, state, user_notes_count, author: .author.username, source_branch, reviewers: [.reviewers[].username], created_at: .created_at[:10], merged_at: (.merged_at // "n/a")[:10], description: (.description // "(none)")[:400]}
```

Pagination uses `sort=asc&order_by=created_at` (not `direction=asc` like GitHub).

## Count Total MRs

GitLab returns total count in the `x-total` response header (GitHub uses `Link:` header parsing):

```bash
glab api "projects/:id/merge_requests?state=all&per_page=1" --include 2>&1 | grep -i x-total
```
