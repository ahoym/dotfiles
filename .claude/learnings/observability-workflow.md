# Observability & Metrics Workflow

## Metrics Discussion Process

When asked to add metrics or improve observability:

1. **Gather context** — Read the code, the MR, and the existing metrics surface area before proposing anything
2. **Map existing metrics** — Create a complete inventory (counters, timers, gauges, distributions) with their tags
3. **Analyze gaps** — Compare against what operational questions you'd want to answer (alerting, debugging, capacity)
4. **Propose additions** — Present specific metrics with names, types, tags, and SLO buckets
5. **Iterate to prune** — Discuss each proposal honestly; remove anything that doesn't earn its cardinality cost
6. **Cardinality check** — Estimate worst-case series count before implementing

For observability principles (alerting-first, YAGNI on metrics, cardinality), see the `java-devops` persona via `/set-persona`.
For Micrometer-specific API patterns (builder vs shorthand, Timer try/finally, testing), see `learnings/spring-patterns.md`.
