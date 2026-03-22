# BigNumber.js for Financial Arithmetic

Financial calculations should use BigNumber.js instead of native JavaScript arithmetic to prevent floating-point precision errors in prices, totals, and basis-point calculations.
**Keywords:** BigNumber.js, bignumber.js, parseFloat, floating-point, precision, toFixed, reduce accumulation, financial arithmetic, order book, spread
**Related:** financial-applications.md, order-book-pricing.md

---

## Rules

1. **Never use `parseFloat()` or native operators (`+`, `-`, `*`, `/`)** on financial values (prices, amounts, totals, spread).
2. **Import BigNumber** (commonly available as a transitive dependency in financial libraries):
   ```ts
   import BigNumber from "bignumber.js";
   ```
3. **Construct from strings**, not numbers, to avoid losing precision:
   ```ts
   new BigNumber(item.price)  // good
   new BigNumber(0.1 + 0.2)        // bad — precision already lost
   ```

## Patterns

### Display formatting
```ts
new BigNumber(price).div(quantity).toFixed(6)
```

### Comparisons and guards
```ts
const total = new BigNumber(a).plus(b);
if (total.isGreaterThan(0)) { ... }
if (total.isZero()) { ... }
```

### CSS / numeric contexts
When a number (not a string) is required — e.g., for inline style widths or chart data — convert at the boundary:
```ts
amount.div(max).times(100).toNumber()  // percentage for width style
```

### Accumulation (reduce patterns)
```ts
items.reduce((sum, item) => sum.plus(item.amount), new BigNumber(0))
```

## Where this applies

- Order book price/size/total columns
- Spread and basis-point calculations
- Trade history aggregation
- Balance displays and payment amount inputs
- Any derived numeric value shown to the user

## Cross-Refs

- `financial-applications.md` — Java BigDecimal patterns, fee calculation invariants, DECIMAL(38,18) schema precision (complements the JavaScript BigNumber.js patterns here)
- `order-book-pricing.md` — mid-price computation, slippage estimation, and reduce accumulation using BigNumber.js in orderbook context
