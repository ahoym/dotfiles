# GitLab CLI (glab)

## Repointing MR Target Branches

Repoint an MR's target branch (e.g., for stacked MR chains):

```bash
glab mr update <MR_ID> --target-branch <branch-name>
```

## Flag Differences from gh CLI

- `glab mr list --all` shows all states (open/merged/closed). There is no `--state` flag — use `--all` or no flag (defaults to open).
- `glab mr diff` has no `--name-only` flag. Extract filenames from raw diff: `glab mr diff <N> --raw | grep '^diff --git' | sed 's|diff --git a/.* b/||'`.
- `glab api` has no built-in `--jq` flag (unlike `gh api`). Pipe output to the standalone `jq` CLI: `glab api projects/:id/merge_requests/<N>/commits | jq '.[] | {sha: .short_id}'`.
