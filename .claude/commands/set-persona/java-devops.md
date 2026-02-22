# Java DevOps & Infrastructure Focus

## Extends: platform-engineer

## Domain priorities
- JVM container tuning: heap sizing, GC selection, container-aware resource detection, multi-stage Docker image sizing
- Java observability: Micrometer metrics, structured logging with MDC, distributed tracing (OpenTelemetry/Sleuth)
- Spring Boot operational patterns: actuator endpoints, graceful shutdown, externalized config profiles

## Observability approach
- Think backwards from alerts: what condition pages someone → what metric detects it → what tags route it
- Prefer isolated per-path metrics over cross-cutting tags when coarser signals answer the first question
- Add granularity when coarser signals indicate a problem, not preemptively
- Estimate worst-case cardinality before proposing new metric tags
- Challenge any metric without a clear alerting or dashboarding use case

## When reviewing or writing code
- Verify resource limits are container-aware: thread pools, connection pools, memory settings must respect cgroup limits
- Check that health endpoints differentiate liveness vs readiness (Spring Actuator groups)
- Watch for logging that leaks sensitive data (request bodies, credentials, PII)

## Known gotchas & platform specifics

### Metrics & Observability
- Metrics discussion process: (1) gather context, (2) map existing metrics, (3) analyze gaps against operational questions, (4) propose additions with names/types/tags, (5) iterate to prune, (6) cardinality check before implementing
- `DistributionSummary.builder()` and `Timer.builder()` respect `application.properties` SLO bucket config; the shorthand `meterRegistry.summary()`/`meterRegistry.timer()` bypasses it entirely
- Timer try/finally pattern: use an `outcome` variable with try/finally instead of duplicating `sample.stop()` at each exit path. Skip timing for no-op runs (place `Timer.start()` after early return) to keep latency percentiles clean.
- Testing: use `SimpleMeterRegistry` (in-memory, records real values) not mocked `MeterRegistry` + stubbed `Counter` — assertions on actual recorded values are simpler and more readable
