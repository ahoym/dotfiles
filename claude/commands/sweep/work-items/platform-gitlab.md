# Platform: GitLab

Implementation of the platform contract for GitLab Issues + MRs. Loaded by `SKILL.md` Phase 2 when source detection resolves to `gitlab`.

## 1. Detection

| Signal | Resolution |
|---|---|
| Arg matches `#\d+` AND remote contains `gitlab.com` (or self-hosted GitLab) | `gitlab` |
| `--source=gitlab` flag | `gitlab` (override) |

## 2. Fetch single item

```bash
glab api projects/:id/issues/<IID> | jq '{iid, title, description, state, labels, web_url, updated_at}'
```

Output does **not** include comments — fetch via #4. (`glab issue view <IID>` also works but returns formatted text, not JSON.)

## 3. Fetch list

```bash
glab issue list --state opened --output json --per-page <MAX>
```

Or via REST for richer filtering:

```bash
glab api 'projects/:id/issues?state=opened&per_page=<MAX>' | jq '.[] | {iid, title, description, state, labels, web_url, updated_at}'
```

Filters:
- Label: `--label=<name>` (CLI) or `?labels=<name>` (REST)
- Author: append `&author_username=<user>`

## 4. Fetch comments

```bash
# Full fetch — notes without position data are top-level comments
glab api projects/:id/issues/<IID>/notes --paginate \
  | jq '[.[] | select(.position == null)] | .[] | {id, body, author: .author.username, created_at}'
```

For incremental fetch (since timestamp `<TS>`):

```bash
# 1. Write jq filter to file (avoids shell-quote complexity):
#      [.[] | select(.position == null)] | .[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at}
# 2. Run:
glab api projects/:id/issues/<IID>/notes --paginate | jq -f tmp/claude-artifacts/jq-filters/jq-filter.jq
```

Note: `glab api` has no `--jq` flag — pipe to standalone `jq` instead.

## 5. State mapping

| GitLab state | Normalized |
|---|---|
| `opened` | `OPEN` |
| `closed` | `CLOSED` |

GitLab Issues have no separate "Done" status. Normalize via `tr '[:lower:]' '[:upper:]'` since GitLab returns lowercase.

## 6. Blocked-by detection

Parse issue description for:
- Lines matching `^Blocked by:` (case-insensitive) → extract `#(\d+)` from each
- Inside `## Dependencies` / `## Blocked by` sections → extract `#(\d+)` from any line

GitLab also has typed issue links via REST — could augment with:

```bash
glab api projects/:id/issues/<IID>/links | jq '.[] | {iid, title, link_type, state}'
```

`link_type == "is_blocked_by"` is the formal blocker. Prefer this over body-text parsing when present.

A blocker is **resolved** if:
- The blocker issue is `closed`, OR
- The blocker has a merged MR referencing it, OR
- The blocker has an open MR with a sweep branch (`glab api projects/:id/merge_requests -F source_branch=sweep/<N>-* -F state=all`)

## 7. Linked-PR detection

```bash
# By branch pattern
glab api projects/:id/merge_requests -F source_branch=<BRANCH> -F state=all \
  | jq '.[] | {iid, source_branch, state}'

# Issue link API (MRs linked via "closes #N" or manual links)
glab api projects/:id/issues/<IID>/related_merge_requests \
  | jq '.[] | {iid, source_branch, state, description}'
```

Filter PR body text to confirm exact issue ref (avoid `#9` matching `#99`).

## 8. Comment posting (POST_ITEM_COMMENT_CMD template)

Agent writes body to `<ABS_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<IID>-comment.md`, then:

```bash
# Use uppercase -F (not -f) with @path — -F reads the file, -f posts the literal string
glab api projects/:id/issues/<IID>/notes -X POST \
  -F body=@<ABS_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<IID>-comment.md
```

`glab issue note` does **not** support `--body-file`. Use the `glab api` form above.

## 9. Watermark fields

`status.md` keys for GitLab:
```yaml
last_comment_id: <max id from notes API where position == null>
last_sweep_updated_at: <issue.updated_at>
```

Skip rule: both must equal current values. Either differs → re-process.

## 10. Branch naming

`sweep/<IID>-<slug>` where `<IID>` is the bare issue number and `<slug>` is a kebab-case 3-5 word title summary.

Example: issue `#42` titled "Fix login redirect" → `sweep/42-fix-login-redirect`.

## Permissions (Phase 0 prereq check)

When source resolves to `gitlab`, these patterns must be in `~/.claude/settings.json`:

```json
"Bash(glab api:*)", "Bash(glab mr create:*)", "Bash(glab mr list:*)",
"Bash(glab issue list:*)", "Bash(glab issue view:*)", "Bash(glab issue comment:*)",
"Bash(glab issue create:*)", "Bash(glab auth:*)"
```
