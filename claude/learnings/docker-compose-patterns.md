Docker Compose patterns: per-service logging overrides, plugin form, atomic-rename mount gotchas, filesystem-path migrations.
- **Keywords:** docker-compose, awslogs, cloudwatch, daemon.json, logging driver, multi-container, deploy, compose v1, compose v2, compose v5, plugin install, systemd, ExecStart, EBUSY, bind-mount, atomic rename, file vs directory mount, path migration, host filesystem
- **Related:** none

## Per-service `logging:` overrides global daemon.json

A service-level `logging:` block in `docker-compose.yaml` overrides Docker daemon's global default driver — including its `awslogs` config in `daemon.json`. Useful for multi-container rollouts where a new container needs a different log group from the existing one without touching the host's `daemon.json`.

```yaml
services:
  schwab:
    image: myapp
    # inherits daemon.json default → awslogs group "myapp-logs"
  tradestation:
    image: myapp
    logging:
      driver: awslogs
      options:
        awslogs-region: us-east-1
        awslogs-group: myapp/tradestation
        awslogs-stream: tradestation
```

**Principle:** prefer per-service `logging:` over editing `daemon.json` when adding new containers. Daemon edits force a Docker restart and affect every container; per-service config is local, reversible, and reviewable in the same PR as the new service.

## Compose v1 vs v2/v5: hyphen vs space, install paths

- `docker-compose` (hyphenated) → v1 standalone binary; **EOL upstream** (last release 2023). Lives at `/usr/bin/docker-compose` on legacy hosts.
- `docker compose` (space) → v2/v5 plugin form. Installed at `/usr/libexec/docker/cli-plugins/docker-compose` (system) or `~/.docker/cli-plugins/docker-compose` (user).
- The v5 release binary works in **both** forms: install at the plugin path AND symlink to `/usr/bin/docker-compose` so legacy callers keep working.
- Verify: `/usr/bin/docker-compose version` shows `v2.x` or `v5.x` if it's actually a v2+ binary mislabeled at the legacy path.

```bash
COMPOSE_VERSION=v5.1.3
DOCKER_CLI_PLUGINS=/usr/libexec/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o "$DOCKER_CLI_PLUGINS/docker-compose"
sudo chmod +x "$DOCKER_CLI_PLUGINS/docker-compose"
sudo ln -sf "$DOCKER_CLI_PLUGINS/docker-compose" /usr/bin/docker-compose  # back-compat
```

## systemd `ExecStart` with the compose plugin form

systemd parses `ExecStart=` as `<binary> <arg1> <arg2> ...` — first token is the binary, rest are args. So this works:

```ini
ExecStart=/usr/bin/docker compose -f /home/ec2-user/myapp/docker-compose.yaml up -d --remove-orphans
```

It runs `/usr/bin/docker` with args `["compose", "-f", "...", "up", "-d", "--remove-orphans"]` — the canonical plugin invocation. No wrapper script needed. Same pattern works for any plugin-extended CLI (`kubectl plugin-name ...`, `helm plugin-name ...`).

## Compose default + Python fail-loud is defense-in-depth, not redundancy

`environment: TS_ENV=${TS_ENV:-sim}` in compose + `os.environ["TS_ENV"]` (KeyError on missing) in Python aren't redundant. Compose provides the safe default for prod containers; the Python guard catches non-Docker contexts (test runs, manual invocation, dev shells) where the env var is absent. Both layers should agree on the *contract* (var must be set), not the *value* — Python doesn't need to default; compose doesn't need to fail-loud. Each layer covers a different execution context.

## Single-file bind-mount + atomic rename = EBUSY

`-v host/file:/ctn/file` causes `os.replace` / `rename(2)` targeting that file to fail with `OSError: [Errno 16] Device or resource busy` — the kernel can't swap inodes under an active mount. Symptom: code using `tempfile.mkstemp` + `os.replace` crashes the container on first state rotation (e.g. OAuth refresh ~20min in). `tmp_path` fixtures and single-boot smoke tests miss it — only a real rotation event under the file-bind-mount topology surfaces the bug.

Fix at two layers — keep both:

**1. Mount the parent directory + route the path via env var.** Atomic-rename works inside a directory-mount.
```yaml
environment:
  - TOKEN_PATH=/workspace/config/tokens/token.json
volumes:
  - "/host/tokens:/workspace/config/tokens"
```

**2. EBUSY fallback in the writer** as a safety net for deployer reverts to the old file-mount layout:
```python
import errno
try:
    os.replace(tmp, target)
except OSError as exc:
    if exc.errno != errno.EBUSY:
        raise
    with open(target, "w") as f:           # non-atomic — lost on mid-write SIGKILL
        json.dump(data, f); f.write("\n")
    os.unlink(tmp)
```

## Filesystem-path migrations have a deployment-side dependency

Migrating a canonical filesystem path inside the container (e.g. `read_x` falls back to a legacy path while `write_x` always targets the new one) is half a migration. The other half is the bind-mount — if hosts are still mounting the *legacy* path, writes hit the new path inside the container's writable layer and are silently lost on `--rm`. Reads still work via fallback, so unit tests, smoke tests, and dev runs all pass; only `docker run --rm` against a real state mutation surfaces the bug.

| Layer | Has to align |
|---|---|
| Code: `_canonical_path()` returns new form | ✓ |
| Code: read tries new, falls back to legacy (write must NOT fall back) | ✓ |
| Deploy: `docker-compose.yaml` bind-mount targets new form | ✓ — easy to forget |
| Deploy: host file exists at new path | ✓ — easy to forget |
| Deploy: legacy host file migrated/removed | optional but cleaner |

Before merging a path-migration PR, grep `docker-compose.yaml`, runbooks, terraform, and any `update_image_*.sh` scripts for the legacy filename and update each. Smoke check: `docker run --rm` the container, mutate state, exit, then re-mount and re-run — if the second run sees stale state, the mount and the canonical path disagree.

Symptom in stateful order-flow systems: action committed externally (broker fill, payment posted) and persisted in-container, `--rm` kills the container, host file still reflects pre-action state, next iteration sees stale state and re-runs the action → duplicate effect. Recovery: `docker cp` from a still-running container, or reconstruct from the external system of record.
