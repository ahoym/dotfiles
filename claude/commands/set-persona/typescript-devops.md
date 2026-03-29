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

## Proactive Cross-Refs

- `~/.claude/learnings/frontend/typescript-ci-gotchas.md`

## Cross-Refs

Load when working in the specific area:
- `~/.claude/learnings/vercel-deployment.md` — Cron job limits, Vercel Postgres (Neon HTTP driver), nullable column comparisons
- `~/.claude/learnings/cicd/gotchas.md` — GitHub Actions and GitLab CI tripwires
- `~/.claude/learnings/cicd/patterns.md` — CI pipeline structure, composite actions, Docker build stage sharing
