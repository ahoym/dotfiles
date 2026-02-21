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
