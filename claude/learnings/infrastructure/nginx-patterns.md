nginx SPA hosting patterns, Vite base path handling, proxy config, and header inheritance gotchas.
- **Keywords:** nginx, alias, try_files, add_header, named location, SPA, Vite, base path, proxy_pass, security headers, asset caching, capture group
- **Related:** ~/.claude/learnings/frontend/react-frontend-gotchas.md, ~/.claude/learnings/web-auth-patterns.md

---

## `alias` + `try_files`: fallback resolves against `root`, not `alias`

`try_files` fallback paths (e.g. `/index.html`) always resolve against the server `root`, even inside an `alias` location. For SPA catch-all routing, use a named location:

```nginx
location /app/ {
    alias /var/www/build/;
    try_files $uri $uri/ @spa;  # fallback goes to named location, not alias
}

# Named location uses root directly — avoids the alias/root mismatch
location @spa {
    root /var/www/build;
    try_files /index.html =404;
}
```

**Never** write `try_files $uri $uri/ /index.html` inside an `alias` block — nginx looks for `/var/www/build/index.html` but at the wrong path (root + /index.html, not alias + /index.html).

## `add_header` is NOT inherited by named locations

Named locations (`@name`) are independent contexts. They do NOT inherit `add_header` from the enclosing `location` block. Security headers must be included explicitly in every named location that serves responses to browsers:

```nginx
location /app/ {
    alias /var/www/build/;
    include /etc/nginx/conf.d/security-headers.conf;  # applies here
    try_files $uri $uri/ @spa;
}

location @spa {
    root /var/www/build;
    include /etc/nginx/conf.d/security-headers.conf;  # MUST repeat — not inherited
    try_files /index.html =404;
}
```

Omitting `include` in `@spa` silently strips all security headers from SPA fallback responses.

## Vite base path + nginx: alias + capture-group regex

When Vite is built with `base: '/sub-path/'`, all asset references use that prefix. nginx's `root` won't resolve them — use `alias` with a capture group to strip the prefix:

```nginx
# Serve the SPA at its Vite base path
location /sub-path/ {
    alias /var/www/build/;
    try_files $uri $uri/ @spa;
}

# Long-lived cache for hashed assets — capture group strips base prefix
location ~* ^/sub-path/(.+\.(js|css|svg|woff2|woff|ttf))$ {
    alias /var/www/build/$1;
    add_header Cache-Control "public, max-age=31536000";
}

# Redirect bare root to the app base (use 302 — 301 caches permanently)
location = / {
    return 302 /sub-path/;
}
```

**Trailing slashes matter:** `location /sub-path/` + `alias /build/` — both must have trailing slashes or nginx produces double-slash URLs.

## proxy_pass with vs without trailing slash

```nginx
# Strips location prefix — /api/foo/bar → /bar on upstream
location /api/foo/ {
    proxy_pass http://upstream/;
}

# Preserves full URI — /api/foo/bar → /api/foo/bar on upstream
location /api/foo/ {
    proxy_pass http://upstream;
}
```

Use no trailing slash when the upstream expects the full path (e.g. auth endpoints like `/login-okta`).
