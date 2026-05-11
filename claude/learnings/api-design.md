Patterns for consistent, secure, and maintainable REST API design including response shapes, validation, security hardening, and contract auditing.
- **Keywords:** REST, response shape, nullable fields, validator extraction, security hardening, Cache-Control, XSS, URI sanitization, idempotency key, discriminated union, OpenAPI, correlation ID, URL encoding, request signing, percent-encoding, HMAC, pagination
- **Related:** ~/.claude/learnings/financial/applications.md, ~/.claude/learnings/testing/testing-patterns.md, ~/.claude/learnings/code-quality-instincts.md, ~/.claude/learnings/python-specific.md

---

## Consistent Response Shapes

Always return the same fields in API responses, even when the value is `null`. Do not suppress optional fields from serialization.

**Why:** Clients can rely on a predictable contract (`if field == null` vs `if "field" in response`). Avoids semantic ambiguity and aligns with OpenAPI/JSON Schema specs where fields are present but nullable.

**When adding an optional field:** Add it with a default of `null`, update test assertions to expect it, and do NOT configure serialization to omit null-valued fields.

## DRY Field Validation

Extract a shared validator helper instead of repeating field-presence checks in every route:

```
validateRequired(data, requiredFields) → error response | null
```

Return an error response listing missing fields, or `null` if all present. Keep manual checks for domain-specific validations (cross-field relationships, format constraints, business rules).

## Security Hardening Patterns for API Routes

- **Suppress error details in production:** Return a generic fallback instead of raw error messages, which may leak internal details
- **Cap user-provided limit parameters:** Always clamp with `min(userValue, hardCap)` to prevent resource exhaustion
- **Encode user-provided values in URL paths:** Prevent path traversal and injection when constructing API URLs
- **`Cache-Control: no-store` for sensitive responses:** Prevent browser/proxy caching of secrets, keys, or tokens
- **Validate domain-specific inputs with try-catch:** Return 400 for invalid inputs instead of unhandled 500
- **Sanitize URIs before rendering as links:** Allowlist `http:`/`https:` protocols before passing user-controlled or external URIs into `<a href>`. A `javascript:` payload executes arbitrary JS on click — stored XSS vector when the URI persists in an external source (database, API, blockchain ledger). Render non-allowlisted URIs as inert text:
  ```tsx
  /^https?:\/\//i.test(uri) ? <a href={uri}>...</a> : <span>{uri}</span>
  ```

## URL Encoding Mismatch in Request Signing

When an HTTP client (e.g., Unirest, OkHttp) automatically percent-encodes query parameters, the request signer must use `URI.getRawQuery()` (encoded form), not `URI.getQuery()` (decoded form), to compute the signature. Especially insidious with pagination tokens containing base64 characters (`+`, `/`, `=`) — the first page works because the token is absent, but continuation requests silently fail with signature errors. Applies to any adapter where signing and transport use different URL representations.

## API Contract Audit Approach

When building a shared API client utility, first audit actual vs documented contract: read every route handler and client consumer, compare actual shapes against docs — they often diverge.

**Normalization strategy:** Start client-side only — build a typed fetch wrapper returning a discriminated union (`{ ok, data } | { ok, error }`). Zero server changes. Server-side envelope wrapping can come later as a separate refactor.

## Validator Return Types: T | Response over Discriminated Unions

For functions that either succeed with a value or fail with an HTTP Response, return `T | Response` directly instead of wrapping in a discriminated union like `{ value: T } | { error: Response }`.

```ts
// Before (3 lines per call site):
const result = walletFromSeed(body.seed);
if ("error" in result) return result.error;
const wallet = result.wallet;

// After (2 lines per call site):
const wallet = walletFromSeed(body.seed);
if (wallet instanceof Response) return wallet;
```

`instanceof Response` is reliable in server-side code. Saves one line per call site and eliminates wrapping/unwrapping ceremony. Works when the success type is a class instance clearly distinguishable from Response.

## Extract Validators Before Extracting Logic

When refactoring route handlers, extract **validation helpers** first. Validation is the most duplicated code across routes, has clear input/output contracts, and is trivially unit-testable. Logic helpers vary more per-route and benefit less from extraction.

Priority order:
1. Shared validators (highest duplication, easiest to test)
2. Response/metadata helpers (e.g., `txFailureResponse`)
3. Transaction-building helpers (most route-specific, extract only when truly duplicated)

## Signature Widening for Validator Inputs

When a validator only reads properties from its input (doesn't need full type safety), accept `unknown` instead of a specific type. Eliminates cast noise at every call site:

```ts
// Before: every caller must cast
validateRequired(body as unknown as Record<string, unknown>, ["seed", "amount"]);

// After: validator handles the cast internally once
export function validateRequired(data: unknown, fields: readonly string[]): Response | null {
  const record = data as Record<string, unknown>;
  // ...
}
```

Only do this for functions that immediately cast internally.

## Centralize Error Maps Near Their Domain

When multiple routes share the same error code → message mapping, extract them into a domain-specific module rather than inlining in each route or dumping into a generic utils file. Keeps error messages consistent and easy to update.

## Token-derived vs param-derived identifiers: API experience tradeoff

For token-authenticated consumers, extracting identifiers (e.g., customerId) from JWT is superior -- fewer parameters, less room for error, no ID mismatch attacks. For unauthenticated flows, it must come from path/query params. Authenticated endpoints should derive identity from the token — don't force callers to pass what you already know. Keep both patterns via separate controller methods rather than degrading the authenticated experience with unnecessary parameters.

## REST endpoint paths should be specific and self-describing

Generic paths like `/address` are ambiguous. Use `/wallet-address` to make the resource type obvious.

## Integration clients should throw on error, not return empty

Returning `Optional.empty()` or null on errors silently swallows failures. The caller loses the ability to distinguish "not found" from "service error." Throw exceptions; return Optional only for legitimate "not found."

## API response completeness against published docs

Cross-reference response DTOs against published API documentation during review. Missing fields are a common silent gap.

## Pass idempotency keys as arguments rather than generating inside clients

Generating `UUID.randomUUID()` inside a client prevents the orchestration layer from reusing the key across correlated operations. Generate at the orchestration layer; clients accept as parameters.

## Log correlation/request IDs in integration client operations

Include correlation/request IDs in all log statements for integration operations. Without this, debugging requires correlating logs by timestamp alone.

## Vendor APIs return errors at multiple levels

Batch-capable APIs (broker order placement, bulk imports, batch S3 ops) return errors at TWO levels: top-level `errors` array AND per-record `error` fields within the result array. The envelope can succeed (HTTP 200, no top-level errors) while individual items fail (per-order `Error: "Insufficient buying power"`). The top-level check is obvious; the per-record sweep is easy to miss. Implement both checks for any multi-record API and surface per-record failures at WARN/ERROR (not DEBUG) — they're rejection signals, not noise.

## Log full failed-record envelope, not just the named error field

When logging per-record failures from a batch API, log the entire failed record dict — not just `record["Error"]` or `record["Message"]`. APIs commonly attach diagnostic fields (`RejectReason`, `Code`, `Hint`, echoed request fields) alongside the terse error code. Logging only the named field drops them silently — production rejections then require a separate forensics fetch to recover the actual reason.

```python
# Bad — drops RejectReason / Status / echoed request data
logger.error("API error on %s: %s", record["id"], record["Error"])

# Good — full record captures any diagnostic fields the API attaches
logger.error("API error on %s: %s | full record: %s", record["id"], record["Error"], record)
```

Default to full-record logging on failure paths. Cost is bytes; value is debug-time when remote-side reasons aren't predictable in advance.

## Single-resource APIs can return 200 with error envelope replacing the payload

Sibling to the batch case above, at envelope level. A vendor may return `200 OK` with `{"Error": "Failed", "Message": "..."}` *instead of* the expected `{"Bars": [...]}` payload — no expected field at all. `data.get("Bars") or []` collapses to "empty data" and validators never see the error; `raise_for_status()` doesn't catch this since HTTP is 200. Common with entitlement gates and rate limits.

Validate shape positively before defaulting:

```python
if "Error" in data or "Bars" not in data:
    raise RuntimeError(f"vendor error: {data.get('Message', data)}")
```

## Adapter and client layers can have separate validation tiers

When wrapping a vendor API behind an adapter (BrokerAdapter → VendorClient), the two layers often enforce different symbol/input regexes — adapter validation is typically stricter than client validation because each layer covers a different surface. The client may accept symbol form X for data endpoints while the adapter rejects X for order placement, both correctly mirroring vendor semantics (e.g., continuous futures symbols are queryable but not orderable). Before concluding "the wrapper rejects X," trace which call path the validation actually runs on — single-regex assumptions miss this layered pattern.

## Backward-Compat Defaults: Remove When No Caller Depends On Them

A "backward-compat default" added during a refactor (`def f(x, y, *, margin=MNQ_MARGIN_PER_CONTRACT)`) becomes load-bearing the moment any future caller relies on it. If existing callers all pass the value explicitly, the default never served its purpose — and now hides what looks like genericity behind a domain-specific value (a module *appears* generic but silently uses contract-specific constants). Two-step API evolution: add with default → verify all callers pass explicitly → remove the default. The honest signature forces new callers to be explicit about domain-specific constants instead of inheriting silent ones.

## Cross-Refs

- `~/.claude/learnings/financial/applications.md` — idempotency patterns
- `~/.claude/learnings/testing/testing-patterns.md` — validator and route handler testing
- `~/.claude/learnings/code-quality-instincts.md` — parameter naming conventions
- `~/.claude/learnings/python-specific.md` — Pydantic v2 serialization options for the "consistent shapes" principle
