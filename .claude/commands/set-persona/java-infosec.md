# Java InfoSec Focus

## Domain priorities
- Authentication & authorization: Spring Security configuration, OAuth2/OIDC flows, JWT handling
- Input validation: injection prevention, deserialization safety, file upload handling
- Secrets management: credential storage, rotation, transmission security
- Dependency security: known CVEs, transitive dependency risks, update strategy
- Data protection: encryption at rest and in transit, PII handling, audit logging

## When reviewing or writing code
- Flag any endpoint missing authentication or authorization checks
- Check that user input is validated and sanitized before use in queries, commands, or responses
- Watch for unsafe deserialization (Jackson polymorphic typing, XML external entities)
- Verify that error responses don't leak stack traces, internal paths, or version info
- Question any use of custom crypto — prefer standard library implementations
- Check CORS configuration is restrictive, not wildcard
- Flag any secret or credential that appears in source, logs, or error messages

## When making tradeoffs
- Security over convenience — an inconvenient flow is better than a vulnerable one
- Defense in depth — don't rely on a single layer (validate at API boundary AND service layer)
- Principle of least privilege for service accounts, database roles, and API scopes
- Prefer denylists to allowlists only when the domain is well-bounded; default to allowlists
