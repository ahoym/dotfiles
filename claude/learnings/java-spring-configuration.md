Spring Security 6: method security interceptor stacking and @EnableMethodSecurity behavior.
- **Keywords:** Spring Security 6, EnableMethodSecurity, AuthorizationManagerBeforeMethodInterceptor, PreAuthorize, AOP
- **Related:** ~/.claude/learnings/infosec-gotchas.md

---

### Spring Security 6 @EnableMethodSecurity stacked interceptors
Custom `AuthorizationManagerBeforeMethodInterceptor` registered with a different bean name COEXISTS with the default `preAuthorizeAuthorizationMethodInterceptor`. Both run in the AOP chain. A custom interceptor returning `GRANTED` does not bypass `@PreAuthorize` -- each interceptor evaluates independently, and all must pass. This is counterintuitive because it looks like the custom interceptor replaces the default, but Spring Security 6's method security uses an additive interceptor model.
