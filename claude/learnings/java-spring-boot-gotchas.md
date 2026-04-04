Spring Boot gotchas: log levels for high-frequency paths, timezone handling, Optional patterns, format strings.
- **Keywords:** log level, debug, ZoneOffset, DST, Optional, orElse, format string, Spring Boot
- **Related:** ~/.claude/learnings/spring-boot-gotchas.md

---

- Use `log.debug` (not `warn` or `info`) for filter-out paths in public WebSocket stream consumers where the majority of events don't belong to your system. Vendor misbehavior warrants `log.debug`; the common "not our order" path warrants no log at all. Over-logging these paths floods production logs and obscures real signal.

- `LocalTime.now(clock)` is sufficient when `clock` carries a timezone via `Clock.system(zoneId)` — the result is already zone-local. Going through `ZonedDateTime.now(clock).toLocalTime()` is redundant and adds confusion about whether the timezone is being applied twice.

- `Optional.orElse(null)` for nullable return fields: the existing rule "always use `.orElseThrow()`" applies when absence is an error. For methods that legitimately return null (nullable DTO fields, optional downstream values), use `.orElse(null)` — calling `.get()` without an `isPresent()` guard is a latent NPE regardless of how rare the empty case is.

- Java format strings: `$n` is not a recognized format specifier — it compiles and runs silently but the argument is dropped. Use `%n` for a platform-appropriate newline or `\n` for a literal LF. The `$` prefix has no meaning in `String.format` / SLF4J format strings.
