# Architecture Patterns — Batch 13 Staging

Append to `docs/learnings/architecture-patterns.md`.

---

### URL encoding mismatch between HTTP client and request signer causes pagination failures

When an HTTP client (e.g., Unirest, OkHttp) automatically percent-encodes query parameters, the request signer must use `URI.getRawQuery()` (encoded form), not `URI.getQuery()` (decoded form), to compute the signature. The mismatch is especially insidious with pagination tokens containing base64 characters (`+`, `/`, `=`) — the first page works fine because the token is absent, but continuation requests silently fail with signature errors. This generalizes a vendor-specific pattern already documented in `security.md`; the same principle applies to any adapter where signing and transport use different URL representations.
