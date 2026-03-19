---
description: "GitLab commands for fetching MR metadata, diffs, files, and commits."
---

# GitLab: Fetch Review Data

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

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
glab mr diff <number> --raw | grep '^diff --git' | sed 's|diff --git a/.* b/||'
```

Note: `glab mr diff` has no `--name-only` flag. Extract filenames from raw diff output.

## Fetch Commits

```bash
glab api projects/:id/merge_requests/<number>/commits \
  --jq '.[] | {sha: .short_id, message: .title}'
```
