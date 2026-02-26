# API Design Guidelines

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

## API Contract Audit Approach

When building a shared API client utility, first audit actual vs documented contract: read every route handler and client consumer, compare actual shapes against docs — they often diverge.

**Normalization strategy:** Start client-side only — build a typed fetch wrapper returning a discriminated union (`{ ok, data } | { ok, error }`). Zero server changes. Server-side envelope wrapping can come later as a separate refactor.

## XRPL `amm_info` Asset Order Normalization

`amm_info` may return `amount`/`amount2` in a different order than the `asset`/`asset2` requested. Always match the response amounts by currency+issuer to determine which is base vs quote, rather than assuming positional correspondence.

```ts
const amount1IsBase =
  amount1.currency === baseCurrency &&
  (baseCurrency === "XRP" || amount1.issuer === baseIssuer);
const base = amount1IsBase ? amount1 : amount2;
const quote = amount1IsBase ? amount2 : amount1;
```
