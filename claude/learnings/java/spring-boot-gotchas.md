Companion to `spring-boot.md`. One-liner tripwires for common Spring Boot mistakes.
- **Keywords:** @Scheduled, ShedLock, CORS, Optional, switch null, Lombok builder, InterruptedException, SLF4J, Map.get, ZoneId, properties quoting, MethodArgumentNotValidException, @ConfigurationProperties, @EnableConfigurationProperties, @ConfigurationPropertiesScan, CGLIB, exception logging, stack trace, catch block, @Profile, IAM, credentials
- **Related:** none

---

- `@Scheduled` + `@SchedulerLock` (ShedLock): swallow exceptions — Spring catches/logs, ShedLock releases lock, job retries next tick; rethrowing produces duplicate error logs
- Inner loops processing independent items: catch per-item to prevent one failure from killing the batch
- `.properties` files: double-quoted values like `"https://..."` include quotes literally — never quote values
- `cors(Customizer.withDefaults())` silently fails with custom SecurityFilterChain — use explicit `.cors(c -> c.configurationSource(corsConfigSource))`
- `Optional<Optional<T>>`: nested Optionals add no information — rethink the API
- `switch` on null enum: NPE before matching any case; `default` does NOT catch null — guard explicitly
- Switch `default`: throw `IllegalArgumentException`, not return null — null propagates silently
- Discarded `.build()` in Lombok builder chains: compiler won't catch it since return value is ignorable
- `Optional.ofNullable().map().orElse()` for simple null-to-default: use ternary; reserve Optional for method return types
- `.get()` on Optional: always use `.orElseThrow()` with meaningful exception
- `MethodArgumentNotValidException`: not all errors are `FieldError` — use `instanceof` before casting
- Constraint annotation + error message are an atomic pair — change one, change both
- `InterruptedException`: call `Thread.currentThread().interrupt()` before rethrowing — bare `throw new RuntimeException(e)` loses the interrupt flag
- `System.out.println`/`System.err.println` in production: use SLF4J with structured logging
- Duplicate logging across layers: log at the point closest to the decision/action, not in both caller and callee
- Catch block logging without the exception object loses the stack trace — always include `e` as the last argument: `log.error("Failed to process", e)`, not `log.error("Failed to process: " + e.getMessage())`
- `Map.get()` results are nullable — null-guard before `.toUpperCase()` or feeding into switch
- Null checks on collection-returning methods: per Java convention, these never return null — don't null-check them
- Hardcoded timezone offsets: use `ZoneId.of("Asia/Singapore")`, not `ZoneOffset.of("+08:00")` — ZoneId handles DST
- `Impl` suffix: name classes by responsibility, not structural role — `PaymentService` not `PaymentServiceImpl`
- `@Retryable(retryFor = RestClientException.class)` catches 4xx too — `RestClientException` parents both `HttpClientErrorException` (4xx) and `HttpServerErrorException` (5xx). Use `retryFor = {ResourceAccessException.class, HttpServerErrorException.class}` or add `noRetryFor = HttpClientErrorException.class`
- `@Data` on JPA entities: generates `equals()`/`hashCode()` from all mutable fields — breaks `Set`/`Map` when entity state changes. Use `@Getter @Setter` + `@EqualsAndHashCode(onlyExplicitlyIncluded = true)` with `@EqualsAndHashCode.Include` on the `@Id` field. Also risk: `toString()` triggering lazy-loaded associations

- PostgreSQL aborts the transaction after a constraint violation — **all subsequent statements fail** with "current transaction is aborted." In `@Transactional` methods, a `DataIntegrityViolationException` from `saveAndFlush()` makes the catch block's recovery query fail. Unit tests with mocked repos don't catch this because mocks don't simulate PG transaction semantics. Fix: `@Transactional(propagation = REQUIRES_NEW)` on the recovery query, or let the exception propagate and retry at the caller (the retry hits the fast-path duplicate check)

- Financial systems: fail-fast on data corruption in GET responses. When a DB field contains corrupt data (e.g., invalid JSON in a JSONB column), throw rather than log-and-return-null. Silent degradation hides integrity signals — a corrupt `vendor_details` field returning `null` is indistinguishable from "no data." In financial systems, data corruption is an incident, not a graceful degradation scenario.

- `@EnableConfigurationProperties` placement: don't put it on unrelated `@Configuration` classes (couples concerns) or on `@Service`/`@Component` classes (configuration concern on a business bean). Options: dedicated `@Configuration` class, or `@ConfigurationPropertiesScan` on the main app class (auto-discovers all `@ConfigurationProperties` records, scales without per-class wiring)
- `@Configuration` + `@ConfigurationProperties` on the same class: `@Configuration` uses CGLIB proxying (needs no-arg constructor), `@ConfigurationProperties` constructor binding needs a parameterized constructor — incompatible on records, semantically wrong on regular classes (conflates bean factory with value holder)

- Broad `@ExceptionHandler(IllegalArgumentException.class)` in global exception handlers masks server 500s as client 400s. Spring/Hibernate throw `IllegalArgumentException` for internal contract violations (bad type conversions, invalid entity state). These handlers make the bug invisible: no 5xx alerts fire, dashboards show clean, callers get misleading "invalid request parameter." Worse: domain methods that throw `IllegalArgumentException` for validation (e.g., `parseAmount`) accidentally work because the broad catch maps them to 400 — two bugs compensating. Fix: use domain-specific exceptions for validation, remove the broad `IllegalArgumentException` catch entirely

- `TransactionTemplate` batch processing with detached entities: when a batch query loads entities outside the transaction and processes each inside a per-item `TransactionTemplate.executeWithoutResult()`, the entity is detached and potentially stale. Re-fetch by ID + status guard inside the transaction prevents submitting stale state. Pattern: `findById().orElseThrow()` → check status still matches expected → proceed. The `handleSubmitFailure` pattern (re-fetch in a new tx) is correct; applying it to the happy path too is the defensive choice for financial services. Extract `refetchEntity(id)` helper when 3+ call sites share the same re-fetch + orElseThrow logic — keeps the pattern consistent and DRY. The status guard is critical when the method has external side effects (vendor API calls) that execute before the DB save — without it, a stale entity leads to double-submit when the save fails with OL and the next cycle retries

- Fixed-offset external systems: use `ZoneOffset.ofHours(-5)`, not `ZoneId.of("America/New_York")`. Geographic zone IDs observe DST; use `ZoneOffset` when the external system documents a fixed UTC offset that never adjusts. The `ZoneId` preference applies to internal/user-facing time — the inverse rule applies here.

- Use `log.debug` (not `warn` or `info`) for filter-out paths in public WebSocket stream consumers where the majority of events don't belong to your system. Vendor misbehavior warrants `log.debug`; the common "not our order" path warrants no log at all. Over-logging these paths floods production logs and obscures real signal.

- `LocalTime.now(clock)` is sufficient when `clock` carries a timezone via `Clock.system(zoneId)` — the result is already zone-local. Going through `ZonedDateTime.now(clock).toLocalTime()` is redundant and adds confusion about whether the timezone is being applied twice.

- `Optional.orElse(null)` for nullable return fields: the existing rule "always use `.orElseThrow()`" applies when absence is an error. For methods that legitimately return null (nullable DTO fields, optional downstream values), use `.orElse(null)` — calling `.get()` without an `isPresent()` guard is a latent NPE regardless of how rare the empty case is.

- `@Profile` on credential-provider `@Configuration` must cover ALL non-IAM environments, not just `"dev"`. Missing a profile (e.g., `"integration"`, `"local"`) silently activates IAM-based production config, which fails with opaque credential errors. Audit `@Profile` annotations on credential configs whenever a new environment or profile is introduced.

- Java format strings: `$n` is not a recognized format specifier — it compiles and runs silently but the argument is dropped. Use `%n` for a platform-appropriate newline or `\n` for a literal LF. The `$` prefix has no meaning in `String.format` / SLF4J format strings.

- Spring bean lifecycle (`DisposableBean`/`AutoCloseable`) checks the actual bean instance, not the `@Bean` method's declared return type. Returning `Executor` from a method that creates `ThreadPoolTaskExecutor` does NOT hide lifecycle — Spring still calls `destroy()`. Narrowing return types is valid API design.

- Financial SPI records: make all invariants explicit even when technically redundant. `total >= 0` is implied by `available >= 0` + `available <= total`, but an explicit check gives the correct error message when a vendor mapping bug produces a negative total.

- Don't include raw financial values in exception messages (`"was: " + amount`). If `IllegalArgumentException` surfaces through `@ExceptionHandler` to an API response, the amount leaks. Keep validation messages generic.

## Cross-Refs

No cross-cluster references.
