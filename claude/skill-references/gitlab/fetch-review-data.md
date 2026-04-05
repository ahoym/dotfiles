---
description: "GitLab commands for fetching MR metadata, diffs, files, and commits."
---

# GitLab: Fetch Review Data

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Section Index
<!-- Update offsets after editing content below -->
| Slug | Offset | Limit |
|------|--------|-------|
| fetch-review-details | 19 | 5 |
| fetch-activity-signals | 25 | 9 |
| fetch-diff | 35 | 5 |
| fetch-files-changed | 41 | 7 |
| fetch-commits | 49 | 8 |

## Fetch Review Details

```bash
glab mr view <number> --output json
```

## Fetch Activity Signals (consolidated)

Quick-exit check for polling — MR state and latest activity. `glab mr view` returns state, commits, and metadata in one call. No `--jq`. Parse JSON response in agent logic.

```bash
glab mr view <number> --output json
```

For notes/comments activity, see "Fetch Recent Inline Comments" in comment-interaction.md.

## Fetch Diff

```bash
glab mr diff <number>
```

## Fetch Files Changed

```bash
glab api projects/:id/merge_requests/<number>/changes | jq -r .changes[].new_path
```

Note: Uses the MR changes API instead of parsing raw diff — avoids quoted `grep`/`sed` args that trigger permission prompts in Claude Code.

## Fetch Commits

```bash
glab api projects/:id/merge_requests/<number>/commits \
  | jq '.[] | {sha: .short_id, message: .title}'
```

Note: `glab api` has no `--jq` flag (unlike `gh api`). Pipe to standalone `jq` instead.
