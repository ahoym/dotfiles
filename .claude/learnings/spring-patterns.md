# Spring Boot Patterns

## @Scheduled + @SchedulerLock Exception Handling

Scheduled jobs using `@Scheduled` + `@SchedulerLock` (ShedLock) should **swallow exceptions** in their top-level method — log the error but do not rethrow.

**Why:**
- Spring's `TaskScheduler` catches and logs exceptions from `@Scheduled` methods anyway, so rethrowing just produces duplicate error logs
- ShedLock releases the lock regardless of whether the method throws or returns normally
- The job will run again on the next schedule — no retry mechanism is lost by swallowing
- Keeping the job alive prevents the scheduler thread from being disrupted

**Pattern:**
```java
@Scheduled(cron = "...")
@SchedulerLock(name = "MyJob_run")
public void run() {
    try {
        // ... business logic ...
    } catch (Exception e) {
        log.error("Job failed: {}", kv("error", e.getMessage()), e);
        // swallow — scheduler retries on next cron tick, ShedLock releases regardless
    }
}
```

**Exception:** Inner loops processing independent items (e.g., iterating customers) should also catch per-item to prevent one failure from killing the batch — but those inner catches can be more granular.

## Micrometer API Patterns

### DistributionSummary.builder() vs meterRegistry.summary()

Use `DistributionSummary.builder("name").tag(...).register(registry).record(value)` instead of `meterRegistry.summary("name", tags).record(value)`.

The shorthand `meterRegistry.summary()` bypasses `application.properties` SLO bucket configuration (`management.metrics.distribution.slo.*` and `management.metrics.distribution.percentiles-histogram.*`). Only the builder pattern ensures property-driven histogram/SLO config is applied.

Same principle applies to `Timer.builder()` vs `meterRegistry.timer()` for SLO buckets.

### Timer try/finally Pattern

When a method has multiple exit paths that all need timing, use an outcome variable with try/finally instead of duplicating `sample.stop()` at each exit:

```java
Timer.Sample sample = Timer.start(meterRegistry);
String outcome = "success";
try {
    // ... business logic with multiple return paths ...
} catch (Exception e) {
    outcome = "failure";
    log.error(...);
} finally {
    sample.stop(Timer.builder("metric.name")
        .tag("outcome", outcome)
        .register(meterRegistry));
}
```

**Skip timing for no-op runs** (e.g., scheduled job finds nothing to do) — place `Timer.start()` after the no-op early return. This keeps latency percentiles clean by only measuring runs that did actual work.

### Testing with SimpleMeterRegistry

Use `SimpleMeterRegistry` (not a mocked `MeterRegistry` + `Counter`) with assertion-based verification:

```java
private MeterRegistry meterRegistry = new SimpleMeterRegistry();
// ... inject into service under test ...
assertThat(meterRegistry.get("metric.name").counter().count()).isEqualTo(1);
```

**Why**: `SimpleMeterRegistry` is an in-memory implementation that actually records metrics. Mocking `MeterRegistry` requires stubbing `counter()`, `timer()`, etc. and verifying interactions — more complex and less readable than just asserting on real recorded values.
