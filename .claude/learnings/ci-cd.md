# CI/CD Patterns

## Lightweight CI Guard (No Checkout)

To block specific file paths from being merged to a branch without needing a full checkout:

```yaml
- name: Check for blocked files in MR
  run: |
    FILES=$(curl -s --header "PRIVATE-TOKEN: $CI_TOKEN" \
      "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/changes" \
      | jq -r '.changes[].new_path | select(startswith(".claude/commands/"))')
    if [ -n "$FILES" ]; then
      echo "ERROR: MR contains blocked files"
      exit 1
    fi
```

**Why this pattern:**
- No full checkout needed — runs in seconds
- No dependencies beyond `curl` and `jq`
- Filters server-side via API, keeping output minimal
- Works in GitLab CI pipelines with `rules: - if: '$CI_MERGE_REQUEST_IID'`

**GitHub Actions equivalent** (for reference):
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
