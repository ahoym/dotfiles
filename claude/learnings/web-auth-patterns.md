Web authentication patterns: cross-subdomain session sharing, cookie attributes, CSRF, and browser cookie behavior.
- **Keywords:** cookie, domain, sameSite, lax, strict, httpOnly, CSRF, csrf-csrf, double-submit, cross-subdomain, localhost, port, JWT, clearCookie, rollout
- **Related:** ~/.claude/learnings/nginx-patterns.md

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

## `__Secure-` prefix requires HTTPS — silent failure on HTTP

Cookies with the `__Secure-` prefix are browser-enforced: the browser silently refuses to set them over HTTP. No server-side error, no application log. Local dev over HTTP breaks invisibly when a cookie is renamed from `my-jwt` to `__Secure-my-jwt`. The `secure: true` flag alone was already required but only advisory without the prefix — with `__Secure-`, HTTPS becomes mandatory at the browser level.

## CORS: always assert `Vary: Origin` alongside `Access-Control-Allow-Origin`

`Vary: Origin` instructs CDN/proxy caches to maintain per-origin response variants. Without it, a cached response for `origin-a.com` may be served to `origin-b.com`, causing cross-origin cache poisoning. Standard pattern: whenever testing or asserting that `Access-Control-Allow-Origin` is set, also verify `Vary: Origin` is present.

## `csrf-csrf` double-submit pattern

The `csrf-csrf` npm package implements the double-submit cookie pattern:
- Sets a CSRF cookie (`psifi.x-csrf-token` by default — override with the `cookieName` option) on each response
- Expects the token in the `x-csrf-token` request header on mutating requests
- Validates only that **cookie value matches header value** — no Host, Origin, or Referer validation
- `GET`, `HEAD`, `OPTIONS` are exempt by default (`ignoredMethods`)

**What this means for nginx proxying:** changing the `Host` header (via `proxy_set_header Host $host`) does not break CSRF validation. The token comparison is purely value-based.

**`sameSite` is about site, not origin.** `sameSite: 'strict'` works for sibling subdomains because they are cross-origin but **same-site** (same eTLD+1). A `fetch()` from `finance.prod.example.com` to `api.prod.example.com` is same-site — the browser sends `strict` cookies. `sameSite: 'none'` is only needed for truly **cross-site** requests (different eTLD+1, e.g. `evil.com` → `example.com`). Don't confuse the two — changing to `'none'` unnecessarily weakens the CSRF boundary.

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

## OAuth bootstrap script error paths can leak credentials

Error handlers that dump API response data — `print(response.text)`, `json.dumps(token_data, indent=2)`, generic exception loggers — leak tokens when the response is partially-successful. Example: `offline_access` scope is excluded; the response has `access_token` but not `refresh_token`. The script's "missing refresh_token" branch fires and dumps the body, exposing `access_token` to terminal/CI history.

Defense-in-depth for any error handler that touches an API response containing credentials:

```python
# BAD: dumps full body including tokens
print(f"Unexpected response: {json.dumps(token_data, indent=2)}")

# GOOD: field names only, never values
print(f"Unexpected response keys: {list(token_data.keys())}")
```

Pair with `urlparse(url).netloc == ...` validation on the redirect URI (see `code-quality-instincts.md` → URL allow-listing) — these tend to coexist in OAuth scripts and break together.

## IdP redirects are navigations, not CORS requests

OAuth/OIDC login flows (redirect to Okta → authenticate → callback) are full browser navigations. CORS middleware and CSRF middleware never see them — browsers only enforce CORS on programmatic requests (fetch, XHR). This means: sharing auth sessions across subdomains via domain-scoped cookies works without CORS configuration for the login flow itself. CORS only matters when sibling subdomains make API calls (fetch) to the backend after authentication.

## `__Secure-` prefix: conditional pattern for HTTP local dev

```typescript
const cookieName = isProduction ? '__Secure-my-jwt' : 'my-jwt';
```

When local dev runs on HTTP, use the `__Secure-` prefix only in production. The fallback read path (`req.cookies[cookieName] ?? req.cookies['my-jwt']`) covers the rename transition in production while being a no-op in dev (where `cookieName` is already `'my-jwt'`).

## `__Host-` prefix on CSRF cookies prevents cookie tossing

`__Host-` enforces `Secure`, `Path=/`, and **no `Domain` attribute** — the browser rejects `__Host-` cookies with a domain. This prevents a compromised sibling subdomain from "tossing" a forged CSRF cookie onto the parent domain. Use conditionally like `__Secure-`:

```typescript
const CSRF_COOKIE_NAME = isProduction ? '__Host-my-app.x-csrf-token' : 'my-app.x-csrf-token';
```

## CSRF is per-backend — don't domain-scope the CSRF cookie

CSRF secret, cookie, and session are all host-scoped. When a sibling subdomain frontend fetches from a backend, the browser sets and sends the CSRF cookie on the *backend's* host automatically. Domain-scoping the CSRF cookie (`domain: '.example.com'`) is unnecessary and harmful — it enables cookie tossing attacks. Host-only is the correct and tighter posture.

## Origin-scoped CSRF tokens for multi-subdomain blast radius reduction

Bind CSRF tokens to the requesting `Origin` so a compromised sibling subdomain can't replay tokens from another:

```typescript
getSessionIdentifier: req => `${req.session?.id}:${req.headers.origin || 'same-origin'}`
```

Same-origin requests use `'same-origin'` literal — tokens obtained without `Origin` only validate on requests without `Origin`. Different origins produce different HMACs.

## `csrf-csrf` npm library defaults

`httpOnly: true`, cookie name `__Host-psifi.x-csrf-token`, `sameSite: 'lax'`, `secure: true`. Uses hash-in-cookie + token-in-JSON pattern (not cookie-to-header). Client gets the token from `GET /csrf-token` JSON response; no need to read the cookie via JS. This means `httpOnly` can (and should) stay on.

## Hardcoded vs env-var security allowlists

Hardcoding an allowlist in source provides no additional security over env-var configuration when both the source bundle and env vars live in the same deployment artifact (e.g. K8s pod). The trust boundary is the deployment pipeline, not the code. Env vars are preferable for values that change per environment or per service onboarding (e.g. CORS origins). Reserve hardcoding for values that are truly fixed across all environments and where the operational cost of code changes is acceptable (e.g. cookie domain allowlists with a small, stable set).
