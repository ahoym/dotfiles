GitLab-specific CI/CD patterns — `glab` CLI debugging, MR API endpoints, shared pipeline stage splitting, configuration gotchas, and CI guards.
- **Keywords:** GitLab, glab, CI/CD, job trace, merge request, DinD, Testcontainers, Surefire, Failsafe, glab api, pipeline stages, rules, cache, artifacts, interruptible, needs, DAG, glab issue create, file-based description, single quotes, permission prompts
- **Related:** none

---

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

## Configuration Patterns

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

Lightweight CI guard (no checkout): API calls + `jq` to check for blocked file paths — runs in seconds with no dependencies beyond `curl` and `jq`.

## glab CLI Flag Differences from gh

- `glab mr create` uses `--description`, not `--body`. `--body` is the `gh` (GitHub CLI) flag — `glab` rejects it as an unknown flag.
- `glab mr list --all` shows all states (open/merged/closed). There is no `--state` flag — use `--all` or no flag (defaults to open).
- `glab mr diff` has no `--name-only` flag. Extract filenames from raw diff: `glab mr diff <N> --raw | grep '^diff --git' | sed 's|diff --git a/.* b/||'`.
- `glab api` has no built-in `--jq` flag (unlike `gh api`). Pipe output to the standalone `jq` CLI: `glab api projects/:id/merge_requests/<N>/commits | jq '.[] | {sha: .short_id}'`.

## Shell Script Wrapper for glab API Calls

When posting multiple `glab api graphql` calls that need command substitution (e.g., `jq -Rs` to escape file content for GraphQL body parameters), write a `.sh` script and run `bash script.sh` instead of inline `$()`. The `$()` subshell triggers Claude Code permission prompts on every invocation, forcing manual approval. A script file executes all substitutions internally with a single permission prompt.

```bash
# Instead of this (prompts on every $() ):
BODY=$(cat file.md | jq -Rs .) && glab api graphql -f query="..."

# Write a script that does the same, then:
bash tmp/change-request-replies/post-review.sh  # Single prompt
```

Applies to all review/comment skills that post via GitLab GraphQL (`createDiffNote`, etc.) or use `-F body=@` with `jq`-processed content.

## `glab api graphql`: File-Based Variables for Inline Diff Comments

Use GraphQL variables with file-based values to avoid shell escaping when posting inline comments. Write the comment body to a file, write a reusable `.graphql` mutation template, then pass variables via flags:

```bash
glab api graphql \
  -F query=@tmp/createDiffNote.graphql \
  -F body=@tmp/comment-body.md \
  -f noteableId=gid://gitlab/MergeRequest/<mr_id> \
  -f baseSha=<sha> -f headSha=<sha> -f startSha=<sha> \
  -f oldPath=<path> -f newPath=<path> \
  -F newLine=<line>
```

**Critical: `-F` vs `-f` semantics.** `-F` (field) expands `@filename` to file contents and infers types (integers, booleans). `-f` (raw-field) sends the literal string — `@filename` becomes the text `@filename`. Use `-F` for file reads (`query`, `body`) and integers (`newLine`). Use `-f` for plain strings (SHAs, paths, IDs).

For GraphQL, all fields except `query` and `operationName` are automatically mapped to GraphQL variables — no separate `variables` JSON needed.

## GitLab API: Individual Discussion GET Returns 404

`GET projects/:id/merge_requests/:iid/discussions/:discussion_id` returns 404 even with valid discussion IDs from the paginated list endpoint. Use the bulk `discussions --paginate` endpoint and filter client-side with jq instead of fetching individual discussions.

```bash
# This 404s:
glab api projects/:id/merge_requests/27/discussions/<sha-id>

# This works — filter from bulk:
glab api projects/:id/merge_requests/27/discussions --paginate | jq '.[] | select(.id == "<sha-id>")'
```

## `glab api -f` Does NOT Create Nested JSON Objects

Bracket notation like `-f "position[new_line]=411"` sends flat JSON keys (`"position[new_line]": "411"`) — GitLab ignores these and creates a general note instead of an inline DiffNote. For any API call requiring nested objects (inline comments with position data), use GraphQL `createDiffNote` instead. This does NOT affect `-f` for flat string parameters (e.g., `-f sort=desc`), which work correctly.

## Inline Diff Comments Require GraphQL `createDiffNote`

The REST notes API cannot create inline diff comments with correct positioning. Use the GraphQL `createDiffNote` mutation instead:
- Line numbers are 1-indexed; off-by-one causes **silent rejections** (comment posts as general note, no error)
- Body escaping for GraphQL string literals requires `\"` and `\n` handling
- `oldLine`/`newLine` logic: removed lines use oldLine only, context lines use both, new lines use newLine only

## Editing MR Notes via REST API

`PUT projects/:id/merge_requests/:iid/notes/:note_id` with `-f body=<new content>` replaces a note's body. Works for both inline (DiffNote) and top-level notes. Useful for adding missing footnotes or correcting replies after posting.

## GitLab Emoji Reactions: Stick to Cross-Platform Names

GitLab and GitHub use different emoji names for the same intent. Unrecognized names silently fail — no error, no reaction, and downstream logic (e.g., mutual resolution detection) breaks without warning. Use only cross-platform names: `rocket` (resolved), `thumbsup`/`thumbsdown` (acknowledged/disapproval). Avoid `hooray` (GitHub-only) and `+1`/`-1` (GitHub aliases that fail on GitLab).

## Repointing MR Target Branches

Repoint an MR's target branch (e.g., for stacked MR chains):

```bash
glab mr update <MR_ID> --target-branch <branch-name>
```

## `glab api` Query Params Need Single Quotes in Zsh

URLs with `&` must be single-quoted — zsh interprets unquoted `&` as a background operator:

```bash
# Wrong — zsh backgrounds the command at &
glab api projects/:id/merge_requests/17/notes?sort=desc&per_page=100

# Right
glab api 'projects/:id/merge_requests/17/notes?sort=desc&per_page=100'
```

## Reading Plan Docs Added in an MR

`glab mr diff` outputs unified diff with context lines. To read only added content (e.g. a plan document added in an MR):

```bash
glab mr diff <N> 2>&1 | grep "^+" | head -300
```

To extract a specific section from added content:

```bash
glab mr diff <N> 2>&1 | grep "^+" | sed -n '/Section Header/,/Next Section/p'
```

## `glab issue create` Has No File-Based Description Flag

`glab issue create -d` accepts inline text only — no `@file` support. For descriptions stored in files (avoiding `$()` permission prompts), use the REST API directly:

```bash
glab api projects/:id/issues -X POST \
  -f 'title=Issue title here' \
  -F description=@path/to/description.md \
  -f labels=tech-debt
```

`-F description=@file` reads the file; `-f title=` and `-f labels=` pass literal strings. Single-quote `-f` values containing spaces to avoid backslash-escape permission prompts.

## Single-Quote `-f` String Values with Spaces

Backslash-escaping spaces (`-f title=Foo\ Bar`) triggers permission prompts per escaped character. Single quotes avoid this:

```bash
# Prompts on every escaped space:
glab api projects/:id/issues -X POST -f title=Consolidate\ Config\ Pattern

# Single prompt:
glab api projects/:id/issues -X POST -f 'title=Consolidate Config Pattern'
```

## Cross-Refs

None — intra-cluster refs handled by cluster index.
