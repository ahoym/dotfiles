pnpm/Node CI specifics — lockfile handling, action setup, browser caching, linting config.
- **Keywords:** pnpm, GitHub Actions, frozen-lockfile, Playwright browser cache, ESLint, Prettier, eslint-config-prettier, Vercel, serverless, cold start, tsc, tsconfig, dependency-review-action
- **Related:** ~/.claude/learnings/aws/vercel-deployment.md, ~/.claude/learnings/cicd/gitlab.md

---

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
- **`tsc --noEmit` vs `tsc -b --noEmit`**: single-program mode (`--noEmit`) resolves types through transitive imports — a type used but never imported can pass if another imported module references it. Project references mode (`-b`) compiles each `tsconfig` reference in isolation with strict module boundaries. CI typecheck using `--noEmit` can silently pass while `tsc -b` (used in build scripts) fails on the same code.
- **Vite/esbuild strips types without checking.** Environment-specific build scripts (`env-cmd ... vite build`) that skip `tsc` produce working bundles from invalid TypeScript. Type checking belongs in a dedicated CI step matching the build's strictness, not duplicated across build variants.

## Vercel / Serverless

- Per-isolate state (in-memory Maps, singletons) doesn't persist across cold starts — meaningful first layer but not globally distributed
- Missing lockfile commits cause deploy failures — `--frozen-lockfile` passes locally because `pnpm install` silently updates

## Jest / Module Mutation

**Module-load snapshot exports are testing footguns.** `export const cookieDomain = getCookieDomain()` alongside `export const getCookieDomain = () => ...` creates a two-tier API: the snapshot captures the value at module-load time and never updates. Callers importing the constant get a permanently stale value. In Jest, module cache ordering determines whether the snapshot reflects the test's environment. Fix: unexport the snapshot, require callers to use the function.

**Test state restore must use try/finally for module mutations.** When tests directly mutate a shared module object (`configModule.isProduction = true`), the restore must be in `try/finally` or `afterEach`. Jest assertion failures are thrown errors — plain inline restores after assertions are silently skipped on failure, leaving the module poisoned for subsequent tests in the same worker.

**CJS vs ESM interop fragility with test mutations.** `import { foo }` compiled to CJS becomes a property access on the module object, so test-level mutations via `require()` propagate correctly. If the project switches to native ESM, this silently breaks — ESM bindings are live but read-only from the consumer side. Any test relying on `require()` mutation of an imported module is a latent ESM migration breakage.

## Cross-Refs

- `~/.claude/learnings/aws/vercel-deployment.md` — Vercel cron limits, Postgres driver patterns
- `~/.claude/learnings/cicd/gitlab.md` — GitLab CI/CD patterns and configuration
