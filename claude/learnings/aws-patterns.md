Cost-aware defaults and scheduling workarounds for ECS Fargate and EventBridge.
- **Keywords:** EventBridge, rate expression, sub-minute scheduling, Lambda, ECS Fargate, NAT Gateway, Secrets Manager, Terraform, public subnet, cost optimization
- **Related:** aws-messaging.md

---

## EventBridge Scheduler minimum interval

EventBridge `rate()` expressions floor at 1 minute. For sub-minute scheduling (e.g., every 3 seconds), the standard workaround is a Lambda triggered every minute that loops internally for ~60 seconds. Lambda free tier (400K GB-seconds) comfortably covers this.

## ECS Fargate cost-aware defaults

- Minimum allocation: 256 CPU (0.25 vCPU) / 512 MB memory — ~$4.60/mo
- Use **default VPC + public subnets** with `assign_public_ip = true` for outbound-only workloads. Avoids NAT Gateway cost (~$30+/mo) which often exceeds the Fargate compute cost itself.
- Egress-only security group (no ingress rules) is sufficient for workers that only make outbound HTTP calls.
- Secrets Manager with a single JSON secret + ECS `secrets` mapping is cheaper and simpler than N separate secrets.
- `ignore_changes = [task_definition]` in Terraform lets CI/CD update the task definition without drift.

## Cross-Refs

- `claude/learnings/aws-messaging.md` — SQS/SNS/EventBridge messaging patterns, including EventBridge routing and architecture decisions
