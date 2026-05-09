Calculation safety, idempotency, decimal precision, and fee logic patterns for financial and payment systems.
- **Keywords:** BigDecimal, DECIMAL precision, fee calculation, idempotency, FeeMode, division by zero, null safety, currency enum, vendor separation, off-by-one, settlement cutoff
- **Related:** ~/.claude/learnings/resilience-patterns.md

---

### Never silently default monetary calculations to zero on error

When fee calculations or amount transformations throw exceptions, failing silently with a zero or pass-through value can cause transactions to process incorrectly (e.g., zero fees). Always fail loudly — throw, log, or block the transaction.

### Stubbed financial logic should throw, not return defaults

If a fee mode or calculation path isn't implemented yet, throw `NotImplementedException` rather than returning the original amount. Returning incorrect values from stubbed financial logic can silently propagate through the system.

### FeeMode semantics: INCLUDED vs EXCLUDED

`INCLUDED` = seller pays fees (fee deducted from gross), `EXCLUDED` = buyer pays fees (fee added on top). Core invariant: `Gross = Net + Fee`. Both modes must be tested explicitly.

### Proportional fee calculation requires zero-amount guards

When distributing fees across multiple transactions proportionally (`txFee = (txAmount / grossAmount) * totalFee`), always guard against division by zero on the gross amount. This is easy to miss when the formula looks simple.

### Side-effect-laden read operations are a design risk in financial systems

Query methods that compute derived state and mutate the entity as a side effect (e.g., auto-completing a transfer when `amountRemaining` reaches zero during a read) violate command-query separation. In financial systems this is especially dangerous — reads should never trigger state transitions.

### Two-layer idempotency for payment systems

Caller provides a `clientReference` (business-level idempotency — "did I already submit this settlement?"). The payment service uses the same reference as the vendor's `Idempotency-Key` header (infrastructure-level — "don't duplicate the bank payment"). This makes retries safe at both levels: caller can safely re-POST, and the service can safely retry vendor calls.

### Domain vs vendor enum separation in payment integrations

Maintain a domain `Currency` enum that's vendor-agnostic. Map to vendor-specific enums (`AcmeCurrency`, future vendor codes) only at the provider boundary. Same applies to payment types, statuses, and account identifiers. Prevents vendor coupling from leaking into domain models and makes adding new vendors a provider-layer change only.

### Off-by-one in date/time cutoff calculations

Settlement cutoff used `.minusDays(1).withHour(6)` instead of `.withHour(6)`, shifting the window by 24 hours. Date arithmetic off-by-ones are a recurring pattern in financial systems -- always trace through concrete examples with real dates to verify the window boundaries.

### DECIMAL precision for financial schemas: use (38, 18)

`DECIMAL(38, 18)` is the standard for financial systems handling crypto assets:
- **38 total digits** — max portable precision across SQL Server, Oracle, and PostgreSQL
- **18 decimal places** — covers the most demanding case (ERC-20 tokens), with 20 integer digits (quadrillions)
- **Java BigDecimal** — JDBC/Hibernate map `DECIMAL(38, x)` cleanly; larger precisions work but are non-standard ORM territory
- **Storage** — PostgreSQL uses ~2 bytes per 4 decimal digits; `(80, 30)` roughly doubles per-row cost with no practical benefit

No currency standard requires >18 decimals (XRP=6, fiat=2-4, Ethereum=18). For intermediate FX rate calculations, compute in BigDecimal and persist only the final amount.

### Null Safety in BigDecimal Stream Reductions and Arithmetic

Nullable fields throw NPE in `reduce(BigDecimal.ZERO, BigDecimal::add)`. Add `.filter(Objects::nonNull)` or use `Optional.ofNullable().orElse(BigDecimal.ZERO)` before reducing. Extends to individual operations: guard with `BigDecimal.ZERO` before subtraction when methods like `getFeeAmount()` can return null.

## Broker-API `.get(key, default)` fallback direction determines failure mode

When parsing broker responses in retry/order-state logic, the default on a missing field picks the failure semantic:

```python
# Fall back to 0: if remainingQuantity is missing, treat as "fully filled"
remaining = order.get("remainingQuantity", 0)  # ghost fill

# Fall back to full qty: if missing, treat as "nothing filled"
remaining = order.get("remainingQuantity", order.get("quantity", 0))  # spurious cancel
```

Neither default is safe — both create silent, money-moving failure modes. In financial code, prefer `raise ValueError` over any default when a field flows into a fill/cancel/ledger decision. Document the expected broker contract (which fields are always present) and fail loudly on violation.

## `str(float)` is unsafe for limit prices sent to broker APIs

IEEE-754 round-trip through `str()` can produce `0.30000000000000004`-style artifacts at the boundary. schwab-py and similar SDKs accept string prices — constructing them with `f"{price:.2f}"` (explicit precision) or `str(Decimal(str(price)).quantize(Decimal("0.01")))` (Decimal round-trip) is the safe path. Bare `str(float_price)` can reject at the exchange or fill at an unintended price.

## Cross-Refs

- `~/.claude/learnings/resilience-patterns.md` — dedup-before-process, domain-typed exceptions, stale-cache correctness patterns in financial/transactional systems (complements the calculation-level error handling here)

---

### NaN/Inf guard at financial calculation boundary

Broker-supplied prices can be non-finite from network errors, halted markets, or synthetic mid-quotes. Helpers that propagate NaN/Inf downstream produce silent incorrectness — `tick_size > 0` guards reject malformed config but pass NaN through `round()` and `*` unchanged. Add `if not math.isfinite(price): raise ValueError(...)` at the boundary of any price helper before downstream math. Same applies to size/quantity helpers fed from broker fills.

### Dry-run / sim binary safety flags need bidirectional tests

Any flag distinguishing "real money" from "simulated" behavior needs both a positive test (`flag=False → execute=True`) and a negative test (`flag=True → execute=False`). Positive-only gives false confidence the gate works bidirectionally — a typo inverting the `if` block still passes the positive test. Apply the same rule to `is_dry_run_enabled`, `simulate=True`, `paper_trading=True`, and any `live_orders` toggle.

### Required field beats `0.0` default on load-bearing money fields

A dataclass `equity: float = 0.0` lets a missed construction site silently produce wrong-but-plausible numbers — `equity=0.0` plus `invested=18000` makes P/L log as `-$18,000`, a total-loss signal that looks legitimate enough to delay investigation. For any field that drives money-affecting computation (balance, equity, principal, notional), prefer required (no default). Loud `TypeError` on missed init beats silent corruption.

Defaults remain appropriate for accumulators (`fees_paid: float = 0.0` accumulating from zero) and metadata (`label: str = ""`). For *inputs* to derived monetary calculations, treat the missing default as a feature — it forces every construction site to be explicit about the value.
