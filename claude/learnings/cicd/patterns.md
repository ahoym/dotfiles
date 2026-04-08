Reusable CI pipeline structures and platform-specific patterns: composite actions, lint-first dependency chains, Docker build-push colocation, GitHub Actions configuration.
- **Keywords:** Docker build push, composite action, lint gate, needs dependency chain, Ruff formatter, CI pipeline structure, cancel-in-progress, test gating, selective tests, latent bugs, iterative validation, GitHub Actions, paths-ignore, continue-on-error, job timeout, gh run view, docker login, password-stdin, container registry, credentials
- **Related:** ~/.claude/learnings/frontend/typescript-ci-gotchas.md

---

## Docker Build and Push Must Share a CI Stage

Splitting `docker build` and `docker push` across separate CI stages fails silently — the push stage runs on a different runner instance that doesn't have the locally-built image. Build and push in the same job.

## Reusable Composite Actions for Shared CI Setup

When multiple CI jobs need the same environment (language runtime, package manager, native C libraries), extract setup into a composite action (e.g., `.github/actions/setup-env/action.yml`). Avoids duplicating 50+ lines across jobs and makes adding new jobs trivial.

## CI Pipeline Structure: Lint-First with Dependency Chain

Structure CI as `lint -> test -> integration` via `needs:`. Lint runs first as a fast gate (seconds, not minutes). Tests only run if lint passes. Integration tests only on pushes to main (not on PRs) to avoid slow PR feedback. Add concurrency controls (`cancel-in-progress: true`) to cancel stale runs on the same branch.

## Ruff Formatting Fixes Bundled with CI Setup

When adding a formatter check to CI (`ruff format --check`), expect a one-time batch of formatting-only changes in the same PR. This is a one-time cost that makes all future PRs pass cleanly.

## Test Gating and Iterative Validation

### Removing selective test gating surfaces latent bugs

When `changes`-based CI filtering was removed and all tests began running on every MR, pre-existing bugs were immediately exposed — specifically a routing key case mismatch that had been hidden because the affected tests only ran when their module's files changed. Selective test gating trades CI speed for hidden regressions — when removing gating, budget time for fixing the bugs it surfaces.

### Iterative CI validation via test commits on MR branches

When CI changes can't be tested locally, push intermediate commits to validate the fix via MR pipelines. CI config changes are tested in CI — multiple intermediate commits on an MR branch is the expected workflow, not a sign of sloppiness.

## GitHub Actions

- `paths-ignore: ['**/*.md']` skips CI on markdown-only changes
- `continue-on-error: true` for non-blocking informational jobs (e.g., E2E)
- Minimal permissions: `contents: read`, `pull-requests: write`
- Set job timeouts: 5 min for fast jobs, 15 min for E2E
- Diagnosing failures: `gh run view <RUN_ID> --job <JOB_ID> --log-failed` — pipe through `tail -80`

## Use `docker login --password-stdin` instead of `-p` flag

Passing passwords via `docker login -p` exposes credentials in process listings (`ps aux`). Use `echo "$SECRET" | docker login --password-stdin` instead. This applies to any CI/CD pipeline or script that authenticates to a container registry.

## Cross-Refs

- `~/.claude/learnings/frontend/typescript-ci-gotchas.md` — pnpm/Node CI specifics (lockfile, Playwright caching, ESLint)
- `~/.claude/learnings/cicd/gitlab.md` — GitLab CI/CD patterns and debugging
