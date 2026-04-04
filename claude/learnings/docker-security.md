Staged entries for new category (no existing file covers Docker security specifically; closest is java/infosec-gotchas.md but that's Java-scoped)

---

### Use `docker login --password-stdin` instead of `-p` flag

Passing passwords via `docker login -p` exposes credentials in process listings (`ps aux`). Use `echo "$SECRET" | docker login --password-stdin` instead. This applies to any CI/CD pipeline or script that authenticates to a container registry.
