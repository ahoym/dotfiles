Reusable GitHub Actions pipeline structures and patterns: composite actions, lint-first dependency chains, Docker build-push colocation, GitHub Actions configuration. Includes generic CI patterns (docker login, ruff divergence, rg/grep guards) most commonly encountered in GitHub Actions contexts.
- **Keywords:** Docker build push, composite action, lint gate, needs dependency chain, Ruff formatter, CI pipeline structure, cancel-in-progress, test gating, selective tests, latent bugs, iterative validation, GitHub Actions, paths-ignore, paths filter, job-level gate, changed files, git diff, fetch-depth, dorny/paths-filter, required status check, continue-on-error, job timeout, gh run view, docker login, password-stdin, container registry, credentials
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

## Stale CI Checks After PR Base Change

PR-targeted workflows filtered by `on.pull_request.branches: [main]` don't re-trigger when a PR's base is repointed to a different branch — the filter applies to the *new* base, so subsequent commits skip the workflow and the prior failed check stays red.

Clear it with `gh run rerun <run-id> --failed`. The rerun executes the same job, but runtime API calls (e.g., `gh api repos/.../pulls/N/files`) return the PR's *current* state — so a check that failed against the old base often passes against the new one without any code changes.

Diagnosis: compare the failed run's `headSha` and `createdAt` against `gh pr view <N> --json updatedAt,baseRefName`. If the PR was edited (base changed) after the run, the failure reflects a prior state.

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

## Skipping CI by Changed Paths: Trigger Filter vs Job-Level Gate

Two ways to run CI only when certain files (e.g. `.py`, not docs) change.

**Trigger-level `paths` / `paths-ignore`** — simplest; skips the *whole* workflow:
```yaml
on:
  pull_request:
    paths: ['**/*.py', 'pyproject.toml', 'uv.lock']
```
⚠️ **Required-check footgun:** a workflow skipped by a path filter never reports, and a *required* status check that never runs leaves the PR stuck ("Expected — waiting for status"), un-mergeable — GitHub treats "skipped by filter" and "not yet run" identically. Safe only when the check is **not required** (verify: `gh api repos/{owner}/{repo}/branches/main/protection` → `404 Branch not protected` = no required checks).

**Job-level gate** — keeps required-check semantics (workflow always triggers, so the check always reports). A `changes` job sets an output; downstream jobs gate on it:
```yaml
jobs:
  changes:
    outputs: { code: "${{ steps.f.outputs.code }}" }
    steps: [ ... id: f, sets code=true|false ... ]
  test:
    needs: [lint, changes]
    if: needs.changes.outputs.code == 'true'
```
A gated job that skips also skips its `needs:` dependents (`integration` → `needs: test` skips too — no separate gate needed).

**Key semantic:** an `if:` with **no status function** (`always()`/`success()`/`failure()`/`cancelled()`) still enforces `needs` success *on top of* the `if`. So `if: needs.changes.outputs.code == 'true'` still requires `lint` to pass — a lint failure keeps blocking `test`.

## Native `git diff` Change Detection (dorny/paths-filter Alternative)

Detect changed paths with pure git — no third-party action. The edge cases dorny abstracts and you now own:

```yaml
- uses: actions/checkout@v4
  with: { fetch-depth: 0 }          # default clone is shallow (depth 1) → diff fails
- id: f
  run: |
    if [ "${{ github.event_name }}" = "pull_request" ]; then
      # three-dot: only the PR's own changes since it diverged from base
      changed="$(git diff --name-only '${{ github.event.pull_request.base.sha }}...${{ github.event.pull_request.head.sha }}')"
    else
      base='${{ github.event.before }}'
      # all-zero base = new branch / first push → git diff errors; fail safe
      [ "$base" = "0000000000000000000000000000000000000000" ] && { echo "code=true" >> "$GITHUB_OUTPUT"; exit 0; }
      changed="$(git diff --name-only "$base" '${{ github.sha }}')"   # two-dot: this push's changes
    fi
    if printf '%s\n' "$changed" | grep -qE '(\.py$|^pyproject\.toml$|^\.github/)'; then
      echo "code=true" >> "$GITHUB_OUTPUT"; else echo "code=false" >> "$GITHUB_OUTPUT"; fi
```
- **`fetch-depth: 0`** — shallow default lacks the base commit.
- **three-dot for PRs** (diff vs merge-base = PR's own changes), **two-dot for push** (that push's changes); two-dot on a PR falsely flags files the base advanced past.
- **all-zero base guard** — first push reports `github.event.before` as 40 zeros.
- Include CI infra (`.github/**`) in the filter so a workflow/config edit still runs — the gating PR then validates itself.
- **grep-in-`if`**: GHA's default shell is `bash -eo pipefail`, so a no-match `grep` in a bare pipe fails the step; keeping it inside an `if` condition consumes the non-zero exit.

## Cross-Refs

- `~/.claude/learnings/frontend/typescript-ci-gotchas.md` — pnpm/Node CI specifics (lockfile, Playwright caching, ESLint)
- `~/.claude/learnings/cicd/gitlab.md` — GitLab CI/CD patterns and debugging
