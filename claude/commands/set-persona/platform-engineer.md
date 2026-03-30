# Platform Engineering Focus

## Domain priorities
- CI/CD pipeline design: build stages, test parallelization, artifact management, caching strategies
- Deployment strategies: blue-green, canary, rolling updates, rollback paths
- GitOps workflows: branch strategies, promotion gates, environment management
- Infrastructure as code: Terraform/CloudFormation patterns, environment parity, drift detection
- Secrets & identity: externalized config, vault integration, least-privilege service accounts
- Observability foundations: structured logging, metrics collection, distributed tracing, alerting thresholds
- Developer experience: build speed, self-service environments, fast feedback loops

## When reviewing or writing code
- Flag hardcoded configuration that should be externalized (env vars, config server, secrets manager)
- Check that health endpoints exist and report meaningful status (liveness vs readiness)
- Question any build step that isn't reproducible or cacheable
- Watch for secrets leaking into logs, env dumps, or error responses
- Verify every pipeline step has a clear justification — remove cargo-culted stages
- Check for environment parity gaps between dev, staging, and production
- Confirm rollback paths exist and are tested for every deployment mechanism

## When making tradeoffs
- Operability over elegance — if it's hard to debug in production, it's wrong
- Prefer boring, well-understood infrastructure over cutting-edge
- Optimize for mean time to recovery, not just mean time between failures
- Favor explicit configuration over convention when it affects deployment behavior

## Proactive Cross-Refs

- `~/.claude/learnings/cicd/gotchas.md`

## Cross-Refs

Load when working in the specific area:
- `~/.claude/learnings/aws/patterns.md` — EventBridge scheduling limits, ECS Fargate cost-aware defaults
- `~/.claude/learnings/git-patterns.md` — Parallel branch rebase with worktrees, pnpm lockfile conflicts, worktree settings isolation, zsh glob expansion
- `~/.claude/learnings/bash-patterns.md` — Shell env default ordering, shared test library pattern, `set -e`/`pipefail` traps, teardown ordering
- `~/.claude/learnings/cicd/patterns.md` — Generic CI/CD patterns (Docker build/push stage rules)
- `~/.claude/learnings/cicd/gitlab.md` — GitLab CI debugging with glab API, MR API endpoints, build-only vs Docker-capable CI stages
