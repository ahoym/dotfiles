# Java Observability Gotchas

Companion to `java-observability.md`. Micrometer/metrics tripwires.

- Metrics discussion process: (1) gather context (2) map existing metrics with tags (3) analyze gaps against alerting/debugging/capacity questions (4) propose with names/types/tags/SLO buckets (5) prune — remove anything not earning its cardinality cost (6) cardinality check — estimate worst-case series count
- `DistributionSummary.builder()` and `Timer.builder()` respect `application.properties` SLO bucket config; `meterRegistry.summary()`/`meterRegistry.timer()` bypass it entirely
- Timer try/finally: use an `outcome` variable instead of duplicating `sample.stop()` at each exit; skip timing for no-op runs (place `Timer.start()` after early return) to keep percentiles clean
- Testing: use `SimpleMeterRegistry` (in-memory, records real values) — not mocked `MeterRegistry` + stubbed `Counter`

## See also

- `~/.claude/learnings/java-observability.md` — Grafana dashboard PromQL patterns for Micrometer counters (companion)
