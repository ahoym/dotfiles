Java integration: gRPC proto builder null handling, Spring Security 6 interceptor stacking.
- **Keywords:** gRPC, proto, builder, NullPointerException, null check, Protobuf, Spring Security 6, EnableMethodSecurity, AuthorizationManagerBeforeMethodInterceptor, PreAuthorize, AOP
- **Related:** ~/.claude/learnings/protobuf-patterns.md

---

### gRPC proto builders NPE on null string fields

Proto builders throw `NullPointerException` on `.setX(null)` for string fields. Always null-check before calling the setter in Java-to-proto translation. Pattern: `if (value != null) { builder.setField(value); }`. This applies to all proto string, bytes, and message fields — the builder contract requires non-null values.

### Spring Security 6 @EnableMethodSecurity stacked interceptors

Custom `AuthorizationManagerBeforeMethodInterceptor` registered with a different bean name COEXISTS with the default `preAuthorizeAuthorizationMethodInterceptor`. Both run in the AOP chain. A custom interceptor returning `GRANTED` does not bypass `@PreAuthorize` — each interceptor evaluates independently, and all must pass. This is counterintuitive because it looks like the custom interceptor replaces the default, but Spring Security 6's method security uses an additive interceptor model.
