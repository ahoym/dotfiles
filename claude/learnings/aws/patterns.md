Cost-aware defaults and scheduling workarounds for ECS Fargate and EventBridge.
- **Keywords:** EventBridge, rate expression, sub-minute scheduling, Lambda, ECS Fargate, NAT Gateway, Secrets Manager, SSM Parameter Store, Terraform, OpenTofu, IaC, public subnet, cost optimization, AWS SDK v2, retryPolicy, retryStrategy, maxAttempts
- **Related:** none

---

## EventBridge Scheduler minimum interval

EventBridge `rate()` expressions floor at 1 minute. For sub-minute scheduling (e.g., every 3 seconds), the standard workaround is a Lambda triggered every minute that loops internally for ~60 seconds. Lambda free tier (400K GB-seconds) comfortably covers this.

## ECS Fargate cost-aware defaults

- Minimum allocation: 256 CPU (0.25 vCPU) / 512 MB memory — ~$4.60/mo
- Use **default VPC + public subnets** with `assign_public_ip = true` for outbound-only workloads. Avoids NAT Gateway cost (~$30+/mo) which often exceeds the Fargate compute cost itself.
- Egress-only security group (no ingress rules) is sufficient for workers that only make outbound HTTP calls.
- Secrets Manager with a single JSON secret + ECS `secrets` mapping is cheaper and simpler than N separate secrets.
- `ignore_changes = [task_definition]` in Terraform lets CI/CD update the task definition without drift.

## AWS SDK v2 Retry Configuration

`RetryPolicy.builder().numRetries(N)` is deprecated in AWS SDK v2. Replace with `.retryStrategy(b -> b.maxAttempts(N + 1))` where `maxAttempts` equals retries plus the initial attempt. The off-by-one between retries and attempts is easy to miss — `numRetries(3)` means 4 total attempts, so the equivalent is `maxAttempts(4)`.

## SSM Parameter Store vs Secrets Manager

Both KMS-encrypted, IAM-scoped, TLS-only. Pick by use case, not by gut.

| | SSM Parameter Store | Secrets Manager |
|---|---|---|
| Cost | Free (Standard tier; 4 KB) | $0.40/secret/month |
| Native rotation | No (DIY Lambda) | Yes (RDS plug-and-play; custom Lambdas for others) |
| Hierarchical paths | Yes (`/app/env/svc/key`, `GetParametersByPath`) | Flat names; `/` allowed but no path query |
| Cross-region replication | Manual | Built-in |
| Size cap | 4 KB Standard / 8 KB Advanced | 64 KB |

**Default to Parameter Store** for static API creds — free, hierarchical, same security guarantees. **Switch to Secrets Manager** when: native rotation matters (RDS), value >4 KB, or multi-region replication is required. The `lifecycle { ignore_changes = [value] }` pattern keeps Terraform-declared SSM placeholders separate from values populated out-of-band (`aws ssm put-parameter --value file://`, never `--value "literal"` — leaks to shell history).

## Terraform vs OpenTofu

Drop-in compatible (HCL syntax, state format, providers all shared). Migration is reversible — switching back is a 1-day project.

- **Terraform** — BSL license (non-compete clause; effectively MIT for non-commercial use). Larger ecosystem, more registry modules, deeper Stack Overflow / docs corpus, HashiCorp Cloud integration. **Default for personal/team projects** — ecosystem advantage outweighs license risk for non-commercial use.
- **OpenTofu** — MPL 2.0 (true open source), Linux Foundation governance, built-in client-side state encryption (Terraform requires Terraform Cloud for equivalent). **Pick when** license matters (commercial competition with HashiCorp), or when state encryption without paying for Terraform Cloud is required.

State backend: S3 + DynamoDB lock for both — pennies per month, durable + versioned + encrypted + concurrent-write-safe. The default local-state setup is fine until two people / two machines / a CI runner ever touches it; switch before that point, not after.

## Agent Isolation: Account Boundary > IAM Boundary

When an agent operates on cloud infra with mutating capability, two isolation models:

| Model | Strength | Failure mode |
|---|---|---|
| Same account, scoped IAM role + tag-condition policies | Soft — depends on policy correctness | Misconfigured `Condition` block → leak across resource sets |
| Separate AWS account via Organizations sub-account | Hard — different account = different blast radius | Credential leak still bounded to that account |

For mutating workloads (`terraform apply`, etc.), separate accounts are the correct boundary. IAM-scoped roles are appropriate when the agent only reads.

Inside the dev sub-account, `AdministratorAccess` is appropriate when the account boundary IS the wall — a hand-crafted policy enumerating every service (EC2/IAM/CloudWatch/EIP/S3/DynamoDB/...) adds maintenance cost without changing blast radius. The wall has already been built at the account perimeter.

Setup cost: ~30 min one-time for a sub-account via Organizations. Free. Worth it for any system handling real money or production user data.

## Cross-Refs

None — intra-cluster refs handled by cluster index.
