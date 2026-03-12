# CI/CD Gotchas

GitHub Actions and GitLab CI tripwires.

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

## Git Workflows

- Cascade rebase for stacked branches: `checkout -B` resets local to remote, then rebase on updated base; `--force-with-lease` for safe push
- After rebasing stacked branches, retarget MRs: `glab mr update <N> --target-branch <new-base>`

## CI Guards

- Lightweight CI guard (no checkout): API calls + `jq` to check blocked file paths — runs in seconds with no dependencies beyond `curl` and `jq`
