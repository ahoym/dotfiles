# API Design Guidelines

## Consistent Response Shapes

Always return the same fields in API responses, even when the value is `null`. Do not use `exclude_none=True` or `response_model_exclude_none=True` to hide optional fields.

**Why:**
- Clients can rely on a predictable contract (`if field is None` vs `if field in response`)
- Avoids semantic ambiguity between "field absent" and "field is null"
- Aligns with OpenAPI/JSON Schema specs where the field is always present, just nullable
- Follows major API guidelines (Google, Microsoft, Stripe)

**When adding a new optional field to a response model:**
1. Add the field with `Optional[X] = None` in the Pydantic model
2. Update test assertions to expect the new field with `None` value
3. Do NOT add `ConfigDict(exclude_none=True)` to suppress it

**Example:** Adding `reference: Optional[str] = None` to a response model — the fix was updating test assertions to include `"reference": None`, not hiding the field from serialization.
