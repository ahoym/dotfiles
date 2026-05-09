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

## Local-vs-remote ruff divergence

`uv run ruff check .` can report clean locally while CI fails on the same SHA. Causes observed: stale venv, worktree with a pre-populated `.venv` not resync'd after a `pyproject.toml` bump, different ruff version in the CI image. Don't treat local-clean as sufficient — CI is authoritative. If an addresser / commit loop is reporting local-clean but CI red, add a `uv sync --frozen` before `ruff check` or delete and recreate the venv.

## `rg`/`grep` + `|| true` + `pipefail` silently voids checks

`rg` and `grep` exit codes are 0 (match), 1 (no match), 2 (error). Under `set -euo pipefail`, you need `|| true` for the no-match case — but it absorbs error exits too. So `rg pattern files 2>/dev/null || true` reports clean when the pattern is absent AND when `rg` is missing, the path is wrong, or the binary segfaults.

Fix is **preflight + scoped suppression**, not blanket `|| true`:
```bash
command -v rg >/dev/null || { echo "rg not installed" >&2; exit 2; }
[[ -d "$ROOT" ]] || { echo "missing $ROOT" >&2; exit 2; }
matches=$(rg --no-config "$pattern" "$ROOT" || true)  # now || true is semantically correct: only no-match path remains
```

Also: ubuntu-latest GHA runners don't include `ripgrep`. `apt-get install` on those runners must precede with `apt-get update -q` — package cache age varies across image rotations and stale caches return 404 on `install`.

## GitHub Environments + OIDC `environment:` Claim Binding

Per-env CI/CD blast radius — bind GitHub Environments to AWS account boundaries via the OIDC subject claim:

```hcl
# Prod role's trust policy (in prod AWS account)
StringEquals = {
  "token.actions.githubusercontent.com:sub" = "repo:org/repo:environment:prod"
}
```

Workflow shape: `environment` input (`dev` | `prod`) selects which AWS role to assume AND which GitHub Environment to bind to. GitHub Environments configured with required-reviewer on prod → manual approval gate inside GitHub before deploy starts. Belt-and-suspenders to OIDC: even if the trust policy were misconfigured, the approval still blocks prod deploys.

Acceptance test: trust policy must reject runs claiming the wrong env. Test with `environment=dev` against the prod role and confirm `AssumeRoleWithWebIdentity` fails. Two trust-policy bugs to catch: wrong-repo (covered by `:sub` repo prefix) and wrong-env (covered by the `:environment:` segment).

Note: GitHub Environments are repo-settings, not Terraform-managed. Required-reviewer config lives in repo settings; document in the runbook.

## Cross-Refs

- `~/.claude/learnings/frontend/typescript-ci-gotchas.md` — pnpm/Node CI specifics (lockfile, Playwright caching, ESLint)
- `~/.claude/learnings/cicd/gitlab.md` — GitLab CI/CD patterns and debugging
