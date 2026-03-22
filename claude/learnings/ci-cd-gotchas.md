# CI/CD Gotchas

GitHub Actions and GitLab CI tripwires covering concurrency, permissions, caching, artifact expiry, and CI guard patterns.
**Keywords:** GitHub Actions, GitLab CI, concurrency, cancel-in-progress, paths-ignore, continue-on-error, needs, cache, artifacts, interruptible, protected variables, GIT_DEPTH, retry, DinD
**Related:** git-patterns.md, ci-cd.md, typescript-ci-gotchas.md

---

## GitHub Actions

- `concurrency` with `cancel-in-progress: true` saves CI minutes on re-push
- `paths-ignore: ['**/*.md']` skips CI on markdown-only changes
- `continue-on-error: true` for non-blocking informational jobs (e.g., E2E)
- Minimal permissions: `contents: read`, `pull-requests: write`
- Set job timeouts: 5 min for fast jobs, 15 min for E2E
- Diagnosing failures: `gh run view <RUN_ID> --job <JOB_ID> --log-failed` — pipe through `tail -80`

## GitLab CI/CD

- `rules:` replaces `only:/except:` — can't combine both in the same job
- `needs:` for DAG parallelism — jobs run when dependencies finish, not when the stage completes
- `cache:` is per-runner by default — use distributed backend (S3, GCS) or `cache:key:files:` with lockfile paths
- `artifacts:expire_in:` defaults to 30 days — set explicitly; use `artifacts:reports:` for MR widget integration
- `interruptible: true` on safely-cancellable jobs saves runner minutes on re-push
- `extends:` over YAML anchors — supports deep merge, more readable
- `include:project` for org-wide templates, `include:local` for repo-internal fragments
- Protected variables only available on protected branches/tags — feature branches silently get empty values
- `GIT_DEPTH: 20` (or appropriate depth) in `variables:` for faster clones — `GIT_DEPTH: 0` for full history when needed (changelog, diff-based checks)
- `allow_failure: true` for non-blocking informational jobs; `allow_failure:exit_codes:` for granular control
- `environment:` with `url:` and `on_stop:` for review apps — enables automatic cleanup when MRs are merged/closed
- `retry: 2` on flaky infrastructure jobs (Docker pulls, network-dependent steps) — avoid on test jobs as it masks real failures

## CI Guards

- Lightweight CI guard (no checkout): API calls + `jq` to check for blocked file paths — runs in seconds with no dependencies beyond `curl` and `jq`

## Cross-Refs

- `~/.claude/learnings/git-patterns.md` — git rebase/stash/worktree patterns that interact with CI workflows
- `ci-cd.md` — full YAML examples for CI guard patterns referenced in the CI Guards section above
- `typescript-ci-gotchas.md` — pnpm/Node CI specifics (lockfile, action setup, Playwright caching, ESLint+Prettier)
