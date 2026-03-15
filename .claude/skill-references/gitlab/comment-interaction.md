---
description: "GitLab commands for fetching, posting, and reacting to MR comments."
---

# GitLab: Comment Interaction

**Important:** Never use `!=` in jq expressions passed via `glab --jq` — the `!` gets shell-escaped. Use positive equivalents like `select(.body | length > 0)`.

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters. They encode accumulated fixes (pagination, quoting, field types) that aren't obvious from the command's surface.

## Fetch Inline/Review Comments

```bash
# Full fetch (--paginate to get all notes beyond default page limit)
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '.[] | {id, body, author: .author.username, created_at, position}'

# Incremental fetch (--paginate + client-side filter to avoid query params that require quoting)
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '.[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at, position}'
```

## Fetch Latest Inline Comment (quick-exit check)

Returns only the most recent note — use for polling quick-exit to check if any new activity exists. GitLab notes API supports `sort` and `per_page` as query params.

```bash
glab api projects/:id/merge_requests/<number>/notes --method GET -f sort=desc -F per_page=1
```

Parse `.[0].created_at` and compare against `LAST_REVIEW_TS`.

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

# Incremental fetch (--paginate + client-side filter to avoid query params that require quoting)
glab api projects/:id/merge_requests/<number>/notes --paginate | jq '[.[] | select(.position == null)] | .[] | select(.created_at > "<TS>") | {id, body, author: .author.username, created_at}'
```

## Reply to Inline Comment

Write the message body to `change-request-replies/<note_id>-<persona>-<role>.md` first (avoids permission prompts from inline HEREDOC content, and prevents file conflicts when multiple agents operate on the same MR), then pass via `-F body=@`:

**Use absolute paths with `-F body=@`** — `glab api` resolves `@` paths relative to the shell's CWD, which may differ from the project root if earlier commands changed directories.

```bash
# Write body to change-request-replies/<note_id>-<persona>-<role>.md, then:
glab api projects/:id/merge_requests/<number>/discussions/<discussion_id>/notes \
  -X POST -F body=@/absolute/path/to/change-request-replies/<note_id>-<persona>-<role>.md
```

## React to Comment

Add an emoji reaction to a note. Use for positive signals/general feedback instead of a text reply.

```bash
# React to a merge request note (available: thumbsup, thumbsdown, smile, tada, confused, heart, rocket, eyes)
glab api projects/:id/merge_requests/<number>/notes/<note_id>/award_emoji -X POST -F name=<emoji>
```

## Post Top-Level Comment

Write the message body to `change-request-replies/<mr_number>-<persona>-<role>-top.md` first, then pass via file reference:

```bash
# Write body to change-request-replies/<mr_number>-<persona>-<role>-top.md, then:
glab mr comment <number> --message "$(cat /absolute/path/to/change-request-replies/<mr_number>-<persona>-<role>-top.md)"
```

**Note:** `glab mr comment` has no `--body-file` or `--message-file` equivalent. The `$(cat ...)` subshell pattern is the best available workaround but may trigger permission prompts for complex message bodies with special characters.
