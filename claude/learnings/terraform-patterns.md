Terraform / OpenTofu patterns and IaC review gotchas.
- **Keywords:** terraform, opentofu, tf, iac, hcl, var, data-source, lifecycle, templatefile, secrets, prevent_destroy, ephemeral env, dev sandbox, agent-driven IaC, AWS account boundary, multi-account, organizations sub-account
- **Related:** none

## Fallback-Source Pattern: Always Gate `data` with `count`

When using a `var.x != "" ? var.x : data.source.id` fallback (e.g., user-provided VPC ID with default-VPC fallback), the `data` source must be conditional:

```hcl
data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

resource "aws_security_group" "x" {
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id
}
```

Without `count`, the data source evaluates on every `plan`/`apply` even when `var.vpc_id` is provided — and fails when the lookup target is absent (e.g., AWS accounts without a default VPC). The `[0]` indexing is mandatory once `count` is added; downstream refs that miss it fail at plan-time with a count mismatch.

This is the Terraform equivalent of lazy evaluation — `data` source fetches are side effects that must be guarded.

## `templatefile()` Is a Secrets Sinkhole

`templatefile()` rendering a script with secrets exposes them in three surfaces simultaneously:

1. **Rendered script content** (e.g., user_data on EC2) — anyone with read access to the resource sees it
2. **Instance metadata API** (`/latest/user-data`) — readable by anything that can hit the metadata endpoint from inside the instance
3. **Terraform state file** — rendered output is stored verbatim

For any secret rendered via `templatefile()` into user_data, GitHub-Actions context, or similar: assume all three surfaces are leaked. Mitigations: pull secrets at runtime from SSM/Secrets Manager inside the rendered script (not as Terraform inputs), or accept the exposure if the secret is short-lived/already-rotated.

## `lifecycle { ignore_changes }` Recovery Commands Belong Colocated

When a resource uses `lifecycle { ignore_changes = [...] }` to allow drift (e.g., AMI updates managed outside Terraform), operators looking at the resource won't see how to recover from drift unless instructions are colocated. README cross-references are missed under pressure.

Pattern: comment block adjacent to the `lifecycle` block listing both in-place (`systemctl restart`) and full (`terraform taint <addr> && terraform apply`) recovery paths. Recovery instructions should live where the drift-causing configuration lives.

## `prevent_destroy` Must Be a Literal — Not Variable-Driven

`lifecycle { prevent_destroy = true }` requires a literal. Terraform forbids variables, locals, or expressions here — `prevent_destroy = var.protect` errors at plan time. Means you can't toggle protection per-env via a flag.

If dev and prod share a module, dev inherits prod's protection. Three workarounds:

| Path | Tradeoff |
|---|---|
| **A. State-rm script in dev** | Modules stay DRY; teardown runs `terraform state rm <protected-addrs>` before `terraform destroy`, plus AWS-CLI sweep filtered by env tag. Highest module fidelity. |
| **B. Parallel modules** (`foo-prod/` with lifecycle, `foo-dev/` without) | ~95% duplication, two-edits-per-change discipline. Cleanest Terraform semantics. |
| **C. Dev declares protected resources inline** | Modules untouched; dev doesn't validate the module path for those resources. |

Path A wins when dev exists in a separate AWS account — script's `AWS_PROFILE` guard + tag filter bound the blast radius of state surgery to dev.

## Ephemeral-Env Teardown When `prevent_destroy` Is Module-Baked

Pattern for `dev-destroy.sh` when modules carry `prevent_destroy`:

```bash
#!/usr/bin/env bash
set -euo pipefail
[[ "${AWS_PROFILE:-}" == "<expected-dev-profile>" ]] || { echo "wrong profile"; exit 2; }
cd "$(dirname "$0")/../envs/dev"
terraform state rm \
  module.ec2_host.aws_eip.this \
  'module.observability.aws_cloudwatch_log_group.this["schwab"]' \
  || true
terraform destroy -auto-approve
aws ec2 describe-addresses --filters Name=tag:Environment,Values=dev \
  --query 'Addresses[].AllocationId' --output text \
  | xargs -n1 -I{} aws ec2 release-address --allocation-id {}
```

Defense in depth: `AWS_PROFILE` guard + `Environment=<env>` tag filter are independent failure domains. One gate failing doesn't expose prod resources.

## Agent-Driven IaC: Account Boundary > IAM Scope

When an environment exists for AI agents to iterate on infra (apply, destroy, re-apply without operator-in-the-loop), the boundary between agent-touchable and untouchable resources should be **AWS account, not IAM policy**.

| Mechanism | Failure mode |
|---|---|
| Read-only IAM on the agent's role | Agent observes but cannot iterate end-to-end — defeats the purpose of having a sandbox. |
| Scoped-write IAM (`Allow` on `dev/*`, `Deny` on `prod/*`) | Policy correctness is the only thing keeping prod safe. One misauthored `Condition` exposes prod. |
| Separate AWS account; agent has credentials only for the dev account | Mathematical isolation. Prod credentials physically aren't in the agent's scope; no policy bug crosses the boundary. |

The account-boundary model also unblocks dev as a real integration test bed — agent can apply the same modules prod uses, observe alarms, validate teardown — instead of a shadow environment with read-only fidelity.

Operator setup is one-time: AWS Organizations sub-account, bootstrap an IAM user with `AdministratorAccess` *inside* the dev account (the account boundary is the safety wall, so permissive IAM inside it doesn't expand blast radius), add a named profile to `~/.aws/credentials`. Optionally enforce `Environment=<env>` via Organizations tag policy as defense-in-depth for tag-filtered destroy sweeps. State backend can be the same S3 bucket as prod with a different `key` prefix; bucket-level IAM keeps the dev role from writing under `prod/*`.

## Terraform PR Verification Ladder

Tiered review path for any Terraform PR — cheapest first, escalate as confidence builds:

1. **Static (no creds)**: `terraform fmt -check`, per-module `terraform validate -backend=false`, optional `tflint` / `tfsec`. Catches ~80% of issues. Wrap in `infra/bin/check.sh` so any agent can run it allowlisted.
2. **Plan against AWS (read-only)**: requires creds. Use a profile with `ReadOnlyAccess` AWS-managed policy — `terraform plan` only needs reads; write APIs fail at the IAM boundary. Requires `-lock=false` if read-only can't write the DynamoDB lock.
3. **Spot-check the diff**: grep for IAM `Resource: "*"`, hardcoded CIDRs (`0.0.0.0/0`), missing encryption flags, missing `prevent_destroy` on irreplaceable resources, AMI IDs that no longer exist in the target region.
4. **Apply + smoke-test**: only in a sandbox env. The README's runbook is the script.

Cumulative — each tier adds confidence and cost. Don't skip earlier tiers because later ones feel more authoritative.
