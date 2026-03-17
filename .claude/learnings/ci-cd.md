# CI/CD Patterns

## Docker Build and Push Must Share a CI Stage

Splitting `docker build` and `docker push` across separate CI stages fails silently — the push stage runs on a different runner instance that doesn't have the locally-built image. Build and push in the same job.

## Reusable Composite Actions for Shared CI Setup

When multiple CI jobs need the same environment (language runtime, package manager, native C libraries), extract setup into a composite action (e.g., `.github/actions/setup-env/action.yml`). Avoids duplicating 50+ lines across jobs and makes adding new jobs trivial.

- **Takeaway**: Shared CI environment setup = composite action, not copy-paste.

## CI Pipeline Structure: Lint-First with Dependency Chain

Structure CI as `lint -> test -> integration` via `needs:`. Lint runs first as a fast gate (seconds, not minutes). Tests only run if lint passes. Integration tests only on pushes to main (not on PRs) to avoid slow PR feedback. Add concurrency controls (`cancel-in-progress: true`) to cancel stale runs on the same branch.

- **Takeaway**: Fast gates first; integration tests on main only; cancel stale runs.

## Ruff Formatting Fixes Bundled with CI Setup

When adding a formatter check to CI (`ruff format --check`), expect a one-time batch of formatting-only changes in the same PR. This is a one-time cost that makes all future PRs pass cleanly.

- **Takeaway**: First-time formatter CI = expect a bulk formatting commit.

## See also

- `~/.claude/learnings/ci-cd-gotchas.md` — GitHub Actions and GitLab CI tripwires (companion)
