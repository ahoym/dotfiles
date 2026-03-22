Cross-layer numeric precision strategy — DB types, wire format, application types, crypto precision landscape, and NUMERIC sizing rationale.
- **Keywords:** NUMERIC, DECIMAL, BigDecimal, BigNumber, BigNumber.js, bignumber.js, parseFloat, floating-point, precision, scale, toFixed, wire format, JSON, string serialization, crypto decimals, NEAR, Ethereum, ERC-20, SQL Server, PostgreSQL, MySQL, order book, spread, financial arithmetic
- **Related:** none

---

## Precision by Layer

| Layer | Type | Why |
|-------|------|-----|
| Database | `NUMERIC(p,s)` | Exact arbitrary-precision arithmetic, native comparison/sorting/aggregation |
| Wire (JSON API) | String `"1234.56"` | JSON `number` is IEEE 754 float — loses precision in transit |
| JS application | `BigNumber("...")` | Construct from wire string, never from parsed float |
| JVM application | `BigDecimal` | JDBC maps `NUMERIC` → `BigDecimal` directly — lossless, no string intermediary |

**JVM path is clean end-to-end**: `NUMERIC` → `ResultSet.getBigDecimal()` → `BigDecimal` arithmetic → serialize to string at API boundary. The string concern only exists when crossing into IEEE 754 territory (JSON, JavaScript).

## Why NUMERIC(38,18)

**38 total digits** = SQL Server's max `DECIMAL` precision. Chosen as the lowest common denominator for cross-DB portability, not a Postgres limit.

**18 decimal places** = Ethereum convention (1 ETH = 10^18 wei). Became the de facto "safe max" for multi-asset systems.

## Crypto Precision Landscape

| Chain/Asset | Decimals | Notes |
|------------|----------|-------|
| NEAR | **24** | yoctoNEAR — exceeds 18 |
| Aave internals | 27 ("ray") | Accounting precision, not token decimals |
| Ethereum/ERC-20 | up to 18 | `decimals()` is `uint8` (max 255), but 18 is practical ceiling |
| Solana | 9 | lamports |
| Bitcoin | 8 | satoshi |
| XRP | 6 | drops |
| Cosmos/ATOM | 6 | uatom |

**18 is not a hard ceiling.** NEAR at 24 and DeFi internal math at 27 break the assumption. Size accordingly: `NUMERIC(38,24)` for NEAR support (14 integer digits — ~100 trillion).

## Database NUMERIC Limits

| | PostgreSQL | MySQL | SQL Server |
|--|-----------|-------|------------|
| Max declared precision | 1,000 | 65 | 38 |
| Max declared scale | 1,000 | 30 | 38 |
| Unbounded mode | Yes (bare `NUMERIC`) | No | No |
| Implementation max | 131,072 + 16,383 digits | 65 total | 38 total |

Postgres `NUMERIC` is variable-length (~8 bytes header + 2 bytes per 4 decimal digits). Wider precision costs marginally more storage but enables exact arithmetic without overflow.

## Sizing Guidance

- **Fiat-only** → `NUMERIC(19,4)` — trillions with 4 decimals, 8 bytes, what most banks use
- **Multi-chain (no NEAR)** → `NUMERIC(38,18)` — covers Ethereum, portable to SQL Server
- **Multi-chain (with NEAR)** → `NUMERIC(38,24)` or `NUMERIC(48,24)` (Postgres-only for the latter)
- **Rate/price columns** → `NUMERIC(38,18)` minimum even in fiat systems — division produces more decimals than inputs

## BigNumber.js Quick Reference (JS)

Never use `parseFloat()` or native operators (`+`, `-`, `*`, `/`) on financial values.

```ts
import BigNumber from "bignumber.js";

// Construct from strings, not numbers
new BigNumber(item.price)        // good
new BigNumber(0.1 + 0.2)        // bad — precision already lost

// Display formatting
new BigNumber(price).div(quantity).toFixed(6)

// Comparisons
const total = new BigNumber(a).plus(b);
if (total.isGreaterThan(0)) { ... }
if (total.isZero()) { ... }

// Accumulation
items.reduce((sum, item) => sum.plus(item.amount), new BigNumber(0))

// Numeric contexts (CSS widths, chart data) — convert at boundary
amount.div(max).times(100).toNumber()
```

Applies to: order book price/size/total, spread/basis-point calculations, trade aggregation, balance displays, any derived numeric shown to user.

## Cross-Refs

No cross-cluster references.
