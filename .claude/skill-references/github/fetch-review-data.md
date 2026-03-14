---
description: "GitHub commands for fetching PR metadata, diffs, files, and commits."
---

# GitHub: Fetch Review Data

**Use these templates verbatim** — substitute placeholders but don't simplify, reformat, or drop parameters.

## Fetch Review Details

```bash
gh pr view <number> --json number,title,headRefName,baseRefName,url,state
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
