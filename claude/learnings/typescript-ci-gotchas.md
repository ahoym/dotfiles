# TypeScript CI Gotchas

pnpm/Node CI specifics — lockfile handling, action setup, browser caching, linting config.

## GitHub Actions (pnpm/Node)

- `pnpm/action-setup@v4` reads `packageManager` from `package.json` automatically; pair with `actions/setup-node@v4` `cache: 'pnpm'` for store caching
- Always use `--frozen-lockfile` on CI installs — catches missing lockfile updates that pass locally
- Changed-files-only checks (e.g., Prettier): `git diff --name-only --diff-filter=ACMR origin/$base_ref` with `head -200` to prevent arg overflow
- `dependency-review-action` gates PRs on *newly introduced* vulnerable deps (actionable); `pnpm audit` scans full tree (noisy)
- ESLint + Prettier coexistence: always add `eslint-config-prettier` last; for ESLint v9 flat config use `eslint-config-prettier/flat`
- Shared install job: `actions/cache/save` in dedicated `install` job, then `actions/cache/restore` in parallel downstream jobs — avoids N redundant `pnpm install` calls
- Playwright browser caching: cache `~/.cache/ms-playwright` keyed on `@playwright/test` version; on hit run `playwright install-deps chromium`, on miss run `playwright install --with-deps chromium`

## TypeScript Build

- When `tsc` fails on missing module imports, check `node_modules` freshness before restructuring `tsconfig.json` — stale deps are the more common cause

## Vercel / Serverless

- Per-isolate state (in-memory Maps, singletons) doesn't persist across cold starts — meaningful first layer but not globally distributed
- Missing lockfile commits cause deploy failures — `--frozen-lockfile` passes locally because `pnpm install` silently updates

## Cross-Refs

- `~/.claude/learnings/vercel-deployment.md` — Vercel cron limits, Postgres driver patterns
- `~/.claude/learnings/ci-cd.md` — general CI/CD patterns and YAML examples
- `~/.claude/learnings/ci-cd-gotchas.md` — general GitHub Actions and GitLab CI tripwires (stack-agnostic companion)
