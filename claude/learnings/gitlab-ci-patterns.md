Staged entries for enrichment of ~/.claude/learnings/gitlab-ci-patterns.md and ~/.claude/learnings/cicd/gitlab.md

---

### YAML anchors cannot cross GitLab CI included files -- use `!reference` tags

YAML anchors are resolved by the YAML parser before GitLab processes `include:` directives, so anchors defined in one file are invisible to other included files. Use `!reference [.rule-name, rules]` instead, which is resolved after all includes are merged into the final pipeline definition.

### `needs:` with `optional: true` prevents scheduling failures from skipped jobs

When a job listed in `needs:` is skipped due to `rules:`, the dependent job fails to schedule. Adding `optional: true` allows the dependent job to proceed without that dependency. Leave `optional` off for jobs that are always present -- it communicates intent.

### Scope CI artifact paths to reduce transfer overhead

Changing artifact paths from broad globs like `**/target/` to specific subdirectories (`classes/`, `test-classes/`, `*.jar`, `generated-sources/`) reduces artifact size significantly. Only include what downstream jobs actually need.

### Enable BuildKit and registry-based layer caching for Docker builds in CI

`DOCKER_BUILDKIT: "1"` enables `--cache-from` with registry images. Push a `:main` tag on the default branch, then use `--cache-from registry/image:main` with `BUILDKIT_INLINE_CACHE=1` build arg. Reduces rebuild time for layers that haven't changed.

### Cache downloaded binary tools in CI with SHA256 verification

Use a version-keyed GitLab CI cache entry for downloaded binaries. Verify integrity with `sha256sum --check --strict` before using. Check if the cached binary exists before downloading. Saves CI time and hardens against supply chain attacks on tool distribution.

### Use Maven `-pl` flag instead of `cd` + `mvn` for submodule builds

`mvn verify -pl adapters/${DIR}-adapters` from the project root avoids directory management errors and works correctly with `set -o pipefail`. Using `cd` into a submodule and running `mvn` there can miss parent POM settings and creates fragile directory-dependent scripts.

### Maven cache with branch-scoped keys and main fallback

`key: maven-${CI_COMMIT_REF_SLUG}` with `fallback_keys: [maven-main]` gives each branch its own cache while falling back to main for cold starts. Prevents cache poisoning between branches while avoiding full re-download on new branches.

### Split long-running CI test shards to reduce wall-clock time

Pipeline wall-clock time is determined by the slowest shard. Splitting the longest-running test shards improves overall pipeline duration more than optimizing fast shards. Profile shard durations periodically and rebalance.

### Parallelize docker-push with test stage using `needs:` DAG scheduling

`needs: ["maven-build"]` on the docker-push job starts it after build completes without waiting for tests to finish. The deployment gate still requires both docker-push and tests to pass. This shortens the critical path when build and test are independent.

### SonarQube quality gate wait is redundant when `allow_failure: true`

`sonar.qualitygate.wait=true` blocks the CI job until the quality gate resolves, but when the job has `allow_failure: true`, the result never gates the pipeline anyway. Remove the wait -- the quality gate still runs server-side. Also: use `GIT_DEPTH: 100` instead of `0` for SonarQube branch comparison to avoid full clone overhead.

### Global `timeout: 1h` default prevents hung CI jobs

Add `timeout: 1h` to the `default:` block in `.gitlab-ci.yml`. Without it, hung jobs block the pipeline indefinitely with no automatic cancellation. Individual jobs can override with shorter or longer timeouts as needed.

### Remove `-U` (force update snapshots) from CI Maven builds

`-U` forces Maven to check all remote repositories for snapshot updates on every build. In CI where the local repository cache is populated fresh, this adds network round-trips without benefit. Reserve `-U` for local development when you need to pull the latest snapshots.
