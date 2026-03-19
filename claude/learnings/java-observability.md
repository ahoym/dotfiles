# Java Observability

## Grafana Dashboard Patterns for Micrometer Counters

When all metrics are counters (no timers/gauges), use these PromQL patterns:

- **Timeseries rate:** `sum(rate(metric_total{...}[$__rate_interval])) * 60` for per-minute rates
- **Bar chart totals:** `sum(increase(metric_total{...}[$__rate_interval]))` for discrete counts per interval
- **Pie chart over range:** `sum(increase(metric_total{...}[$__range]))` for full-window totals
- **Ratio panels:** `clamp_min(denominator, 1e-10)` to avoid division-by-zero on sparse metrics
- **Stat panels:** `reduceOptions.calcs: ["lastNotNull"]` for current value

Structure dashboards by operational question (backwards from alerts), not by metric name. Group: overview stats → throughput over time → failure/protection layers → downstream integration health → recovery jobs.

## Cross-Refs

- `~/.claude/learnings/java-observability-gotchas.md` — Micrometer/metrics tripwires (companion)
