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

## GitHub Actions CI Template for Next.js/pnpm

**Utility: Medium**

Parallel job structure for Next.js + pnpm projects:

| Job | Trigger | Blocks Merge? |
|-----|---------|---------------|
| Lint | push + PRs | Yes |
| Build (type-check) | push + PRs | Yes |
| Unit tests | push + PRs | Yes |
| Prettier (changed files) | PRs only | Yes |
| Dependency review | PRs only | Yes |
| E2E tests | push + PRs | No (informational) |

Key configuration choices:
- `pnpm/action-setup@v4` — reads `packageManager` from `package.json` automatically
- `actions/setup-node@v4` with `cache: 'pnpm'` — caches pnpm store
- `--frozen-lockfile` on all installs — catches missing lockfile updates
- `workflow_dispatch` — manual "Run workflow" button for re-runs
- `concurrency` with `cancel-in-progress: true` — saves CI minutes on re-push
- Minimal permissions: `contents: read`, `pull-requests: write`
- Job timeouts: 5 min for fast jobs, 15 min for E2E
- `paths-ignore: ['**/*.md']` — skip CI on markdown-only changes
- E2E uses `continue-on-error: true` for non-blocking informational status

## eslint-config-prettier Required When Adding Prettier

**Utility: Medium**

When introducing Prettier to a project with ESLint, always add `eslint-config-prettier`. It disables all ESLint formatting rules that conflict with Prettier. Without it, ESLint and Prettier can demand contradictory formatting, causing both CI checks to fail.

For ESLint v9 flat config:
```js
import prettierConfig from "eslint-config-prettier";

const eslintConfig = defineConfig([
  ...otherConfigs,
  prettierConfig,  // must be last to override formatting rules
]);
```

## dependency-review-action vs pnpm audit

**Utility: High**

These serve different purposes and should not be treated as interchangeable:

| | `actions/dependency-review-action` | `pnpm audit` |
|---|---|---|
| **Scope** | Only *newly introduced* deps in the PR | Entire dependency tree |
| **Signal** | Actionable — PR author can fix | Noisy — deep transitive deps often unfixable |
| **When** | PR-only | Any time |
| **Best for** | CI gate on PRs | Separate monitoring |

**Recommendation**: Use `dependency-review-action` in CI to gate PRs (focused, actionable). Use GitHub Dependabot alerts for comprehensive vulnerability tracking (managed separately, auto-creates fix PRs).

## Diagnosing CI Failures on Dependabot PRs

**Utility: Medium**

Quick workflow for investigating failing CI checks on PRs (especially dependabot):

```bash
# 1. See which checks failed
gh pr checks <PR_NUMBER>

# 2. Get the failed job logs (run ID from checks output)
gh run view <RUN_ID> --job <JOB_ID> --log-failed

# 3. Checkout the PR branch locally
gh pr checkout <PR_NUMBER>

# 4. Reproduce and fix locally
pnpm install && pnpm lint  # (or whichever check failed)
```

The `--log-failed` flag on `gh run view` filters to only the failing step output, which is much more useful than `--log` which dumps everything. Pipe through `tail -80` to focus on the error message at the end.
