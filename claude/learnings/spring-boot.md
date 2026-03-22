# Spring Boot

Spring Boot patterns covering JPA/Hibernate, Flyway migrations, PostgreSQL enums, Jackson DTOs, multi-module builds, and test conventions.
- **Keywords:** Spring Boot, JPA, Hibernate, Flyway, PostgreSQL, Mockito, Lombok, @Builder.Default, @Transactional, @UuidGenerator, @PostConstruct, Jackson, @NoArgsConstructor, H2, Testcontainers, VARCHAR CHECK constraint, multi-module, init container
- **Related:** spring-boot-gotchas.md, postgresql-query-patterns.md

---

### Mockito 5+ (Spring Boot 3.5.x): Drop mockito-inline

Spring Boot 3.5.x uses Mockito 5+ which includes inline mocking in `mockito-core` by default. The separate `mockito-inline` artifact is unnecessary and will fail to resolve if the parent BOM no longer manages its version. Safe to remove -- `MockedStatic` and static mocking still work via `mockito-core`.

### Multi-Module: spring-boot:run from Parent POM

`mvn -pl <module> -am spring-boot:run` from a multi-module parent POM fails with "Unable to find a suitable main class" because the plugin runs on the parent first. Workaround: build with `mvn package -DskipTests`, then start directly with `java -jar <module>/target/<artifact>.jar --spring.profiles.active=<profile>`.

### List Property Indexing Must Start at 0 and Be Contiguous

Spring Boot list properties (e.g., `wallets[0].address`, `wallets[1].address`) must start at index 0 with no gaps. Starting at [1] or having a gap (e.g., jumping from [3] to [5]) causes Spring Boot to silently drop entries -- no startup error, just missing data at runtime. Each indexed entry requires all its sub-properties at the same index.

### Flyway Migration Filenames Require Uppercase V Prefix

Lowercase `v001__init.sql` is silently ignored by Flyway. Must be `V001__init.sql` (uppercase V). No error, no warning -- the migration simply doesn't execute. Verify migrations ran by checking the `flyway_schema_history` table.

### Avoid Mixing application.properties and application.yml

Spring Boot will merge both formats if both exist, but precedence rules are non-obvious and can lead to subtle configuration conflicts. Pick one config format and use it consistently across the project.

### JPA @CreationTimestamp/@UpdateTimestamp as Timestamp Source of Truth

Use JPA lifecycle annotations as the authoritative timestamp management layer, not DB triggers. JPA annotations are testable and visible in application code. If DB triggers exist for defense-in-depth, document clearly which layer is authoritative.

### Indexes in Migrations, Not JPA Annotations

@Index annotations on JPA entities are redundant when indexes are defined in Flyway migrations. Migration SQL is the authoritative source for schema objects. JPA @Index can create conflicts if the generated DDL doesn't match the migration-defined index exactly.

### @Builder.Default Required for insertable=false Columns

DB-defaulted columns marked with `insertable=false, updatable=false` in JPA still need Java-side defaults via `@Builder.Default` for Lombok builders. Without it, builders leave these fields null, causing test failures or unexpected behavior in non-persistence contexts.

### @Enumerated + PostgreSQLEnumJdbcType for PostgreSQL Enums

Standard pattern for type-safe PostgreSQL enum columns in JPA entities. Combines `@Enumerated(EnumType.STRING)` with Hibernate's `PostgreSQLEnumJdbcType` for proper JDBC type mapping.

### JPA Repository Generic Type Must Match Entity ID Type

`JpaRepository<Entity, Long>` when the entity uses `UUID` as its ID type causes runtime errors, not compile-time errors. The generic type parameter is erased at compile time, so the mismatch only surfaces when Spring Data tries to generate query implementations at startup or when certain repository methods are invoked. For entities with `@IdClass(CompositeKeyClass.class)`, the second generic parameter must be the composite key class, not `UUID`.

### Flyway Migrations Must Not Be Modified After Deployment

Modifying the content of an already-applied Flyway migration causes checksum mismatches (FlywayValidateException). Once a migration is applied to any environment, it is immutable -- fixes must go in new migration versions.

### PostgreSQL Views Must Be Dropped Before Altering Their Dependent Columns

When adding or modifying a column on a table that has dependent views, PostgreSQL will fail the ALTER. Same migration: DROP VIEW IF EXISTS, ALTER TABLE, CREATE OR REPLACE VIEW -- keeps them atomic in sequence.

### ResponseEntityExceptionHandler: only extend when handling Spring MVC built-in exceptions

Don't extend `ResponseEntityExceptionHandler` in a `@RestControllerAdvice` that only handles application-level exceptions. That base class is designed for Spring MVC's built-in exceptions (MethodArgumentNotValidException, etc.) and adds unnecessary complexity when your handler only deals with custom domain exceptions.

### saveAndFlush in loops creates partial-commit risks

Using `saveAndFlush` inside a processing loop means earlier iterations are already committed if a later iteration fails, leaving inconsistent state. Use save() in loops with a single flush/commit, or @Transactional on the enclosing method.

### Jackson DTOs need @NoArgsConstructor alongside @AllArgsConstructor

Jackson requires a default no-arg constructor for deserialization. When using Lombok's `@AllArgsConstructor`, Jackson can't instantiate the object without also having `@NoArgsConstructor`. Lombok DTO pattern: @Data + @NoArgsConstructor + @AllArgsConstructor (or @Builder with @NoArgsConstructor).

### @JsonProperty annotations must be applied consistently across all DTO fields

Inconsistent `@JsonProperty` annotation means some fields get explicit JSON name mapping while others rely on Jackson's default naming strategy. If the default strategy diverges from the explicit names (e.g., snake_case vs camelCase), some fields silently fail to deserialize. Either annotate all fields or none.

### Database Migrations That Change FK Targets Require Data Consistency Verification

When altering a foreign key to reference a different column (e.g., code -> name), existing data in the referencing column must already match the new target column's values. Otherwise the migration fails at constraint creation time.

### Case sensitivity in Sort.Direction validation

`Sort.Direction.fromString()` is case-insensitive in Spring, but custom validation may check lowercase while conversion expects uppercase. Normalize before both validation and conversion operations to avoid mismatches.

### JPA entities need no-arg constructors when using Lombok @Data + @AllArgsConstructor

`@Data` + `@AllArgsConstructor` without `@NoArgsConstructor` removes the default constructor JPA/Hibernate requires for entity instantiation. Always pair with `@NoArgsConstructor`.

### Spring MVC path collision: UUID path variables shadow sibling sub-resource paths

When `/{id}` is at the same level as `/webhooks` or `/partners`, Spring gives precedence to path variable match. Fix: rename the parent path to give each resource its own unambiguous namespace.

### Separate @Transactional boundaries to avoid stale reads in polling loops

When a method both saves and re-reads entities, a single `@Transactional` prevents seeing fresh data (reads return the cached version from the persistence context). Extract saving logic into a separate service with its own `@Transactional` boundary.

### @UuidGenerator on entities with application-assigned IDs causes silent overwrites

Hibernate `@UuidGenerator` silently overwrites application-assigned IDs. If application code sets IDs via `UUID.randomUUID()`, remove `@UuidGenerator`. The annotation always generates a new UUID, ignoring any value already set on the field.

### @PostConstruct + singleton = stale reference data anti-pattern

When a `@Component` singleton loads DB-backed reference data in `@PostConstruct`, that data is frozen for the pod's lifetime. New reference data (currencies, networks, assets) added to the DB after startup is invisible. Fix options: per-call fresh lookup, `@Cacheable` with TTL, or `@RefreshScope`.

### Residual annotations after refactoring

After changing from DI-managed to manual construction (or vice versa), check for leftover `@Component`, `@PostConstruct`, `@Autowired` annotations that no longer serve a purpose. Residual annotations are a code smell after refactors and confuse readers about the class's lifecycle.

### Multi-module Flyway init container pattern

In multi-module Spring Boot services with K8s deployment, Flyway migrations live in a dedicated init module (e.g., `*-service-init`) that runs as a K8s init container before the server starts. The server module uses `spring.jpa.hibernate.ddl-auto=validate` and does NOT have Flyway on its classpath. This separation ensures multi-replica safety -- only the init container races on the migration lock. For tests in the server module, add Flyway as a test-scoped dependency and duplicate migration SQL in `src/test/resources/db/migration/`.

### PostgreSQL CREATE TYPE ... AS ENUM breaks H2 tests

H2 does not support PostgreSQL's `CREATE TYPE name AS ENUM (...)` syntax. When using PostgreSQL enum types in migrations, H2 is not viable for integration tests — use Testcontainers with PostgreSQL instead.

### VARCHAR + CHECK Constraint > PG ENUM Type for Migration Safety

`ALTER TYPE ... ADD VALUE` cannot run inside a transaction in PostgreSQL, making enum evolution painful — especially with Flyway which wraps each migration in a transaction by default. Using `VARCHAR` columns with `CHECK (column IN ('VAL1', 'VAL2'))` constraints provides equivalent DB-level validation without the migration headache. Adding a new value is a simple `ALTER TABLE ... DROP CONSTRAINT ... ADD CONSTRAINT` which is fully transactional.

### Enum.valueOf() is unsafe for DB-sourced values

Database values may not match Java enum constants (case differences, new values added to DB but not code, typos). Use a safe lookup pattern -- `Arrays.stream(values()).filter(...)` with a fallback or `Optional` -- instead of raw `Enum.valueOf()` which throws `IllegalArgumentException` with no context.

### Mutable Domain Entities Should Be Classes, Not Records

Records/data classes are for immutable value objects. Domain entities with changing state (status transitions, accumulated collections) should be regular classes.

### Secrets in Properties Files

Hardcoded tokens/secrets in `application.properties` are a recurring review issue. Use `${ENV_VAR}` syntax in committed files and `application-local.properties` (gitignored) for actual values. Consider pre-commit hooks or CI checks for literal tokens.

### Cross-Reference JPA and DTO Constraints Against Migration Columns

Missing `nullable=false` on JPA annotations should mirror DB NOT NULL constraints. Similarly, `@Size(max=N)` on DTOs should match `VARCHAR(N)` column constraints. Mismatches cause confusing errors at the wrong layer.

### Flyway Migration Files Must End With a Trailing Newline

Missing trailing newlines cause diff noise and compatibility issues. Consistently enforced in review.

### Extract Validation Into Dedicated Validator Classes

Validation logic in standalone classes (e.g., `RawCustodyTransactionValidator`) keeps processors focused on orchestration while rules become independently testable.

### Test Naming Convention: method_when_should

`getTransfer_whenIdNotFound_shouldReturn404` — encodes what's tested, the condition, and expected behavior. Makes test failures self-documenting.

### Validation Failure Tests Should Verify Service Layer Never Called

For 400-level validation failures, assert `verify(service, never()).method(any(), any())`. Confirms validation short-circuits before business logic.

### Correct Enum Types in Test Data — Copy-Paste Risk

Tests may compile with the wrong enum type if both are structurally compatible. Review test data for semantic correctness, not just compilation. Copy-paste bugs span enums, Javadoc, assertions, and test data values.

### Entity ID Strategy Must Match Usage Site

When modifying `@Id` generation annotations, grep for all entity creation sites to verify alignment. See also: `@UuidGenerator` silently overwrites application-assigned IDs (above).

## Cross-Refs

- `spring-boot-gotchas.md` — one-liner tripwires for common Spring Boot mistakes (companion file)
- `postgresql-query-patterns.md` — window functions, CTEs, indexing strategy, migration safety patterns (complements the Spring Boot migration gotchas here)
