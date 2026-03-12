# Java Observability

## Grafana Dashboard Patterns for Micrometer Counters

When all metrics are counters (no timers/gauges), use these PromQL patterns:

- **Timeseries rate:** `sum(rate(metric_total{...}[$__rate_interval])) * 60` for per-minute rates
- **Bar chart totals:** `sum(increase(metric_total{...}[$__rate_interval]))` for discrete counts per interval
- **Pie chart over range:** `sum(increase(metric_total{...}[$__range]))` for full-window totals
- **Ratio panels:** `clamp_min(denominator, 1e-10)` to avoid division-by-zero on sparse metrics
- **Stat panels:** `reduceOptions.calcs: ["lastNotNull"]` for current value

Structure dashboards by operational question (backwards from alerts), not by metric name. Group: overview stats → throughput over time → failure/protection layers → downstream integration health → recovery jobs.

## Micrometer Gotchas

- Metrics discussion process: (1) gather context (2) map existing metrics with tags (3) analyze gaps against alerting/debugging/capacity questions (4) propose with names/types/tags/SLO buckets (5) prune — remove anything not earning its cardinality cost (6) cardinality check — estimate worst-case series count
- `DistributionSummary.builder()` and `Timer.builder()` respect `application.properties` SLO bucket config; `meterRegistry.summary()`/`meterRegistry.timer()` bypass it entirely
- Timer try/finally: use an `outcome` variable instead of duplicating `sample.stop()` at each exit; skip timing for no-op runs (place `Timer.start()` after early return) to keep percentiles clean
- Testing: use `SimpleMeterRegistry` (in-memory, records real values) — not mocked `MeterRegistry` + stubbed `Counter`
