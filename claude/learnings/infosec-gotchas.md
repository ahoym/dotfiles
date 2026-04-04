Staged entries for enrichment of ~/.claude/learnings/java/infosec-gotchas.md

---

### HMAC signature validation must use constant-time comparison
`String.equals()` is vulnerable to timing attacks (CWE-208) because it short-circuits on first mismatch, leaking information about how many bytes matched. Use `MessageDigest.isEqual()` on raw byte arrays for HMAC validation. Never compare Base64-encoded strings -- the encoding preserves the timing side channel.

### SpEL @PreAuthorize must reference actual method parameter names
`#request` vs `#balanceId` -- an incorrect SpEL variable reference in `@PreAuthorize` may silently bypass authorization. When copy-pasting `@PreAuthorize` annotations between methods, verify that `#paramName` matches the target method's actual parameter names. The expression evaluates against the method signature, not the source method's.

### Automated security scanner false positives on framework-specific behavior
Security bots (and human reviewers agreeing with bots) can flag false CWE violations when they analyze code in isolation without understanding runtime behavior. Example: bot flagged CWE-863 (broken authorization) on Spring Security 6 stacked interceptors -- custom `AuthorizationManagerBeforeMethodInterceptor` returning true doesn't bypass `@PreAuthorize` because both interceptors run in the AOP chain. Treat scanner findings as leads requiring runtime-aware verification, not as confirmed vulnerabilities.
