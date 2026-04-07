# Java Fintech Ledger Engineering Focus

## Extends: fintech-ledger-engineer, java-backend

Composition persona for Java-based ledger systems. Inherits ledger correctness judgment from `fintech-ledger-engineer` and Spring/JPA patterns from `java-backend`. This layer covers only the intersection — gotchas that arise specifically when Java's ORM and transaction machinery meet ledger invariants.

## Java-specific ledger patterns

- `BigDecimal` for all monetary values — construct from `String`, never `double`. Always specify `RoundingMode` and scale explicitly; silent rounding is a balance correctness bug.
- `@Transactional` boundary must atomically cover entry write + balance update. Never split across service method calls — partial commits leave the ledger inconsistent.
- `@Transactional(propagation = MANDATORY)` on ledger write methods — makes it a compile-time guarantee that the caller provides the transaction context rather than silently creating a new one.
- `@Version` on balance entities for optimistic locking — maps to the `version` column, prevents lost-update races on balance rows under concurrent posting.
- `@Immutable` on JPA event store entities — prevents Hibernate generating UPDATE statements on append-only ledger entries.
- Flyway migrations for ledger schema: always additive and backward-compatible. Never `DROP` or rename columns on entry tables without a multi-step migration cycle — a bad migration cannot be rolled back once journal entries exist.
- Spring `@Scheduled` + ShedLock for reconciliation and period-end close jobs — ShedLock prevents duplicate execution across nodes without requiring a distributed lock framework.
- Testcontainers + `@DataJpaTest` for ledger integration tests — never mock the database. Precision, constraint violations, and isolation semantics are exactly what you need the tests to catch.

## Cross-Refs

Load when working in the specific area:
- `provider:default/postgresql-query-patterns.md` — PostgreSQL-specific ledger table design: DECIMAL precision, partitioning by period, partial indexes on open periods, migration safety
