---
description: "GitHub commands for fetching PR metadata, diffs, files, and commits."
---

# GitHub: Fetch Review Data

## Section Index
<!-- Offsets are 1-indexed line numbers. After editing sections below, verify by running: Read(file, offset, limit) for each slug -->
| Slug | Offset | Limit |
|------|--------|-------|
| fetch-review-details | 20 | 5 |
| fetch-review-details-with-reviews | 26 | 7 |
| fetch-activity-signals | 34 | 7 |
| fetch-diff | 42 | 5 |
| fetch-files-changed | 48 | 5 |
| fetch-commits | 54 | 6 |

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Fetch Review Details

```bash
gh pr view <number> --json number,title,headRefName,baseRefName,url,state
```

## Fetch Review Details with Reviews (consolidated)

Combines metadata, state, and reviews in a single call — use when step 3+4 can be merged (e.g., code-review-request). No `--jq` to avoid quoted strings in permission patterns.

```bash
gh pr view <number> --json number,title,headRefName,baseRefName,url,state,reviews
```

## Fetch Activity Signals (consolidated)

Quick-exit check for polling — commits, reviews, state, and top-level comments in one call. No `--jq`. Parse JSON response in agent logic.

```bash
gh pr view <number> --json commits,reviews,state,comments
```

## Fetch Diff

```bash
gh pr diff <number>
```

## Fetch Files Changed

```bash
gh pr view <number> --json files --jq '.files[].path'
```

## Fetch Commits

```bash
gh pr view <number> --json commits \
  --jq '.commits[] | {sha: .oid[0:7], message: .messageHeadline}'
```
