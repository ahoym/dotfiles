# Financial Application Patterns

### Never silently default monetary calculations to zero on error

When fee calculations or amount transformations throw exceptions, failing silently with a zero or pass-through value can cause transactions to process incorrectly (e.g., zero fees). Always fail loudly — throw, log, or block the transaction.

### Stubbed financial logic should throw, not return defaults

If a fee mode or calculation path isn't implemented yet, throw `NotImplementedException` rather than returning the original amount. Returning incorrect values from stubbed financial logic can silently propagate through the system.

### FeeMode semantics: INCLUDED vs EXCLUDED

`INCLUDED` = seller pays fees (fee deducted from gross), `EXCLUDED` = buyer pays fees (fee added on top). Core invariant: `Gross = Net + Fee`. Both modes must be tested explicitly.

- **Takeaway**: Always maintain the `Gross = Net + Fee` invariant across all fee calculation paths.

### Proportional fee calculation requires zero-amount guards

When distributing fees across multiple transactions proportionally (`txFee = (txAmount / grossAmount) * totalFee`), always guard against division by zero on the gross amount. This is easy to miss when the formula looks simple.

- **Takeaway**: Any financial formula with division needs a zero-divisor guard, even when "it shouldn't happen."

### Side-effect-laden read operations are a design risk in financial systems

Query methods that compute derived state and mutate the entity as a side effect (e.g., auto-completing a transfer when `amountRemaining` reaches zero during a read) violate command-query separation. In financial systems this is especially dangerous — reads should never trigger state transitions.

- **Takeaway**: Separate state transition logic from query methods. Financial state changes should be explicit, auditable operations.

### Two-layer idempotency for payment systems

Caller provides a `clientReference` (business-level idempotency — "did I already submit this settlement?"). The payment service uses the same reference as the vendor's `Idempotency-Key` header (infrastructure-level — "don't duplicate the bank payment"). This makes retries safe at both levels: caller can safely re-POST, and the service can safely retry vendor calls.

- **Takeaway**: Align business and infrastructure idempotency keys. The caller's reference should flow through to the vendor's idempotency mechanism.

### Domain vs vendor enum separation in payment integrations

Maintain a domain `Currency` enum that's vendor-agnostic. Map to vendor-specific enums (`AcmeCurrency`, future vendor codes) only at the provider boundary. Same applies to payment types, statuses, and account identifiers. Prevents vendor coupling from leaking into domain models and makes adding new vendors a provider-layer change only.

- **Takeaway**: Domain speaks domain language. Vendor translation happens in the provider implementation, not in the service layer.

### Off-by-one in date/time cutoff calculations

Settlement cutoff used `.minusDays(1).withHour(6)` instead of `.withHour(6)`, shifting the window by 24 hours. Date arithmetic off-by-ones are a recurring pattern in financial systems -- always trace through concrete examples with real dates to verify the window boundaries.

- **Takeaway**: Date/time cutoff logic needs concrete example walk-throughs. Off-by-one in time windows can silently include/exclude a full day of transactions.

### DECIMAL precision for financial schemas: use (38, 18)

`DECIMAL(38, 18)` is the standard for financial systems handling crypto assets:
- **38 total digits** — max portable precision across SQL Server, Oracle, and PostgreSQL
- **18 decimal places** — covers the most demanding case (ERC-20 tokens), with 20 integer digits (quadrillions)
- **Java BigDecimal** — JDBC/Hibernate map `DECIMAL(38, x)` cleanly; larger precisions work but are non-standard ORM territory
- **Storage** — PostgreSQL uses ~2 bytes per 4 decimal digits; `(80, 30)` roughly doubles per-row cost with no practical benefit

No currency standard requires >18 decimals (XRP=6, fiat=2-4, Ethereum=18). For intermediate FX rate calculations, compute in BigDecimal and persist only the final amount.

### Null Safety in BigDecimal Stream Reductions and Arithmetic

Nullable fields throw NPE in `reduce(BigDecimal.ZERO, BigDecimal::add)`. Add `.filter(Objects::nonNull)` or use `Optional.ofNullable().orElse(BigDecimal.ZERO)` before reducing. Extends to individual operations: guard with `BigDecimal.ZERO` before subtraction when methods like `getFeeAmount()` can return null.

## See also

- `.claude/learnings/bignumber-financial-arithmetic.md` — JavaScript BigNumber.js patterns for frontend financial calculations (complements the Java BigDecimal patterns here)
- `.claude/learnings/resilience-patterns.md` — dedup-before-process, domain-typed exceptions, stale-cache correctness patterns in financial/transactional systems (complements the calculation-level error handling here)
