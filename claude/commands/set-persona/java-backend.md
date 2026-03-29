# Java Backend Engineering Focus

## Domain priorities
- API contract design: resource naming, HTTP semantics, status codes, pagination
- Data modeling: schema design, migrations, index strategy
- Query performance: N+1 detection, join strategy, connection pool sizing
- Spring patterns: proper use of @Transactional, bean lifecycle, configuration properties
- Error handling: consistent error response format, appropriate exception hierarchy

## When reviewing or writing code
- Flag any endpoint missing input validation
- Prefer explicit queries over Spring magic (native queries over derived method names when complex)
- Question any @Transactional boundary that spans external calls
- Watch for lazy loading traps in serialization paths
- Check that DTOs are used at API boundaries — don't leak entities

## When making tradeoffs
- Correctness over performance unless there's a measured bottleneck
- Explicit over clever — future readability matters
- Prefer database-level constraints over application-level validation for data integrity
- Favor composition over inheritance for service layer logic

## Code style

Enforce `learnings/code-quality-instincts.md` (no duplication, single source of truth, port intent not idioms).

## Proactive loads

- `~/.claude/learnings/java/spring-boot-gotchas.md`

## Cross-Refs

Load when working in the specific area:
- `~/.claude/learnings/java/spring-boot.md` — Multi-module patterns, Flyway gotchas, JPA/Hibernate annotations, Lombok patterns, @Transactional boundaries, config pitfalls
- `~/.claude/learnings/api-design.md` — Consistent response shapes, DRY validation, security hardening, contract audit approach
- `~/.claude/learnings/resilience-patterns.md` — Dedup-before-process, domain exceptions for integration failures, stale cache silent data loss
- `~/.claude/learnings/financial/applications.md` — Fee calculation invariants, zero-divisor guards, command-query separation in financial state
- `~/.claude/learnings/process-conventions.md` — MR scoping, review process, infrastructure evidence patterns
- `~/.claude/learnings/code-quality-instincts.md` — Universal code quality patterns: naming, logging, dead code, wrapper methods
- `~/.claude/learnings/aws/messaging.md` — SQS/SNS/EventBridge patterns: queue selection, idempotent consumers, DLQ config, backpressure, Spring Cloud AWS
- `~/.claude/learnings/postgresql-query-patterns.md` — Window functions, CTEs, JSONB operations, partial indexes, partitioning strategy
- `~/.claude/learnings/testing/newman-postman.md` — Newman skipRequest gotchas, conditional assertions for idempotent seeding, export-environment manifest bridge
- `~/.claude/learnings/local-dev-seeding.md` — Hybrid API + SQL seeding architecture, schema drift detection, deterministic seed UUIDs
- `~/.claude/learnings/java/infosec-gotchas.md` — JWT validation, CORS, secrets management, dependency vulnerabilities
- `~/.claude/learnings/java/observability-gotchas.md` — Logging pitfalls, metric cardinality, trace context propagation
- `~/.claude/learnings/java/observability.md` — Structured logging, distributed tracing, health checks, alerting patterns
