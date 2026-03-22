Companion to `spring-boot.md`. One-liner tripwires for common Spring Boot mistakes.
- **Keywords:** @Scheduled, ShedLock, CORS, Optional, switch null, Lombok builder, InterruptedException, SLF4J, Map.get, ZoneId, properties quoting, MethodArgumentNotValidException
- **Related:** spring-boot.md

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
- `Map.get()` results are nullable — null-guard before `.toUpperCase()` or feeding into switch
- Null checks on collection-returning methods: per Java convention, these never return null — don't null-check them
- Hardcoded timezone offsets: use `ZoneId.of("Asia/Singapore")`, not `ZoneOffset.of("+08:00")` — ZoneId handles DST
- `Impl` suffix: name classes by responsibility, not structural role — `FundingApi` not `FundingApiImpl`

## Cross-Refs

- `~/.claude/learnings/spring-boot.md` — Spring Boot patterns and best practices (companion file)
