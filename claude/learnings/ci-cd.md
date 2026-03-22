Reusable CI pipeline structures including composite actions, lint-first dependency chains, and Docker build-push colocation.
- **Keywords:** Docker build push, composite action, lint gate, needs dependency chain, Ruff formatter, CI pipeline structure, cancel-in-progress
- **Related:** ci-cd-gotchas.md, gitlab-ci-cd.md, typescript-ci-gotchas.md

---

## Docker Build and Push Must Share a CI Stage

Splitting `docker build` and `docker push` across separate CI stages fails silently — the push stage runs on a different runner instance that doesn't have the locally-built image. Build and push in the same job.

## Reusable Composite Actions for Shared CI Setup

When multiple CI jobs need the same environment (language runtime, package manager, native C libraries), extract setup into a composite action (e.g., `.github/actions/setup-env/action.yml`). Avoids duplicating 50+ lines across jobs and makes adding new jobs trivial.

## CI Pipeline Structure: Lint-First with Dependency Chain

Structure CI as `lint -> test -> integration` via `needs:`. Lint runs first as a fast gate (seconds, not minutes). Tests only run if lint passes. Integration tests only on pushes to main (not on PRs) to avoid slow PR feedback. Add concurrency controls (`cancel-in-progress: true`) to cancel stale runs on the same branch.

## Ruff Formatting Fixes Bundled with CI Setup

When adding a formatter check to CI (`ruff format --check`), expect a one-time batch of formatting-only changes in the same PR. This is a one-time cost that makes all future PRs pass cleanly.

## Cross-Refs

- `~/.claude/learnings/ci-cd-gotchas.md` — GitHub Actions and GitLab CI tripwires (companion)
- `~/.claude/learnings/gitlab-ci-cd.md` — GitLab-specific CI patterns (glab debugging, DinD stages, MR API)
- `~/.claude/learnings/typescript-ci-gotchas.md` — pnpm/Node CI specifics (lockfile, Playwright caching, ESLint)
