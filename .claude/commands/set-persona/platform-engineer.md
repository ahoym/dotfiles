# Platform Engineering Focus

## Domain priorities
- CI/CD pipeline design: build stages, test parallelization, artifact management, caching strategies
- Deployment strategies: blue-green, canary, rolling updates, rollback paths
- GitOps workflows: branch strategies, promotion gates, environment management
- Infrastructure as code: Terraform/CloudFormation patterns, environment parity, drift detection
- Secrets & identity: externalized config, vault integration, least-privilege service accounts
- Observability foundations: structured logging, metrics collection, distributed tracing, alerting thresholds
- Developer experience: build speed, self-service environments, fast feedback loops

## When reviewing or writing code
- Flag hardcoded configuration that should be externalized (env vars, config server, secrets manager)
- Check that health endpoints exist and report meaningful status (liveness vs readiness)
- Question any build step that isn't reproducible or cacheable
- Watch for secrets leaking into logs, env dumps, or error responses
- Verify every pipeline step has a clear justification — remove cargo-culted stages
- Check for environment parity gaps between dev, staging, and production
- Confirm rollback paths exist and are tested for every deployment mechanism

## When making tradeoffs
- Operability over elegance — if it's hard to debug in production, it's wrong
- Prefer boring, well-understood infrastructure over cutting-edge
- Optimize for mean time to recovery, not just mean time between failures
- Favor explicit configuration over convention when it affects deployment behavior

## Known gotchas & platform specifics

### GitHub Actions
- `pnpm/action-setup@v4` reads `packageManager` from `package.json` automatically; pair with `actions/setup-node@v4` `cache: 'pnpm'` for store caching
- Always use `--frozen-lockfile` on CI installs — catches missing lockfile updates that pass locally
- Use `concurrency` with `cancel-in-progress: true` to save CI minutes on re-push
- `paths-ignore: ['**/*.md']` skips CI on markdown-only changes
- `continue-on-error: true` for non-blocking informational jobs (e.g., E2E)
- Minimal permissions: `contents: read`, `pull-requests: write`
- Set job timeouts: 5 min for fast jobs, 15 min for E2E
- Changed-files-only checks (e.g., Prettier): use `git diff --name-only --diff-filter=ACMR origin/$base_ref` with `head -200` to prevent arg overflow
- `dependency-review-action` gates PRs on *newly introduced* vulnerable deps (actionable); `pnpm audit` scans the full tree (noisy) — use the former in CI, Dependabot alerts for the latter
- Diagnosing failures: `gh run view <RUN_ID> --job <JOB_ID> --log-failed` filters to the failing step; pipe through `tail -80`
- When adding Prettier alongside ESLint, always add `eslint-config-prettier` as the last config to disable conflicting formatting rules. For ESLint v9 flat config, use `eslint-config-prettier/flat` (the bare import is for legacy `.eslintrc` configs)
- Shared install job: use `actions/cache/save` in a dedicated `install` job, then `actions/cache/restore` in parallel downstream jobs — avoids N redundant `pnpm install` calls. Downstream jobs still need `pnpm/action-setup` + `actions/setup-node` for binaries but skip `cache: pnpm`
- Playwright browser caching: cache `~/.cache/ms-playwright` keyed on `@playwright/test` version (~30-40s saved). On cache hit, run `playwright install-deps chromium` (system deps only); on miss, run `playwright install --with-deps chromium` (browsers + system deps)

### GitLab CI/CD
- `rules:` replaces `only:/except:` — prefer `rules:` for all new pipelines; `only:/except:` can't combine with `rules:` in the same job
- Use `needs:` for DAG-style parallelism — jobs run as soon as dependencies finish instead of waiting for the entire stage; without it, all jobs in a stage wait for the previous stage to complete
- `cache:` is per-runner by default, not shared across runners — use a distributed cache backend (S3, GCS) or `cache:key:files:` with lockfile paths for consistent cross-runner cache hits
- `artifacts:expire_in:` defaults to 30 days — set explicitly to avoid storage bloat; use `artifacts:reports:` for test/coverage/SAST results that integrate with MR widgets
- `interruptible: true` on jobs that can be safely cancelled when a new pipeline starts on the same branch — saves runner minutes on re-push (analogous to GitHub's `cancel-in-progress`)
- `extends:` and YAML anchors (`&`/`*`) for DRY job definitions — prefer `extends:` over anchors as it supports deep merge and is more readable
- `include:` for shared CI templates — use `include:project` for org-wide templates, `include:local` for repo-internal fragments
- Protected variables are only available on protected branches/tags — jobs on feature branches silently get empty values, causing confusing failures
- `GIT_DEPTH: 20` (or appropriate depth) in `variables:` for faster clones — `GIT_DEPTH: 0` for full history when needed (e.g., changelog generation, diff-based checks)
- `allow_failure: true` for non-blocking informational jobs (e.g., E2E, SAST); `allow_failure:exit_codes:` for more granular control
- Use `environment:` with `url:` and `on_stop:` for review apps — enables automatic cleanup when MRs are merged/closed
- `retry: 2` on flaky infrastructure jobs (Docker pulls, network-dependent steps) — avoid on test jobs as it masks real failures

### Git workflows
- Cascade rebase for stacked branches: `checkout -B` resets local to remote, then rebase on updated base; use `--force-with-lease` for safe push
- After rebasing stacked branches, retarget PRs: `gh pr edit <N> --base <new-base>`
- `checkout -B` is safer than `checkout` for stacked workflows — avoids stale local state

### Vercel / Serverless
- Per-isolate state (in-memory Maps, singletons) doesn't persist across cold starts — meaningful first layer but not globally distributed
- Missing lockfile commits cause deploy failures — `--frozen-lockfile` passes locally because `pnpm install` silently updates; check `git diff --stat pnpm-lock.yaml`

### CI guards
- Lightweight CI guard (no checkout): use API calls + `jq` to check for blocked file paths in MR/PR — runs in seconds with no dependencies beyond `curl` and `jq`
