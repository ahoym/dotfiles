# Testing Patterns

## Cross-Implementation Test Fixtures

When server and client independently implement the same encoding (e.g., server uses `Buffer.from().toString("hex")`, client uses `TextEncoder` + `Array.from`), test both against **shared known input/output pairs** to catch drift.

**Pattern:**
- Define a set of canonical fixtures: `"KYC"` → `"4B5943"`, `"AML Check"` → `"414D4C20436865636B"`
- Server test suite asserts `encodeServerSide("KYC") === "4B5943"`
- Client test suite asserts `encodeClientSide("KYC") === "4B5943"` (same expected value)
- If either implementation drifts, its tests fail independently

**Why not share code?** Server-only APIs (e.g., Node `Buffer`) aren't available in the browser. Separate implementations are correct — but they need to agree on outputs.

**When to use:** Any time you have parallel encode/decode, hash, or serialization logic across server/client boundaries. Common in: credential encoding, currency formatting, signature verification.

## Prefer local payload over API response to reduce mock coupling

When code generates a value (e.g., a reference ID) and sends it in an API request, read it back from the local payload object rather than from the API response. This avoids forcing every test mock to echo back that field.

### Example

```python
# BAD - reads from API response, every mock must include referenceId
response = api_client.create_payment(payload=[payment_data], ...)
payment = response["payments"][0]
return PaymentResult(reference=payment["referenceId"])

# GOOD - reads from local payload, mocks don't need to include it
payment_data = self.build_payment_payload(...)
response = api_client.create_payment(payload=[payment_data], ...)
return PaymentResult(reference=payment_data.get("referenceId"))
```

### Why it matters

- Adding a field to the response path requires updating every test mock that returns that response
- Integration tests using HTTP-level mocking (e.g., `responses` library) are especially painful to update
- The local payload is deterministic and already in scope — no reason to round-trip through the mock
