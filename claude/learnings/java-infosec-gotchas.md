# Java InfoSec Gotchas

Security tripwires — check these before any code review or implementation.
**Keywords:** authentication, authorization, CORS, deserialization, Jackson, XXE, input validation, secrets, stack traces, crypto
**Related:** api-design.md

---

- Flag any endpoint missing authentication or authorization checks
- Validate and sanitize user input before use in queries, commands, or responses
- Watch for unsafe deserialization: Jackson polymorphic typing, XML external entities
- Error responses must not leak stack traces, internal paths, or version info
- Question any custom crypto — prefer standard library implementations
- CORS configuration must be restrictive, not wildcard
- Flag any secret or credential in source, logs, or error messages

## Cross-Refs

- `~/.claude/learnings/api-design.md` — API security hardening, input validation, error contracts
