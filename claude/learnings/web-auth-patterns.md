Web authentication patterns: cross-subdomain session sharing, cookie attributes, CSRF, and browser cookie behavior.
- **Keywords:** cookie, domain, sameSite, lax, strict, httpOnly, CSRF, csrf-csrf, double-submit, cross-subdomain, localhost, port, JWT, clearCookie, rollout
- **Related:** ~/.claude/learnings/security.md, ~/.claude/learnings/infosec-gotchas.md, ~/.claude/learnings/nginx-patterns.md

---

## Cross-subdomain cookie sharing

To share a JWT cookie between sibling subdomains (e.g. `app.prod.example.com` and `api.prod.example.com`):

1. **Set `domain` to the narrowest shared parent** — e.g. `.prod.example.com`. Omitting `domain` creates a host-only cookie visible only to the exact host.
2. **Switch `sameSite` from `strict` to `lax`** — `strict` suppresses the cookie on top-level redirects from one subdomain to another (e.g. post-Okta redirect back to app). `lax` allows it on top-level GET navigations while still blocking cross-site subresource requests.
3. **Call `clearCookie` before setting** — prevents dual-cookie collision during rollout. The browser treats `name` (host-only) and `name` on `.prod.example.com` as distinct cookies. Clearing the old one ensures only the parent-domain cookie persists after re-login.

```typescript
// Express example
res.clearCookie(cookieName);  // evicts old host-only cookie
res.cookie(cookieName, token, {
  httpOnly: true,
  secure: true,
  sameSite: 'lax',
  domain: process.env.COOKIE_DOMAIN,  // e.g. ".prod.example.com"
});
```

**Rollout safety:** users with existing host-only sessions are unaffected (old cookie still works until expiry). On next login, `clearCookie` evicts the old cookie and they get the parent-domain cookie. Undetectable to users.

**Per-environment config:**
- prod: `.prod.example.com`
- staging: `.staging.example.com`
- local: unset — see localhost section below

## Localhost cookies are port-agnostic

Cookies set by `localhost:4000` are sent to `localhost:3000` (and any other localhost port). Port is not part of the cookie scope. Setting `Domain=localhost` is rejected or unreliable in most browsers.

**Implication:** for local development where a backend (port 4000) and frontend (port 3000) need to share cookies, leave `COOKIE_DOMAIN` unset. The browser automatically sends the cookie across ports.

## `csrf-csrf` double-submit pattern

The `csrf-csrf` npm package implements the double-submit cookie pattern:
- Sets a CSRF cookie (`LH.x-csrf-token` by default) on each response
- Expects the token in the `x-csrf-token` request header on mutating requests
- Validates only that **cookie value matches header value** — no Host, Origin, or Referer validation
- `GET`, `HEAD`, `OPTIONS` are exempt by default (`ignoredMethods`)

**What this means for nginx proxying:** changing the `Host` header (via `proxy_set_header Host $host`) does not break CSRF validation. The token comparison is purely value-based.

**Client-side requirement:** the SPA must fetch the token from `/csrf-token` (GET, CSRF-exempt) and attach it as `x-csrf-token` on all POST/PUT/PATCH/DELETE requests.

```typescript
// Axios interceptor pattern
let csrfToken: Promise<string> | null = null;
const getCsrfToken = () => {
  if (!csrfToken) csrfToken = apiClient.get('/csrf-token').then(r => r.data.token);
  return csrfToken;
};
apiClient.interceptors.request.use(async (config) => {
  if (['post','put','patch','delete'].includes(config.method ?? '')) {
    config.headers['x-csrf-token'] = await getCsrfToken();
  }
  return config;
});
```
