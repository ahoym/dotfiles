---
description: "GitHub commands for fetching, posting, and reacting to PR comments."
---

# GitHub: Comment Interaction

**Important:** Never use `!=` in jq expressions passed via `gh --jq` — the `!` gets shell-escaped. Use positive equivalents like `select(.body | length > 0)`.

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters. They encode accumulated fixes (pagination, quoting, field types) that aren't obvious from the command's surface.

**Quoted strings in jq trigger permission prompts.** Any jq expression containing string literals (e.g., `"<TS>"`, `"n/a"`, `"LGTM"`) inside a Bash command triggers permission prompts — even when the string is inside the jq filter, not a shell argument. **Workaround:** Write the jq filter to `tmp/jq-filter.jq` via the Write tool, then use `jq -f tmp/jq-filter.jq`. For `--jq` flag usage, switch to piped `| jq -f` instead.

**This file covers fetching and replying to existing comments.** To **create** new inline comments on a review, use the reviews endpoint in `pr-management.md` — the `/pulls/{n}/comments` endpoint requires `position` or `positioning` fields (not `line`), and posting via the reviews endpoint with a `comments` array is the correct pattern.

## Section Index
<!-- Update offsets after editing content below -->
| Slug | Offset | Limit |
|------|--------|-------|
| fetch-inline-review-comments | 28 | 12 |
| fetch-recent-inline-comments | 41 | 12 |
| fetch-general-review-comments | 54 | 7 |
| fetch-issue-top-level-comments | 62 | 12 |
| reply-to-inline-comment | 75 | 11 |
| edit-inline-comment | 87 | 11 |
| react-to-comment | 99 | 12 |
| post-top-level-comment | 112 | 8 |

## Fetch Inline/Review Comments

```bash
# Full fetch (--paginate to get all comments beyond default 30-per-page limit)
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate --jq '.[] | {id, path, line, body, user: .user.login, created_at}'

# Incremental fetch — write jq filter to file first (avoids quoted string permission prompt):
# 1. Write to tmp/jq-filter.jq via Write tool:
#      .[] | select(.created_at > "<TS>") | {id, path, line, body, user: .user.login, created_at}
# 2. Then (use piped jq -f instead of --jq):
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate | jq -f tmp/jq-filter.jq
```

## Fetch Recent Inline Comments (quick-exit check)

Returns recent inline review comments — use for polling quick-exit to check if any new non-self activity exists. Fetches 10 to see past agent replies. No `--jq` to avoid quoted strings.

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments --method GET -f sort=created -f direction=desc -F per_page=10
```

Filter out self-comments (`Role:.*<YOUR_ROLE>` in body). Interpret results:
- **Some non-self, at least one newer than `LAST_REVIEW_TS`** → new activity, proceed
- **Some non-self, all older than `LAST_REVIEW_TS`** → no new activity, skip
- **All comments are self** → inconclusive (non-self activity may exist beyond the window), fall through to full incremental fetch

## Fetch General Review Comments

```bash
gh pr view <number> --json reviews --jq '.reviews[] | select(.body | length > 0) | {author: .author.login, state: .state, body}'
```

**Note:** This endpoint does not support `since` filtering. On incremental fetches, always re-fetch and compare the review count against `LAST_REVIEW_COUNT` to detect new review submissions.

## Fetch Issue/Top-Level Comments

```bash
# Full fetch (--paginate to get all comments beyond default 30-per-page limit)
gh api repos/{owner}/{repo}/issues/<number>/comments --paginate --jq '.[] | {id, body, user: .user.login, created_at}'

# Incremental fetch — write jq filter to file first (avoids quoted string permission prompt):
# 1. Write to tmp/jq-filter.jq via Write tool:
#      .[] | select(.created_at > "<TS>") | {id, body, user: .user.login, created_at}
# 2. Then (use piped jq -f instead of --jq):
gh api repos/{owner}/{repo}/issues/<number>/comments --paginate | jq -f tmp/jq-filter.jq
```

## Reply to Inline Comment

Write the message body to `tmp/change-request-replies/<comment_id>-<persona>-<role>.md` first (avoids permission prompts from inline HEREDOC content, and prevents file conflicts when multiple agents operate on the same PR), then pass via `-F body=@`:

**Use absolute paths with `-F body=@`** — `gh api` resolves `@` paths relative to the shell's CWD, which may differ from the project root if earlier commands changed directories.

```bash
# Write body to tmp/change-request-replies/<comment_id>-<persona>-<role>.md, then:
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -F body=@/absolute/path/to/tmp/change-request-replies/<comment_id>-<persona>-<role>.md -F in_reply_to=<comment_id>
```

## Edit Inline Comment

Update an existing pull request review comment:

```bash
# Write updated body to .gh-reply.tmp, then:
gh api repos/{owner}/{repo}/pulls/comments/<comment_id> -X PATCH \
  -F body=@.gh-reply.tmp
```

Note: The endpoint is `pulls/comments/<comment_id>` (no PR number), not `pulls/<number>/comments/<comment_id>`.

## React to Comment

Add an emoji reaction to an inline comment or issue comment. Use for positive signals/general feedback instead of a text reply.

```bash
# React to inline/review comment (available: +1, -1, laugh, confused, heart, hooray, rocket, eyes)
# Use -f (lowercase) not -F — -F infers type and treats +1/-1 as numeric, which the API rejects
gh api repos/{owner}/{repo}/pulls/comments/<comment_id>/reactions -f content=<emoji>

# React to issue/top-level comment
gh api repos/{owner}/{repo}/issues/comments/<comment_id>/reactions -f content=<emoji>
```

## Post Top-Level Comment

Write the message body to `tmp/change-request-replies/<pr_number>-<persona>-<role>-top.md` first, then pass via file reference. **Use absolute paths** — same CWD caveat as Reply to Inline Comment.

```bash
# Write body to tmp/change-request-replies/<pr_number>-<persona>-<role>-top.md, then:
gh pr comment <number> --body-file /absolute/path/to/tmp/change-request-replies/<pr_number>-<persona>-<role>-top.md
```
