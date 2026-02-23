# TypeScript DevOps & Infrastructure Focus

## Extends: platform-engineer

## Domain priorities
- Node.js/pnpm CI pipelines: install caching, lockfile integrity, parallel job structure
- TypeScript build tooling: type-checking as CI gate, ESLint/Prettier coexistence, bundler configuration
- E2E testing infrastructure: Playwright browser caching, test parallelization, flaky test management
- Serverless deployment: Vercel, edge runtimes, cold start implications

## When reviewing or writing code
- Verify `pnpm-lock.yaml` is committed when dependencies change — `--frozen-lockfile` in CI catches this but local installs silently update
- Check that ESLint and Prettier configs don't conflict — `eslint-config-prettier` must be last
- Ensure E2E tests are non-blocking (`continue-on-error: true`) unless the project has stabilized them

## Known gotchas & platform specifics

### GitHub Actions (pnpm/Node)
- `pnpm/action-setup@v4` reads `packageManager` from `package.json` automatically; pair with `actions/setup-node@v4` `cache: 'pnpm'` for store caching
- Always use `--frozen-lockfile` on CI installs — catches missing lockfile updates that pass locally
- Changed-files-only checks (e.g., Prettier): use `git diff --name-only --diff-filter=ACMR origin/$base_ref` with `head -200` to prevent arg overflow
- `dependency-review-action` gates PRs on *newly introduced* vulnerable deps (actionable); `pnpm audit` scans the full tree (noisy) — use the former in CI, Dependabot alerts for the latter
- When adding Prettier alongside ESLint, always add `eslint-config-prettier` as the last config to disable conflicting formatting rules. For ESLint v9 flat config, use `eslint-config-prettier/flat` (the bare import is for legacy `.eslintrc` configs)
- Shared install job: use `actions/cache/save` in a dedicated `install` job, then `actions/cache/restore` in parallel downstream jobs — avoids N redundant `pnpm install` calls. Downstream jobs still need `pnpm/action-setup` + `actions/setup-node` for binaries but skip `cache: pnpm`
- Playwright browser caching: cache `~/.cache/ms-playwright` keyed on `@playwright/test` version (~30-40s saved). On cache hit, run `playwright install-deps chromium` (system deps only); on miss, run `playwright install --with-deps chromium` (browsers + system deps)

### Vercel / Serverless
- Per-isolate state (in-memory Maps, singletons) doesn't persist across cold starts — meaningful first layer but not globally distributed
- Missing lockfile commits cause deploy failures — `--frozen-lockfile` passes locally because `pnpm install` silently updates; check `git diff --stat pnpm-lock.yaml`
