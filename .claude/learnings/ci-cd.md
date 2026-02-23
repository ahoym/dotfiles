# CI/CD Learnings

## Prettier Gradual Adoption via Changed-Files CI Check

**Utility: High**

Run Prettier only on files changed in a PR to avoid a big-bang reformat when introducing Prettier to an existing codebase. Only newly touched files must pass formatting, gradually improving the codebase over time.

In GitHub Actions:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # full history needed for git diff

- name: Check formatting of changed files
  run: |
    FILES=$(git diff --name-only --diff-filter=ACMR origin/${{ github.base_ref }} -- '*.ts' '*.tsx' '*.js' '*.mjs' '*.json' '*.css' | head -200)
    if [ -z "$FILES" ]; then
      echo "No formattable files changed."
      exit 0
    fi
    echo "$FILES" | xargs npx prettier --check
```

Key details:
- `--diff-filter=ACMR` = Added, Copied, Modified, Renamed (skip deleted files)
- `head -200` prevents argument list overflow on huge PRs
- Only run this job on PRs (`if: github.event_name == 'pull_request'`)


