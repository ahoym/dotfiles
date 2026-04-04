Docker security: credential handling in CI/CD and container builds.
- **Keywords:** docker login, password-stdin, container registry, CI/CD, credentials
- **Related:** ~/.claude/learnings/security.md

---

### Use `docker login --password-stdin` instead of `-p` flag

Passing passwords via `docker login -p` exposes credentials in process listings (`ps aux`). Use `echo "$SECRET" | docker login --password-stdin` instead. This applies to any CI/CD pipeline or script that authenticates to a container registry.
