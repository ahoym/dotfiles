# API Design Guidelines

## Consistent Response Shapes

Always return the same fields in API responses, even when the value is `null`/`None`. Do not suppress optional fields from serialization output.

**Why:**
- Clients can rely on a predictable contract (`if field == null` vs `if "field" in response`)
- Avoids semantic ambiguity between "field absent" and "field is null"
- Aligns with OpenAPI/JSON Schema specs where the field is always present, just nullable
- Follows major API guidelines (Google, Microsoft, Stripe)

**When adding a new optional field to a response model:**
1. Add the field with a default of `null`/`None`/`undefined`
2. Update test assertions to expect the new field with its null value
3. Do NOT configure serialization to omit null-valued fields

**Example:** Adding an optional `reference` field to a response model — the fix was updating test assertions to include `"reference": null`, not hiding the field from serialization.

## validateRequired() Helper for DRY Field Validation

Instead of repeating manual field-presence checks in every POST route, extract a shared helper:

```typescript
export function validateRequired(
  data: Record<string, unknown>,
  fields: string[],
): Response | null {
  const missing = fields.filter((f) => !data[f]);
  if (missing.length > 0) {
    return Response.json(
      { error: `Missing required fields: ${missing.join(", ")}` },
      { status: 400 },
    );
  }
  return null;
}
```

The `as unknown as Record<string, unknown>` cast is needed when the body is typed as a specific request interface. Keep manual checks for domain-specific validations beyond field presence (array length bounds, cross-field relationships, wallet address mismatches).

## Security Hardening Patterns for API Routes

- **Suppress error details in production:** Use `process.env.NODE_ENV === "production"` to return a generic fallback instead of raw `err.message`, which may leak internal details
- **Cap user-provided limit parameters:** Always clamp with `Math.min(userValue, hardCap)` to prevent resource exhaustion
- **Use `encodeURIComponent()` for URL path segments:** When constructing API URLs with user-provided values (e.g., addresses)
- **`Cache-Control: no-store` for sensitive responses:** Prevent browser/proxy caching of wallet seeds, keys
- **Validate seeds with try-catch around `Wallet.fromSeed()`:** Return 400 for invalid seeds instead of unhandled 500

## API Contract Audit Approach

When building a shared API client utility (e.g., `apiFetch<T>`), first audit actual vs documented contract: read every route handler and client consumer, compare actual shapes against docs — they often diverge.

**Normalization strategy:** Start client-side only — build `apiFetch<T>` returning `ApiResult<T> = { ok: true; data: T } | { ok: false; error: string }`. Zero server changes, `data` is the full JSON body typed as `T`. Server-side envelope wrapping (`{ data: T }`) can come later as a bigger refactor touching every route.
