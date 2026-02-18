# CI/CD Patterns

## Lightweight GitHub Actions Guard (No Checkout)

To block specific file paths from being merged to a branch without needing a full checkout:

```yaml
- name: Check for blocked files in PR
  env:
    GH_TOKEN: ${{ github.token }}
  run: |
    FILES=$(gh api "repos/${{ github.repository }}/pulls/${{ github.event.pull_request.number }}/files" \
      --paginate --jq '.[].filename | select(startswith(".claude/commands/"))')
    if [ -n "$FILES" ]; then
      echo "::error::PR contains blocked files"
      exit 1
    fi
```

**Why this pattern:**
- No `actions/checkout` needed — runs in ~2 seconds
- No dependencies (Python, Node, etc.) — just `gh` which is pre-installed
- `--paginate` handles PRs with 100+ files
- `--jq` filters server-side, keeping output minimal
