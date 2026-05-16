Docker image patterns — image ref grammar, WORKDIR vs relative paths, multi-service run, image disk reclaim.
- **Keywords:** image tag, repo:tag, repo-tag, GHCR, registry path, WORKDIR, relative path, CWD, configparser, docker run -d, --restart, detached, multi-service, docker rmi, dangling, shared layers, "0B reclaimed"
- **Related:** none

## `:` is the only tag separator — `repo-<hash>` creates N repositories

OCI grammar is `[registry/]repository[:tag][@digest]`. The colon is the *only* token Docker parses as a tag separator. `ghcr.io/org/foo-<hash>` is one *repository path* with implicit `:latest`; `ghcr.io/org/foo:<hash>` is repo `foo` with tag `<hash>`.

The dash form looks superficially like versioning but breaks every tag-aware affordance:

| Operation | `repo:tag` form | `repo-<hash>` form |
|---|---|---|
| `docker images foo` lists all versions | ✓ | ✗ (each version is a different repo) |
| Retention policy / vulnerability scan attaches per repo | One target, many tags | Fragmented across N one-tag repos |
| Rollback alias (`:stable`, `:latest`) | Cheap | Requires re-tag-and-push per alias |
| Compose `image: foo:${TAG}` resolves | ✓ | ✗ (different repo path) |

If you see a publish script doing `BASE-$(git rev-parse HEAD)` as the *repository* path with no explicit tag, that's the bug. Fix:

```bash
docker build -t "$BASE:$HASH" -f ... .
docker tag "$BASE:$HASH" "$REGISTRY/$NAMESPACE/$BASE:$HASH"
docker push "$REGISTRY/$NAMESPACE/$BASE:$HASH"
```

Pre-existing dash-form repos on the registry are orphans after the fix; cleanup is optional. Compose, runbook docs, and any retag-aware code must be updated together — a half-migrated state where publish uses `:` but compose still expects `-` resolves to nothing on pull.

## WORKDIR drives relative-path resolution for in-container code

Container code using relative paths (e.g. `configparser.ConfigParser().read("config/.env")`) resolves against the process CWD, which is the Dockerfile's `WORKDIR`. Two images reading the same relative path with different WORKDIRs read different files. Symptom: bind-mount appears correct, but the app raises a KeyError or missing-section error on data that *is* in the mounted file because the app is reading a different file entirely.

```
# Image A: WORKDIR /workspace → reads /workspace/config/.env
# Image B: WORKDIR /opt       → reads /opt/config/.env

# Bind-mount: -v host/cfg:/workspace/config/.env
# Effective in Image A: ✓
# Effective in Image B: ✗ — image reads /opt/config/.env, mount is a no-op
```

Fix is in the Dockerfile, not the caller — align WORKDIR across images that share calling conventions (run scripts, compose mount targets). Don't fix by adjusting the mount target per image; that fragments runbook commands.

`COPY config config` with a missing `config/.env` in the build context (gitignored credentials file) bakes nothing at `/opt/config/.env`; the app then sees an empty file (or a stale one from build context) instead of the mounted file. The KeyError is the loudest symptom of WORKDIR mismatch.

## Multi-service `docker run` needs `-d`; foreground blocks the chain

`docker run -i -t image` attaches the caller's stdin/stdout and blocks until the container exits. Chaining a second `docker run` after it in a script means the second never starts unless the first is killed. For multi-service runtime managed by a single script:

```bash
docker run -d --restart unless-stopped --name svc-a ... image     # detached
docker run -d --restart unless-stopped --name svc-b ... image     # also detached
docker ps                                                         # confirm both up
```

`--rm` is incompatible with `--restart` (Docker rejects it) — `--rm` for one-shot interactive testing, `--restart` for long-running services. Mixing `-i -t` with `-d` is legal but pointless; `-d` already detaches, the `-i -t` are no-ops.

Compose handles this natively (every service is detached by default), so legacy `docker run`-based update scripts that grew from a single-service era often need this fix when extended to a second service.

## `docker rmi` reports "0B reclaimed" when removing shared-layer refs

After `docker image prune -f` or `docker rmi <id>` on dangling images that share layers with tagged ones, Docker prints:

```
Total reclaimed space: 0B
```

This is misleading. Disk wasn't freed *by this command* because the underlying layer blobs are still referenced by tagged images. The dangling refs got *untagged* (the goal), and disk frees later when the last reference goes. The actual disk delta is visible via `docker system df` before/after a sequence of cleanups.

Counter-example where you *do* see real reclaim: removing the last reference to an image with unique layers (e.g., a stale tagged build from months ago that doesn't share with anything current). Then `Total reclaimed` matches the image size.

Useful pattern: chain cleanup steps and only check `docker system df` at the end, not per-step:

```bash
# Remove a known cruft pattern (e.g., one-repo-per-commit orphans)
docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^repo-[a-f0-9]+:' | xargs docker rmi
# Then dangling
docker image prune -f
# Finally measure
docker system df
```

## `--entrypoint <interpreter>` smoke-tests config-dependent containers

To verify a bind-mounted config or env file reaches the right path *without* triggering the image's default entrypoint (long-running service, OAuth flow, etc.):

```bash
docker run --rm \
  -v "$PWD/config:/workspace/config" \
  --entrypoint python \
  "$IMAGE" -c "import configparser; c=configparser.ConfigParser(); c.read('config/.env'); print(c.sections())"
```

`--entrypoint` overrides the Dockerfile's `ENTRYPOINT` for one invocation. The image's `CMD` becomes args to the new entrypoint, so `-c "..."` runs an inline probe. Works for any interpreter (`python`, `node`, `ruby`, `sh`). Pairs with the WORKDIR pattern above — the probe path is WORKDIR-relative, so this validates the mount target *and* the WORKDIR resolution together.
