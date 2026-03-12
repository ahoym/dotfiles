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

## Known gotchas & platform specifics

### Spring Boot
- `@Scheduled` + `@SchedulerLock` (ShedLock): swallow exceptions in the top-level method — Spring's TaskScheduler catches/logs anyway, ShedLock releases the lock regardless, and the job retries on next cron tick. Rethrowing just produces duplicate error logs.
- Inner loops processing independent items should catch per-item to prevent one failure from killing the batch

## Proactive loads

- `learnings/spring-boot.md`

## Detailed references

Load when working in the specific area:
- `learnings/spring-boot.md` — Multi-module patterns, Flyway gotchas, JPA/Hibernate annotations, Lombok patterns, @Transactional boundaries, config pitfalls
- `learnings/api-design.md` — Consistent response shapes, DRY validation, security hardening, contract audit approach
- `learnings/resilience-patterns.md` — Dedup-before-process, domain exceptions for integration failures, stale cache silent data loss
- `learnings/financial-applications.md` — Fee calculation invariants, zero-divisor guards, command-query separation in financial state
- `learnings/code-review-general.md` — Broad Java/Spring code review patterns: null safety, enum design, test structure, naming conventions
- `learnings/aws-messaging.md` — SQS/SNS/EventBridge patterns: queue selection, idempotent consumers, DLQ config, backpressure, Spring Cloud AWS
- `learnings/postgresql-query-patterns.md` — Window functions, CTEs, JSONB operations, partial indexes, partitioning strategy
- `learnings/local-dev-seeding.md` — Hybrid API+SQL seeding architecture, schema drift detection, deterministic seed UUIDs
- `learnings/newman-postman.md` — Newman skipRequest gotchas, conditional assertions for idempotent seeding, export-environment manifest bridge
