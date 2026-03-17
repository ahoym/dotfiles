# GitLab CI/CD Patterns

## Diagnosing GitLab CI Failures with glab

`glab api` provides full access to job metadata, logs, and artifacts for CI debugging:

```bash
# Job metadata (status, duration, commit, runner info)
glab api projects/<url-encoded-path>/jobs/<job-id>

# Job logs (full trace output)
glab api projects/<url-encoded-path>/jobs/<job-id>/trace

# Extract just the error section (traces can be 1MB+)
glab api projects/<url-encoded-path>/jobs/<job-id>/trace 2>&1 | grep -A 20 'BUILD FAILURE\|ERROR\|FAILED'
```

**Workflow for failing jobs:**
1. Fetch metadata → confirm status, stage, commit
2. Fetch trace → `tail -100` or grep for error patterns
3. Cross-reference with local code → read files, propose fix

URL-encode project paths: slashes become `%2F` (e.g., `group%2Fsubgroup%2Fproject`).

## GitLab API: MR Detail vs Changes Endpoints

`glab api "projects/:id/merge_requests/:iid"` returns `changes_count` (string) but NOT per-file diffs. For file-level diff data, use the `/changes` endpoint: `glab api "projects/:id/merge_requests/:iid/changes"`. The basic endpoint is cheap; `/changes` returns full diffs and is heavier.

## Shared CI Pipelines: Build-Only vs Docker-Capable Stages

Shared CI pipelines often split stages by capability — build-only stages (no Docker daemon) vs Docker-capable stages (DinD available). This determines where Testcontainers-dependent tests can run.

**Implication for tests:** Testcontainers tests must run in Docker-capable stages. In Maven projects:
- `*Tests.java` (Surefire, `mvn package`) → build-only stage, no Docker needed
- `*IT.java` (Failsafe, `mvn verify`) → Docker-capable stage, Testcontainers work here

```yaml
build:
  extends: .build-base  # No Docker daemon
  script:
    - mvn clean package -DskipITs=true  # Surefire only

integration-tests:
  extends: .docker-base  # DinD available
  script:
    - mvn verify -DskipUTs=true  # Failsafe only
```

## See also

- `~/.claude/learnings/ci-cd.md` — general CI/CD patterns (Docker staging, composite actions, lint-first pipelines)
- `~/.claude/learnings/ci-cd-gotchas.md` — GitHub Actions and GitLab CI tripwires (companion)
