# Learnings Index

Read this file when starting domain-relevant work. For clusters, read the cluster's CLAUDE.md to discover individual files.

Read `~/.claude/learnings-providers.json` to discover all provider directories. For each provider, check if its `localPath`'s `CLAUDE.md` exists and read it.
If `docs/learnings/CLAUDE.md` exists in the current project, read it for repo-local learnings.

---

## Clusters

- `claude-authoring/CLAUDE.md` — Authoring skills, guidelines, learnings, personas, and CLAUDE.md files
- `claude-code/CLAUDE.md` — Claude Code platform mechanics, agent infrastructure, orchestration
- `xrpl/CLAUDE.md` — XRPL integration: orderbook, AMM, cross-currency payments, DEX data
- `java/CLAUDE.md` — Java/JVM: Spring Boot, Quarkus/Kotlin, observability, security
- `frontend/CLAUDE.md` — React 19, Next.js, TypeScript, UI components, accessibility
- `aws/CLAUDE.md` — AWS infrastructure: EventBridge, SQS/SNS, Lambda
- `cicd/CLAUDE.md` — CI/CD: GitHub Actions, GitLab CI, pipeline patterns
- `financial/CLAUDE.md` — Financial/ledger engineering: monetary calculations, architecture, accounting
- `testing/CLAUDE.md` — Testing: Vitest, React Testing Library, Playwright E2E, Newman/Postman

## Database

- `postgresql-query-patterns.md` — PostgreSQL: window functions, CTEs, JSONB, indexing, schema design, migration safety
- `local-dev-seeding.md` — Local dev seeding: hybrid API + SQL architecture for repeatable test data

## Deployment

- `vercel-deployment.md` — Vercel: cron job limits, Postgres (Neon), environment variables

## General Engineering

- `api-design.md` — API design: consistent response shapes, versioning, error contracts
- `code-quality-instincts.md` — Fundamental code quality practices across all languages
- `refactoring-patterns.md` — Refactoring: survey before acting, scope discipline
- `git-patterns.md` — Git: rebase, worktree, commit hygiene, branch management
- `git-github-api.md` — GitHub API: pagination, reviews endpoint, stacked PRs, cascade rebase
- `review-conventions.md` — Code review: self-review, comment etiquette, LGTM, structured footnotes
- `bash-patterns.md` — Bash: shell env default ordering, quoting gotchas
- `python-specific.md` — Python: Pydantic v2 optional fields, serialization
- `resilience-patterns.md` — Resilience: idempotent processing, reprocessing loop prevention
- `reactive-data-patterns.md` — Reactive data patterns for real-time UIs: background refresh, resource validation
- `process-conventions.md` — Engineering process conventions: scoping, tracking, work organization
