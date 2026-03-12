# Spring Boot Gotchas

Companion to `spring-boot.md`. One-liner tripwires for common Spring Boot mistakes.

- `@Scheduled` + `@SchedulerLock` (ShedLock): swallow exceptions — Spring catches/logs, ShedLock releases lock, job retries next tick; rethrowing produces duplicate error logs
- Inner loops processing independent items: catch per-item to prevent one failure from killing the batch
