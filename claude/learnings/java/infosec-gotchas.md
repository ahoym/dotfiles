Security tripwires — check these before any code review or implementation.
- **Keywords:** authentication, authorization, CORS, deserialization, Jackson, XXE, input validation, secrets, stack traces, crypto, Spring Security, @PreAuthorize, method security, helper visibility, private method, HMAC, timing attack, CWE-208, SpEL, security scanner, false positive, logging, PII, financial data, SSL, TLS, certificate, trust store, SSLContext, KeyStore, cert pinning, test security
- **Related:** ~/.claude/learnings/api-design.md

---

- Flag any endpoint missing authentication or authorization checks
- Validate and sanitize user input before use in queries, commands, or responses
- Watch for unsafe deserialization: Jackson polymorphic typing, XML external entities
- Error responses must not leak stack traces, internal paths, or version info
- Question any custom crypto — prefer standard library implementations
- CORS configuration must be restrictive, not wildcard
- Flag any secret or credential in source, logs, or error messages

### Internal helper methods on Spring beans must be `private` to prevent authorization bypass

Spring Security's method-level interceptors (`@PreAuthorize`, `@Secured`, etc.) only wrap the entry point bean method — they are not applied to internal calls within the same bean or to helper methods that other beans call directly. A public helper on a secured Spring service is callable by other beans without any security checks applied.

Mark any internal helper that should only be invoked through a secured entry point as `private`. If the helper needs to be shared across beans, extract it into a separate unsecured utility service and ensure all callers go through the secured entry point.

### HMAC signature validation must use constant-time comparison
`String.equals()` is vulnerable to timing attacks (CWE-208) because it short-circuits on first mismatch, leaking information about how many bytes matched. Use `MessageDigest.isEqual()` on raw byte arrays for HMAC validation. Never compare Base64-encoded strings — the encoding preserves the timing side channel.

### SpEL @PreAuthorize must reference actual method parameter names
`#request` vs `#balanceId` — an incorrect SpEL variable reference in `@PreAuthorize` may silently bypass authorization. When copy-pasting `@PreAuthorize` annotations between methods, verify that `#paramName` matches the target method's actual parameter names. The expression evaluates against the method signature, not the source method's.

### Automated security scanner false positives on framework-specific behavior
Security bots can flag false CWE violations when they analyze code in isolation without understanding runtime behavior. Example: bot flagged CWE-863 on Spring Security 6 stacked interceptors — custom `AuthorizationManagerBeforeMethodInterceptor` returning true doesn't bypass `@PreAuthorize` because both interceptors run in the AOP chain. Treat scanner findings as leads requiring runtime-aware verification, not as confirmed vulnerabilities.

### Strip sensitive financial data from log statements
Logging full balance or account objects in error messages exposes sensitive financial data to log aggregators, dashboards, and alerting systems. Don't include raw financial objects in structured logging arguments (e.g., `kv("balance", balanceObj)`). Log only identifiers needed for debugging (account ID, balance type) and omit amounts.

### Replace trust-all-certs with cert-pinned SSLContext in tests

Even in test code, `TrustAllCerts` / no-op `TrustManager` implementations mask certificate rotation and validation issues that would surface in production. Load the actual test certificate into a `KeyStore`, build a proper `SSLContext` from it, and use that in test HTTP clients. This catches cert expiry, chain issues, and hostname mismatches during the test cycle rather than after deployment.

## Cross-Refs

- `~/.claude/learnings/api-design.md` — API security hardening, input validation, error contracts
