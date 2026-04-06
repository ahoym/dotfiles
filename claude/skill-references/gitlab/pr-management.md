---
description: "GitLab commands for creating/updating MRs, posting reviews, and branch management."
---

# GitLab: MR Management

## Section Index
<!-- Offsets are 1-indexed line numbers. After editing sections below, verify by running: Read(file, offset, limit) for each slug -->
| Slug | Offset | Limit |
|------|--------|-------|
| create-or-update-request | 19 | 12 |
| post-review-with-inline-comments | 32 | 49 |
| checkout-review-branch | 81 | 6 |
| check-for-existing-review | 88 | 5 |
| find-approved-reviewers | 94 | 10 |

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Create or Update MR (Body via File)

Write the MR body to `tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md` first to avoid quoting issues.

**Use absolute paths with `$(cat)`** — `$(cat)` resolves relative to the shell's CWD, which may differ from the project root.

```bash
# Write body via Write tool to tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md, then:
glab mr create --target-branch <base-branch> --title "<title>" --description "$(cat /absolute/path/to/tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md)"
# Or update existing:
glab mr update <number> --description "$(cat /absolute/path/to/tmp/claude-artifacts/change-request-replies/request-body-<BRANCH_NAME>.md)"
```

## Post Review with Inline Comments

GitLab has no single "review" API like GitHub. Post inline comments via GraphQL `createDiffNote` mutation, then post the summary as a top-level comment.

**Important:** Do NOT use `glab api -f` with bracket notation (`position[new_line]=...`) for inline comments — see comment-interaction.md caveat. Use GraphQL instead.

**Step 1: Get SHAs and MR internal ID:**

```bash
glab api projects/:id/merge_requests/<number>/versions | jq '.[0] | {base_commit_sha, head_commit_sha}'
glab mr view <number> --output json | jq '.id'
```

The MR `id` (not `iid`) is needed for the GraphQL `noteableId`: `"gid://gitlab/MergeRequest/<id>"`.

**Step 2: Post each inline comment via GraphQL:**

```bash
glab api graphql -f query='mutation {
  createDiffNote(input: {
    noteableId: "gid://gitlab/MergeRequest/<mr_id>",
    body: "<escaped_body>",
    position: {
      baseSha: "<base_sha>",
      headSha: "<head_sha>",
      startSha: "<base_sha>",
      paths: {
        oldPath: "<file_path>",
        newPath: "<file_path>"
      },
      newLine: <line_number>
    }
  }) { note { id } errors }
}'
```

**File-based queries:** For complex mutations, write the query to a `.graphql` file and use **uppercase `-F`**: `glab api graphql -F query=@tmp/claude-artifacts/change-request-replies/gql-1.graphql`. Lowercase `-f query=@file` does NOT read the file — it passes the literal string `@file` as the query value, causing silent GraphQL failures.

**Body escaping:** The body must be a valid GraphQL string literal — escape `"` as `\"`, newlines as `\n`, and single quotes with shell `'\''` trick. For complex bodies, use `jq -Rs` on a file to produce a JSON-escaped string, then interpolate. **Always use `jq` for JSON processing — never `python3`** (not in the permission allowlist for `claude -p` sessions).

**Line number verification:** The `newLine` must be the exact line number in the new file (1-indexed). Off-by-one errors cause `"line_code can't be blank"` errors — GitLab silently rejects positions that don't match the diff. **Always verify line numbers against the actual file content** (via repository files API), not just diff hunk arithmetic. Hunk headers show where the hunk starts, but blank lines and multi-line removals shift subsequent positions.

For new lines (`+` in the diff), omit `oldLine`. For context lines (unchanged), include both `oldLine` and `newLine`. For removed lines (`-`), include only `oldLine`.

**Step 3: Post the review summary as a top-level comment** (see comment-interaction.md → "Post Top-Level Comment").

**Step 4: Clean up:**
Delete only the files written during this run — not the entire directory. Other skills or concurrent agents may have files in `tmp/claude-artifacts/change-request-replies/`. Track filenames as you write them, then delete exactly those files. Leave the directory in place.

## Checkout Review Branch

```bash
glab mr checkout <number>
git pull origin <source_branch>
```

## Check for Existing Review

```bash
glab mr list --source-branch <branch-name>
```

## Find Approved Reviewers

```bash
# Write jq filter to tmp/claude-artifacts/jq-filters/jq-filter.jq via Write tool first (avoids quoted string permission prompt):
#   [.[] | select(.body | test("LGTM"; "i"))] | [.[].author.username] | unique | .[]
# Then:
glab api "projects/:id/merge_requests/<number>/notes?sort=desc&per_page=100" \
  | jq -rf tmp/claude-artifacts/jq-filters/jq-filter.jq
```
