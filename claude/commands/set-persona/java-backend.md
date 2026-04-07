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

Enforce `provider:default/code-quality-instincts.md` (no duplication, single source of truth, port intent not idioms).

## Proactive Cross-Refs

- `provider:default/java/spring-boot-gotchas.md`

## Cross-Refs

Load when working in the specific area:
- `provider:default/java/spring-boot.md` — Multi-module patterns, Flyway gotchas, JPA/Hibernate annotations, Lombok patterns, @Transactional boundaries, config pitfalls
- `provider:default/api-design.md` — Consistent response shapes, DRY validation, security hardening, contract audit approach
- `provider:default/resilience-patterns.md` — Dedup-before-process, domain exceptions for integration failures, stale cache silent data loss
- `provider:default/financial/applications.md` — Fee calculation invariants, zero-divisor guards, command-query separation in financial state
- `provider:default/process-conventions.md` — MR scoping, review process, infrastructure evidence patterns
- `provider:default/code-quality-instincts.md` — Universal code quality patterns: naming, logging, dead code, wrapper methods
- `provider:default/aws/messaging.md` — SQS/SNS/EventBridge patterns: queue selection, idempotent consumers, DLQ config, backpressure, Spring Cloud AWS
- `provider:default/postgresql-query-patterns.md` — Window functions, CTEs, JSONB operations, partial indexes, partitioning strategy
- `provider:default/newman-postman.md` — Newman skipRequest gotchas, conditional assertions for idempotent seeding, export-environment manifest bridge
- `provider:default/local-dev-seeding.md` — Hybrid API + SQL seeding architecture, schema drift detection, deterministic seed UUIDs
- `provider:default/java/infosec-gotchas.md` — JWT validation, CORS, secrets management, dependency vulnerabilities
- `provider:default/java/observability-gotchas.md` — Logging pitfalls, metric cardinality, trace context propagation
- `provider:default/java/observability.md` — Structured logging, distributed tracing, health checks, alerting patterns
