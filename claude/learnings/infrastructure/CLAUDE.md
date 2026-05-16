Infrastructure and deployment patterns: container runtime, orchestration, networking, infrastructure-as-code.

| File | When to read |
|------|-------------|
| docker-image-patterns.md | Docker images: `repo:tag` vs `repo-<hash>` grammar, WORKDIR vs relative paths, multi-service `docker run -d`, disk reclaim semantics |
| docker-compose-patterns.md | Docker Compose: per-service `logging:`, plugin form, EBUSY on file bind-mounts, path-migration mounts, bind-mount perm inheritance |
| kubernetes-helm-patterns.md | Helm: bootstrapping apps from templates, prometheusrule boilerplate gotcha |
| nginx-patterns.md | nginx: alias+try_files SPA routing, add_header inheritance in named locations, Vite base path, proxy_pass trailing slash |
| terraform-patterns.md | Terraform: fallback-source `count` gating, `templatefile()` secret exposure, `lifecycle { ignore_changes }` recovery, `prevent_destroy` literal constraint, ephemeral-env teardown, agent-driven IaC account boundary, PR verification ladder |
