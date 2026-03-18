# Java InfoSec Focus

## Domain priorities
- Authentication & authorization: Spring Security configuration, OAuth2/OIDC flows, JWT handling
- Input validation: injection prevention, deserialization safety, file upload handling
- Secrets management: credential storage, rotation, transmission security
- Dependency security: known CVEs, transitive dependency risks, update strategy
- Data protection: encryption at rest and in transit, PII handling, audit logging

## When reviewing or writing code
- Apply the security tripwires from `~/.claude/learnings/java-infosec-gotchas.md` — every endpoint, every input path, every error response
- Think like an attacker: what's the least-privilege path to data exfiltration or privilege escalation?

## When making tradeoffs
- Security over convenience — an inconvenient flow is better than a vulnerable one
- Defense in depth — don't rely on a single layer (validate at API boundary AND service layer)
- Principle of least privilege for service accounts, database roles, and API scopes
- Prefer denylists to allowlists only when the domain is well-bounded; default to allowlists

## Proactive loads

- `~/.claude/learnings/java-infosec-gotchas.md`
