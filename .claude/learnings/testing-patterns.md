# Testing Patterns

## Prefer local payload over API response to reduce mock coupling

When code generates a value (e.g., a reference ID) and sends it in an API request, read it back from the local payload object rather than from the API response. This avoids forcing every test mock to echo back that field.

### Example

```typescript
// BAD - reads from API response, every mock must include referenceId
const response = await apiClient.createPayment({ payload: [paymentData] });
const payment = response.payments[0];
return { reference: payment.referenceId };

// GOOD - reads from local payload, mocks don't need to include it
const paymentData = buildPaymentPayload(...);
const response = await apiClient.createPayment({ payload: [paymentData] });
return { reference: paymentData.referenceId };
```

### Why it matters

- Adding a field to the response path requires updating every test mock that returns that response
- Integration tests using HTTP-level mocking are especially painful to update
- The local payload is deterministic and already in scope — no reason to round-trip through the mock

## Testing Response-Returning Validators

When testing Next.js API validator functions that return `Response | null`:

```typescript
// Assert success (null = valid)
expect(validateInput("user@example.com", "email")).toBeNull();

// Assert failure (Response with status and JSON body)
const resp = validateInput("not-valid", "email");
expect(resp).not.toBeNull();
expect(resp!.status).toBe(400);
const body = await resp!.json();
expect(body.error).toContain("Invalid");
```

The `!` non-null assertion is safe after the `not.toBeNull()` check. The `await resp!.json()` is needed because `Response.json()` returns a Promise.

## Invalid Date in jsdom/Node

`new Date("not-a-date").toLocaleTimeString()` does **not** throw in jsdom or Node.js — it returns the string `"Invalid Date"`. This means `try/catch` is insufficient to handle invalid date inputs in formatting functions.

**Fix:** Add an explicit validity check before calling locale methods:

```ts
const d = new Date(iso);
if (isNaN(d.getTime())) return fallback;
return d.toLocaleTimeString(...);
```
