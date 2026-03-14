---
description: "GitLab commands for fetching MR metadata, diffs, files, and commits."
---

# GitLab: Fetch Review Data

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Fetch Review Details

```bash
glab mr view <number> --output json
```

## Fetch Diff

```bash
glab mr diff <number>
```

## Fetch Files Changed

```bash
glab mr diff <number> --name-only
```

## Fetch Commits

```bash
glab api projects/:id/merge_requests/<number>/commits \
  --jq '.[] | {sha: .short_id, message: .title}'
```
