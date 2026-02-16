---
description: Run a security audit on one or more projects using parallel agents
---

# Security Audit

Run a structured security audit on one or more projects. Uses parallel agents to check a standard security checklist, flags dead security code, and assesses the deployment risk profile.

## Usage

- `/do-security-audit` - Audit the current project
- `/do-security-audit <path>` - Audit a specific project
- `/do-security-audit <path1> <path2>` - Compare two projects side-by-side

## Instructions

### 1. Identify target project(s)

**Single project** (default): Use the current working directory or provided path.

**Multiple projects**: Parse space-separated paths. Enable comparison mode.

### 2. Run security checklist

Launch parallel Explore subagents — one per project — with this checklist:

- API input validation
- Secret/credential handling and transmission
- CSP and security headers
- Rate limiting (implemented AND wired up?)
- CORS / origin checks
- Dependency versions (outdated or vulnerable)
- Error message leakage (dev vs prod)

Each agent should report findings per checklist item with severity (Critical / High / Medium / Low / Info).

### 3. Check for dead security code

Flag code that exists but is never called. An implemented-but-unwired rate limiter is worse than no rate limiter — it creates false confidence.

Look for:
- Security middleware defined but not mounted
- Validation functions that are imported but never invoked
- Environment-gated security checks that are always bypassed in the current config

### 4. Assess deployment risk profile

Evaluate the deployment context to calibrate severity:
- What environment does this target? (local dev, staging, production)
- Does it handle sensitive data? (credentials, financial data, PII)
- Is it public-facing or internal?
- What's the blast radius of a compromise?

Security choices acceptable in one context (e.g., plaintext tokens in dev) become critical in another (e.g., production with real user data).

### 5. Compare findings (multi-project mode only)

When auditing multiple projects, compare findings side-by-side:
- **Shared vulnerabilities** — present in both projects
- **Unique to each** — present in only one
- **Improvements** — issues in one that are fixed in the other
- **Risk profile differences** — different deployment contexts change what matters

### 6. Report

Present findings in a structured report:

```
## Security Audit: <project name(s)>

### Summary
- Critical: N | High: N | Medium: N | Low: N

### Findings

#### [Critical] <title>
- **Location**: <file:line>
- **Description**: ...
- **Recommendation**: ...

...

### Dead Security Code
- <file:line> — <description>

### Risk Profile
- Deployment context: ...
- Sensitive data: ...
- Calibration notes: ...
```

## Important Notes

- This is a surface-level automated audit, not a penetration test
- Always recommend professional security review for production systems handling sensitive data
- The checklist covers common web application concerns — extend it for domain-specific risks (e.g., blockchain, financial, healthcare)
