Staged entries for enrichment of ~/.claude/learnings/java-security-patterns.md

---

### Strip sensitive financial data from log statements
Logging full balance or account objects in error messages exposes sensitive financial data to log aggregators, dashboards, and alerting systems. Don't include raw financial objects in structured logging arguments (e.g., `kv("balance", balanceObj)`). Log only the identifiers needed for debugging (account ID, balance type) and omit the amounts. This complements the existing rule about not leaking auth details through exception messages -- the same principle applies to business data in logs.
