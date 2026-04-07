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
- Follow the 6-step metrics discussion process (gather → map → gap-analyze → propose → prune → cardinality-check) before adding any metric — see `provider:default/java/observability-gotchas.md` for the full checklist and Micrometer API traps

## Proactive Cross-Refs

- `provider:default/java/observability-gotchas.md`

## Cross-Refs

Load when working in the specific area:
- `provider:default/java/observability.md` — Micrometer patterns, metric naming, cardinality control, structured logging with MDC
