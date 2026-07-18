# Platform: GitHub

Implementation of the platform contract for GitHub Issues + PRs. Loaded by `SKILL.md` Phase 2 when source detection resolves to `github`.

## 1. Detection

| Signal | Resolution |
|---|---|
| Arg matches `#\d+` AND remote contains `github.com` | `github` |
| `--source=github` flag | `github` (override) |

## 2. Fetch single item

```bash
gh issue view <N> --json number,title,body,state,labels,url,updatedAt,comments
```

Output JSON includes the comment thread inline (no separate fetch needed).

## 3. Fetch list

```bash
gh issue list --state open --limit <MAX> --json number,title,body,state,labels,url,updatedAt
```

Filters:
- Label: `--label=<name>` → `gh issue list ... --label <name>`
- Author: `--author=<user>` → append `--author <user>`

List output does **not** include comments — fetch per-item via #4 if needed.

## 4. Fetch comments

```bash
gh issue view <N> --json comments -q '.comments[] | {id, body, author: .author.login, createdAt}'
```

Top-level comments only — GitHub Issues don't have inline comments.

## 5. State mapping

| GitHub state | Normalized |
|---|---|
| `OPEN` | `OPEN` |
| `CLOSED` | `CLOSED` |

GitHub Issues have no separate "Done" status — closed = closed.

## 6. Blocked-by detection

Parse issue body for:
- Lines matching `^Blocked by:` (case-insensitive) → extract `#(\d+)` from each
- Inside `## Dependencies` / `## Blocked by` headed sections → extract `#(\d+)` from any line

A blocker is **resolved** if:
- The blocker issue is `CLOSED`, OR
- The blocker has a merged PR (`gh pr list --state merged --search "fixes #<N> OR closes #<N> OR relates to #<N>"`), OR
- The blocker has an open PR with a sweep branch (`gh pr list --state open --head 'sweep/<N>-*'`)

A blocker is **unresolved** only when the issue is open AND has no PR.

## 7. Linked-PR detection

```bash
gh pr list --state open --head "sweep/<N>-*" --json number,headRefName,url
```

Filter client-side; substring matches like `#9` matching `#99` must be ruled out by checking PR body for exact phrases (`Relates to #<N>`, `Fixes #<N>`, `Closes #<N>`, `Blocked by:.*#<N>`).

## 8. Comment posting (POST_ISSUE_COMMENT_CMD template)

Agent writes body to `<ABS_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<N>-comment.md`, then:

```bash
gh issue comment <N> --body-file <ABS_PROJECT_ROOT>/tmp/claude-artifacts/change-request-replies/<N>-comment.md
```

`gh issue comment` supports `--body-file` natively.

## 9. Watermark fields

`status.md` keys for GitHub:
```yaml
last_comment_id: <max comment.id from gh issue view>
last_sweep_updated_at: <issue.updatedAt>
```

Skip rule: both must equal current values to skip. Either differs → re-process.

## 10. Branch naming

`sweep/<N>-<slug>` where `<N>` is the bare issue number (no `#` prefix) and `<slug>` is a kebab-case 3-5 word summary derived from the title.

Example: issue `#42` titled "Fix login redirect after timeout" → `sweep/42-fix-login-redirect`.

## Permissions (Phase 0 prereq check)

When source resolves to `github`, these patterns must be in `~/.claude/settings.json`:

```json
"Bash(gh issue list:*)", "Bash(gh issue view:*)", "Bash(gh issue comment:*)",
"Bash(gh pr list:*)", "Bash(gh pr create:*)", "Bash(gh api:*)", "Bash(gh auth:*)"
```
