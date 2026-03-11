# Spring Boot

### Mockito 5+ (Spring Boot 3.5.x): Drop mockito-inline

Spring Boot 3.5.x uses Mockito 5+ which includes inline mocking in `mockito-core` by default. The separate `mockito-inline` artifact is unnecessary and will fail to resolve if the parent BOM no longer manages its version. Safe to remove -- `MockedStatic` and static mocking still work via `mockito-core`.

### Multi-Module: spring-boot:run from Parent POM

`mvn -pl <module> -am spring-boot:run` from a multi-module parent POM fails with "Unable to find a suitable main class" because the plugin runs on the parent first. Workaround: build with `mvn package -DskipTests`, then start directly with `java -jar <module>/target/<artifact>.jar --spring.profiles.active=<profile>`.

### List Property Indexing Must Start at 0 and Be Contiguous

Spring Boot list properties (e.g., `wallets[0].address`, `wallets[1].address`) must start at index 0 with no gaps. Starting at [1] or having a gap (e.g., jumping from [3] to [5]) causes Spring Boot to silently drop entries -- no startup error, just missing data at runtime. Each indexed entry requires all its sub-properties at the same index.

- **Takeaway**: Always verify list property indices start at 0 and are contiguous. Spring Boot fails silently on index issues.

### Flyway Migration Filenames Require Uppercase V Prefix

Lowercase `v001__init.sql` is silently ignored by Flyway. Must be `V001__init.sql` (uppercase V). No error, no warning -- the migration simply doesn't execute. Verify migrations ran by checking the `flyway_schema_history` table.

- **Takeaway**: Always use uppercase `V` prefix for Flyway versioned migrations. This is a silent failure mode with no diagnostic output.

### Avoid Mixing application.properties and application.yml

Spring Boot will merge both formats if both exist, but precedence rules are non-obvious and can lead to subtle configuration conflicts. Consolidate to a single format across the project.

- **Takeaway**: Pick one config format and use it consistently. If the project uses `.properties`, don't introduce `.yml` files.

### JPA @CreationTimestamp/@UpdateTimestamp as Timestamp Source of Truth

Team consensus (transfer-server MR !38) settled on JPA annotations as the authoritative timestamp management layer, removing DB triggers. JPA annotations are testable and visible in application code. DB triggers were tried (!25) but created confusion about which layer "owns" timestamps.

- **Takeaway**: Use JPA lifecycle annotations for timestamp management. If DB triggers exist for defense-in-depth, document clearly which layer is authoritative.

### Indexes in Migrations, Not JPA Annotations

@Index annotations on JPA entities are redundant when indexes are defined in Flyway migrations. Migration SQL is the authoritative source for schema objects. JPA @Index can create conflicts if the generated DDL doesn't match the migration-defined index exactly.

- **Takeaway**: Define indexes in Flyway migrations only. Don't duplicate with JPA @Index annotations.

### @Builder.Default Required for insertable=false Columns

DB-defaulted columns marked with `insertable=false, updatable=false` in JPA still need Java-side defaults via `@Builder.Default` for Lombok builders. Without it, builders leave these fields null, causing test failures or unexpected behavior in non-persistence contexts.

- **Takeaway**: When marking JPA columns as insertable=false, add @Builder.Default with a sensible Java default.

### @Enumerated + PostgreSQLEnumJdbcType for PostgreSQL Enums

Standard pattern for type-safe PostgreSQL enum columns in JPA entities. Combines `@Enumerated(EnumType.STRING)` with Hibernate's `PostgreSQLEnumJdbcType` for proper JDBC type mapping.

- **Takeaway**: Use @Enumerated(EnumType.STRING) + @JdbcType(PostgreSQLEnumJdbcType.class) for PostgreSQL enum columns.

### JPA Repository Generic Type Must Match Entity ID Type

`JpaRepository<Entity, Long>` when the entity uses `UUID` as its ID type causes runtime errors, not compile-time errors. The generic type parameter is erased at compile time, so the mismatch only surfaces when Spring Data tries to generate query implementations at startup or when certain repository methods are invoked. For entities with `@IdClass(CompositeKeyClass.class)`, the second generic parameter must be the composite key class, not `UUID`.

- **Takeaway**: Always verify the second type parameter of JpaRepository matches the entity's @Id field type (including composite keys via @IdClass). Silent compile-time, loud runtime bug.

### Flyway Migrations Must Not Be Modified After Deployment

Modifying the content of an already-applied Flyway migration causes checksum mismatches (FlywayValidateException). Once a migration is applied to any environment, it is immutable -- fixes must go in new migration versions.

- **Takeaway**: Treat applied migrations as append-only. Never edit an existing migration; always create a new one.

### PostgreSQL Views Must Be Dropped Before Altering Their Dependent Columns

When adding or modifying a column on a table that has dependent views, PostgreSQL will fail the ALTER. Use DROP VIEW IF EXISTS before the ALTER TABLE, ideally in the same migration file so they execute atomically in sequence.

- **Takeaway**: Same migration: DROP VIEW IF EXISTS, ALTER TABLE, CREATE OR REPLACE VIEW.

### ResponseEntityExceptionHandler: only extend when handling Spring MVC built-in exceptions

Don't extend `ResponseEntityExceptionHandler` in a `@RestControllerAdvice` that only handles application-level exceptions. That base class is designed for Spring MVC's built-in exceptions (MethodArgumentNotValidException, etc.) and adds unnecessary complexity when your handler only deals with custom domain exceptions.

- **Takeaway**: Custom exception handlers should be plain @RestControllerAdvice. Only extend ResponseEntityExceptionHandler when overriding Spring's built-in exception handling.

### saveAndFlush in loops creates partial-commit risks

Using `saveAndFlush` inside a processing loop means earlier iterations are already committed if a later iteration fails, leaving inconsistent state. Wrap batch processing in a single transaction boundary or implement explicit rollback logic.

- **Takeaway**: Batch operations need transactional atomicity. Use save() in loops with a single flush/commit, or @Transactional on the enclosing method.

### Jackson DTOs need @NoArgsConstructor alongside @AllArgsConstructor

Jackson requires a default no-arg constructor for deserialization. When using Lombok's `@AllArgsConstructor`, Jackson can't instantiate the object without also having `@NoArgsConstructor`. This was flagged on 3 out of 4 files in a single MR.

- **Takeaway**: Lombok DTO pattern for Jackson: @Data + @NoArgsConstructor + @AllArgsConstructor (or @Builder with @NoArgsConstructor).

### @JsonProperty annotations must be applied consistently across all DTO fields

Inconsistent `@JsonProperty` annotation means some fields get explicit JSON name mapping while others rely on Jackson's default naming strategy. If the default strategy diverges from the explicit names (e.g., snake_case vs camelCase), some fields silently fail to deserialize.

- **Takeaway**: Either annotate all fields with @JsonProperty or none. Mixing creates silent serialization mismatches.

### Database Migrations That Change FK Targets Require Data Consistency Verification

When altering a foreign key to reference a different column (e.g., code -> name), existing data in the referencing column must already match the new target column's values. Otherwise the migration fails at constraint creation time.

- **Takeaway**: Before changing a FK target column, verify all existing referencing data matches the new target's values.

### Case sensitivity in Sort.Direction validation

`Sort.Direction.fromString()` is case-insensitive in Spring, but custom validation may check lowercase while conversion expects uppercase. Normalize before both validation and conversion operations to avoid mismatches.

- **Takeaway**: Normalize sort direction strings before both validation and conversion. Spring is case-insensitive but custom code may not be.

### JPA entities need no-arg constructors when using Lombok @Data + @AllArgsConstructor

`@Data` + `@AllArgsConstructor` without `@NoArgsConstructor` removes the default constructor JPA/Hibernate requires for entity instantiation. Always pair with `@NoArgsConstructor`.

- **Takeaway**: Lombok entity pattern: always include @NoArgsConstructor alongside @AllArgsConstructor for JPA entities.

### Spring MVC path collision: UUID path variables shadow sibling sub-resource paths

When `/{id}` is at the same level as `/webhooks` or `/partners`, Spring gives precedence to path variable match. Fix: rename the parent path to give each resource its own unambiguous namespace.

- **Takeaway**: Avoid path variable segments at the same level as literal path segments. UUID patterns match everything.

### Separate @Transactional boundaries to avoid stale reads in polling loops

When a method both saves and re-reads entities, a single `@Transactional` prevents seeing fresh data (reads return the cached version from the persistence context). Extract saving logic into a separate service with its own `@Transactional` boundary.

- **Takeaway**: Polling loops that save then re-read need separate transactional boundaries. Same-transaction reads return stale persistence context data.

### @UuidGenerator on entities with application-assigned IDs causes silent overwrites

Hibernate `@UuidGenerator` silently overwrites application-assigned IDs. If application code sets IDs via `UUID.randomUUID()`, remove `@UuidGenerator`. The annotation always generates a new UUID, ignoring any value already set on the field.

- **Takeaway**: Check whether IDs are application-assigned before adding @UuidGenerator. It silently overwrites, not supplements.

### @PostConstruct + singleton = stale reference data anti-pattern

When a `@Component` singleton loads DB-backed reference data in `@PostConstruct`, that data is frozen for the pod's lifetime. New reference data (currencies, networks, assets) added to the DB after startup is invisible. Fix options: per-call fresh lookup, `@Cacheable` with TTL, or `@RefreshScope`.

- **Takeaway**: Never cache mutable reference data in @PostConstruct singletons. Use TTL-based caching or fresh lookups.

### Residual annotations after refactoring

After changing from DI-managed to manual construction (or vice versa), check for leftover `@Component`, `@PostConstruct`, `@Autowired` annotations that no longer serve a purpose. Residual annotations are a code smell after refactors and confuse readers about the class's lifecycle.

- **Takeaway**: After refactoring class lifecycle management, audit for orphaned Spring annotations.

### Multi-module Flyway init container pattern

In multi-module Spring Boot services with K8s deployment, Flyway migrations live in a dedicated init module (e.g., `*-service-init`) that runs as a K8s init container before the server starts. The server module uses `spring.jpa.hibernate.ddl-auto=validate` and does NOT have Flyway on its classpath. For tests in the server module, add Flyway as a test-scoped dependency and duplicate migration SQL in `src/test/resources/db/migration/`.

- **Takeaway**: Separation ensures multi-replica safety (only init container races on migration lock). Server module validates schema matches entities but never modifies it.

### PostgreSQL CREATE TYPE ... AS ENUM breaks H2 tests

H2 does not support PostgreSQL's `CREATE TYPE name AS ENUM (...)` syntax. When using PostgreSQL enum types in migrations, H2 is not viable for integration tests — use Testcontainers with PostgreSQL instead. The alternative (VARCHAR columns) trades DB-level type safety for test simplicity.

- **Takeaway**: If you use PG enum types, commit to Testcontainers for all DB tests. There's no H2 workaround.

### Enum.valueOf() is unsafe for DB-sourced values

Database values may not match Java enum constants (case differences, new values added to DB but not code, typos). Use a safe lookup pattern -- `Arrays.stream(values()).filter(...)` with a fallback or `Optional` -- instead of raw `Enum.valueOf()` which throws `IllegalArgumentException` with no context.

- **Takeaway**: Never use raw Enum.valueOf() for externally-sourced values. Use safe lookup patterns with meaningful error messages.
