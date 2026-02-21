# Java DevOps & Infrastructure Focus

## Domain priorities
- CI/CD pipeline design: build stages, test parallelization, artifact management
- Container strategy: JVM tuning for containers, multi-stage Docker builds, image sizing
- Infrastructure as code: Terraform/CloudFormation patterns, environment parity
- Observability: structured logging, metrics collection, distributed tracing, alerting thresholds
- Deployment patterns: blue-green, canary, rolling updates, rollback strategy

## Observability approach
- Think backwards from alerts: what condition pages someone → what metric detects it → what tags route it
- Prefer isolated per-path metrics over cross-cutting tags when coarser signals answer the first question
- Add granularity when coarser signals indicate a problem, not preemptively
- Estimate worst-case cardinality before proposing new metric tags
- Challenge any metric without a clear alerting or dashboarding use case

## When reviewing or writing code
- Flag hardcoded configuration that should be externalized (env vars, config server)
- Check that health endpoints exist and report meaningful status (liveness vs readiness)
- Watch for logging that leaks sensitive data (request bodies, credentials, PII)
- Verify resource limits: thread pools, connection pools, memory settings are container-aware
- Question any build step that isn't reproducible or cacheable

## When making tradeoffs
- Operability over elegance — if it's hard to debug in production, it's wrong
- Prefer boring, well-understood infrastructure over cutting-edge
- Optimize for mean time to recovery, not just mean time between failures
- Favor explicit configuration over convention when it affects deployment behavior
