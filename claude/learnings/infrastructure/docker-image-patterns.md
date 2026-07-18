Docker image patterns — image ref grammar, WORKDIR vs relative paths, multi-service run, image disk reclaim.
- **Keywords:** image tag, repo:tag, repo-tag, GHCR, registry path, WORKDIR, relative path, CWD, configparser, docker run -d, --restart, detached, multi-service, docker rmi, dangling, shared layers, "0B reclaimed", multi-stage, COPY --from, flatten layer, build cache, builder prune, ldconfig, libta-lib, useradd, import gate, build-time smoke test, manylinux, libgomp, libgfortran, ARG, NONROOT_UID, COPY --chown, .dockerignore, templated secrets, bind-mount secrets, VirtioFS, gRPC-FUSE, bind-mount ownership, uid remap, container uid, 0600, sudo chown, macOS Docker Desktop, --network none, startup barrier marker
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

## `COPY --from=stage . .` flattens the whole stage into one layer — caching dies, runtime bloats

A final stage doing `COPY --from=build . .` squashes the entire build-stage rootfs (toolchain, apt caches, source, venv) into one monolithic layer. Two consequences:

- **No cross-build cache sharing.** That layer's cache key is the build stage's *full* rootfs content, so any earlier `COPY src src` invalidates it and every commit produces a fresh full-size cache record. N builds → N copies of ~the same layer; `docker system df` build cache balloons (routinely larger than the image total) while `builder prune -f` only trims the dangling tail. Symptom: many identical-sized (~hundreds of MB) cache records, one per build date.
- **Runtime bloat.** The squash drags `build-essential`/`gcc`/`git`/apt caches into the final image even on a slim base (worked example: 791MB → 265MB after the fix).

Fix — copy targeted paths as separate, reuse-ordered layers (stable first, volatile last):

```dockerfile
COPY --from=build /usr/local/lib/libfoo* /usr/local/lib/   # native libs: tiny, stable
RUN ldconfig
COPY --from=build /workspace/.venv /workspace/.venv         # deps: keyed on lockfile, shared across commits
COPY --from=build /workspace/src src                        # source: small, volatile, invalidates only itself
```

Per-build cache delta drops from one full layer to a few MB when deps are unchanged. Gotchas when replacing `COPY . .`: the slim base loses anything the squash brought across — recreate `useradd` users (no inherited `/etc/passwd`), copy native `.so`s explicitly + `ldconfig` (e.g. TA-Lib's `libta-lib.so` from `/usr/local/lib`), and confirm wheels don't need system libs the toolchain provided (`libgomp`/`libgfortran`). Smoke-test before pruning the old cache: `docker run --rm --entrypoint python <img> -c "import <native_ext>"`.

## Reviewing a multi-stage Dockerfile diff: the changed stage's deps live in stages not in the diff

A diff touching only the final stage shows `COPY --from=earlier-stage /path …` but not what `earlier-stage` produced. Diff-only reviewers (subagents told not to read the repo) can't judge whether the copy is complete or drops a runtime-needed artifact. Supply the full Dockerfile (or at least the referenced earlier stages) as inline review context — cheaper than granting repo read access when the missing context is small and known.

The check this unlocks: does the targeted copy reproduce everything the old `COPY . .` provided that runtime needs (native `.so`s, recreated users, transitive libs)? A selective copy that omits one is a build-green / deploy-crash latent bug — and an `import <one-ext>` smoke test doesn't prove the *rest* of the dependency tree resolves its own transitive libs.

## Bake a build-time import gate, not just a post-build smoke test

A `RUN python -c "import <full prod stack>"` placed after the `.venv` COPY fails the *build* if any native dep's transitive `.so` is missing from the slim base (numpy → `libgomp`/`libgfortran`/`libquadmath`; talib → `libta-lib.so`). manylinux wheels usually self-bundle these so it builds green today, but a future dep bump can ImportError at container start — the worst failure mode for a long-running service. Stronger than a manual `docker run --entrypoint python -c import` (fires only if someone runs it) and stronger than `import <one-ext>` (proves only that ext's libs). Two encoding rules:

- **Verify the import list against the actual lockfile, not the reviewer's guess.** A suggested `import talib, numpy, pandas, scipy` failed the build spuriously — `pandas`/`scipy` weren't dependencies. Read `pyproject.toml`/`uv.lock` and import exactly the prod set (mind import names: `schwab-py` → `schwab`, `ta-lib` → `talib`).
- **Exclude first-party modules.** Importing the entrypoint or its composition root (`config.accounts`) constructs broker/DB clients needing credentials absent at build time — chicken-and-egg. Gate on third-party libs only; they cover the native-`.so` risk.

The `RUN` is stable (changes only when the dep set changes) so it caches with the layers around it, and doubles as a check that the `libta*` copy + `ldconfig` resolved.

## `COPY --chown=<name>` needs the user to pre-exist; pre-`FROM` `ARG` for cross-stage uid SSOT

`COPY --from=… --chown=nonroot:nonroot src dst` resolves the name against the *current* stage's `/etc/passwd`, so `useradd` must run **before** the COPY (the recreated-user `useradd` is often written after the app copies — move it up). Setting ownership at copy time also drops a trailing `chown -R` metadata-rewrite layer. `useradd` is stable, so placing it before the volatile source copies preserves the reuse-ordering.

When the same `useradd -u 8877 nonroot` literal appears in two stages it drifts silently — bump one and the other's `chown name` still resolves (name is local) while cross-stage uid *ownership* diverges, surfacing only as a prod permission error. Hoist to one source: `ARG NONROOT_UID=8877` before the first `FROM`, then a bare `ARG NONROOT_UID` re-declared in each stage that uses `useradd -u ${NONROOT_UID}` (a pre-`FROM` ARG must be re-stated per stage to be usable in `RUN`). No `--build-arg` needed — the default applies, so build scripts that don't pass one still get the SSOT value.

## Templated secret files ship placeholders; `.dockerignore` mirrors `.gitignore` against a future broad COPY

A stage doing `COPY config/.env.template config/.env` ships the *renamed template* (placeholders), not real secrets — real ones are bind-mounted over the path at runtime. So `COPY --from=stage /workspace/config config` carrying `.env`/`*token.json`/`*limits.json` is safe **iff** the templates hold only placeholders: verify the committed `*.template` contents AND confirm the runtime mount from `docker-compose.yaml` volumes — don't assume either.

The latent risk is a *future* broad `COPY config config` sweeping real gitignored secrets from the build context into a layer (readable offline via `docker save`, regardless of `USER nonroot`). Defend cheaply with a `.dockerignore` whose globs mirror `.gitignore`'s secret patterns (`config/.env`, `config/*.env`, `config/*token.json`, `config/*limits.json`); the `*.template` files don't match, so current copies keep working.

## Bind-mount ownership: macOS VirtioFS remaps to the container uid; Linux/CI preserves host uid

A bind-mounted file appears with different ownership *inside* the container depending on the host's file-sharing layer:

- **macOS Docker Desktop (VirtioFS/gRPC-FUSE)** remaps the mount to the container's running uid. A host file `uid=501 mode=600` is seen inside a `USER 8877` container as `uid=8877 mode=600` — the container process reads it as-is.
- **Linux (native / CI ubuntu-latest)** preserves the host uid. The same file stays `uid=501`, so a `USER 8877` process gets `EACCES` on a `0600` file it doesn't own.

Consequence for a private-key-style secret (a token file an app refuses unless mode is `0600`, owner-only — e.g. `FileTokenStore` raising on `mode & 0o077`): on Linux the mounted file must be `chown`ed to the container's non-root uid, and giving a file to a *different* uid is privileged → needs `sudo`/root. On macOS that chown is a redundant no-op. A run/smoke script that chowns unconditionally (correct for CI) fires a spurious `sudo` prompt locally on a Mac.

Probe how a mount is presented inside — don't reason about it:
```bash
docker run --rm -v "$HOSTFILE:/f:ro" "$IMAGE" stat -c 'uid=%u mode=%a' /f
```

To run such a script sudo-free on macOS, neuter only the chown in a copy (`:` discards its args):
```bash
sed 's/sudo chown/: chown/' script.sh > /tmp/nosudo.sh
```
