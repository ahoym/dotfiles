Security tripwires — check these before any code review or implementation.
- **Keywords:** authentication, authorization, CORS, deserialization, Jackson, XXE, input validation, secrets, stack traces, crypto, Spring Security, @PreAuthorize, method security, helper visibility, private method
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

## Cross-Refs

- `~/.claude/learnings/api-design.md` — API security hardening, input validation, error contracts
