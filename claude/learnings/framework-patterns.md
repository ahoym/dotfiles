Framework-specific patterns: AWS SDK v2 migration, Spring profile configuration.
- **Keywords:** AWS SDK v2, retryPolicy, retryStrategy, Spring Profile, IAM, credentials, configuration
- **Related:** ~/.claude/learnings/java-spring-configuration.md

---

### AWS SDK v2: `retryPolicy` is deprecated — use `retryStrategy` with `maxAttempts`

`RetryPolicy.builder().numRetries(N)` is deprecated in AWS SDK v2. Replace with `.retryStrategy(b -> b.maxAttempts(N + 1))` where `maxAttempts` equals retries plus the initial attempt. The off-by-one between retries and attempts is easy to miss — `numRetries(3)` means 4 total attempts, so the equivalent is `maxAttempts(4)`.

### Spring `@Profile` annotations must cover all non-IAM environments

When a `@Configuration` class provides a non-IAM fallback (e.g., static credentials instead of STS/IRSA), its `@Profile` must include every environment where IAM is unavailable — not just `"dev"`. Missing a profile (e.g., `"integration"` or `"local"`) silently activates the IAM-based production config, which fails with opaque credential errors. Audit `@Profile` annotations on credential provider configs whenever a new environment or profile is introduced.
