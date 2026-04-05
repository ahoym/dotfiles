---
description: "GitLab commands for fetching, posting, and reacting to MR comments."
---

# GitLab: Comment Interaction

**Important:** Never use `!=` in jq expressions passed via `glab --jq` — the `!` gets shell-escaped. Use positive equivalents like `select(.body | length > 0)`.

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters. They encode accumulated fixes (pagination, quoting, field types) that aren't obvious from the command's surface.

**Always use `jq` for JSON processing — never `python3`.** `python3` is not in the permission allowlist for `claude -p` sessions and will cause unrecoverable permission denials. Use `jq -Rs` for string escaping, `jq -r` for extraction, `jq -f tmp/filter.jq` for complex filters.

**Quoted strings in jq trigger permission prompts.** Any jq expression containing string literals (e.g., `"<TS>"`, `"n/a"`, `"LGTM"`) inside a Bash command triggers permission prompts — even when the string is inside the jq filter, not a shell argument. **Workaround:** Write the jq filter to `tmp/jq-filter.jq` via the Write tool, then use `jq -f tmp/jq-filter.jq`. This keeps all quoted strings out of the Bash command.

**Caveat: `glab api -f` does NOT create nested JSON objects.** Bracket notation like `-f "position[new_line]=411"` sends flat JSON keys (`"position[new_line]": "411"`) — GitLab ignores these and creates a general note instead of an inline DiffNote. For any API call requiring nested objects (inline comments with position data), use GraphQL `createDiffNote` instead (see pr-management.md → "Post Review with Inline Comments"). This does NOT affect `-f` for flat string parameters (e.g., `-f sort=desc`), which work correctly.

## Section Index
<!-- Update offsets after editing content below -->
| Slug | Offset | Limit |
|------|--------|-------|
| fetch-inline-review-comments | 29 | 12 |
| fetch-recent-inline-comments | 42 | 12 |
| fetch-general-review-comments | 55 | 9 |
| fetch-issue-top-level-comments | 65 | 12 |
| reply-to-inline-comment | 78 | 11 |
| react-to-comment | 90 | 8 |
| post-top-level-comment | 99 | 14 |

## Fetch Inline/Review Comments

```bash
# Full fetch (--paginate to get all notes beyond default page limit)
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '.[] | {id, body, author: .author.username, created_at, position}'

# Incremental fetch — write jq filter to file first (avoids quoted string permission prompt):
# 1. Write to tmp/jq-filter.jq via Write tool:
#      .[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at, position}
# 2. Then:
glab api projects/:id/merge_requests/<number>/notes --paginate | jq -f tmp/jq-filter.jq
```

## Fetch Recent Inline Comments (quick-exit check)

Returns recent notes — use for polling quick-exit to check if any new non-self activity exists. Fetches 10 to see past agent replies.

```bash
glab api projects/:id/merge_requests/<number>/notes --method GET -f sort=desc -F per_page=10
```

Filter out self-comments (`Role:.*<YOUR_ROLE>` in body). Interpret results:
- **Some non-self, at least one newer than `LAST_FETCH_TS`** → new activity, proceed
- **Some non-self, all older than `LAST_FETCH_TS`** → no new activity, skip
- **All comments are self** → inconclusive (non-self activity may exist beyond the window), fall through to full incremental fetch

## Fetch General Review Comments

```bash
# Use discussions endpoint for threaded comments
glab api projects/:id/merge_requests/<number>/discussions \
  | jq '.[] | {id, notes: [.notes[] | {id, body, author: .author.username, position}]}'
```

**Note:** This endpoint does not support `updated_after` filtering. On incremental fetches, always re-fetch and compare the discussion count against `LAST_REVIEW_COUNT` to detect new review submissions.

## Fetch Issue/Top-Level Comments

```bash
# Full fetch — notes without position data are top-level comments (--paginate for all pages)
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '[.[] | select(.position == null)] | .[] | {id, body, author: .author.username, created_at}'

# Incremental fetch — write jq filter to file first (avoids quoted string permission prompt):
# 1. Write to tmp/jq-filter.jq via Write tool:
#      [.[] | select(.position == null)] | .[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at}
# 2. Then:
glab api projects/:id/merge_requests/<number>/notes --paginate | jq -f tmp/jq-filter.jq
```

## Reply to Inline Comment

Write the message body to `tmp/change-request-replies/<note_id>-<persona>-<role>.md` first (avoids permission prompts from inline HEREDOC content, and prevents file conflicts when multiple agents operate on the same MR), then pass via `-F body=@`:

**Use absolute paths with `-F body=@`** — `glab api` resolves `@` paths relative to the shell's CWD, which may differ from the project root if earlier commands changed directories.

```bash
# Write body to tmp/change-request-replies/<note_id>-<persona>-<role>.md, then:
glab api projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -F body=@/absolute/path/to/tmp/change-request-replies/<note_id>-<persona>-<role>.md
```

## React to Comment

Add an emoji reaction to a note. Use for positive signals/general feedback instead of a text reply.

```bash
# React to a merge request note (available: thumbsup, thumbsdown, smile, tada, confused, heart, rocket, eyes)
glab api projects/:id/merge_requests/<number>/notes/<note_id>/award_emoji -X POST -F name=<emoji>
```

## Post Top-Level Comment

Write the message body to `tmp/change-request-replies/<mr_number>-<persona>-<role>-top.md` first, then post via the notes API with `-F body=@`:

```bash
# Write body to tmp/change-request-replies/<mr_number>-<persona>-<role>-top.md, then:
glab api projects/:id/merge_requests/<number>/notes -X POST \
  -F body=@/absolute/path/to/tmp/change-request-replies/<mr_number>-<persona>-<role>-top.md
```

**Use absolute paths with `-F body=@`** — `glab api` resolves `@` paths relative to the shell's CWD, which may differ from the project root if earlier commands changed directories.

**Note:** Avoid `glab mr comment --message "$(cat ...)"` — the `$(cat ...)` subshell triggers permission prompts. The notes API with `-F body=@` reads the file directly without shell interpolation.
