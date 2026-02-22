# BigNumber.js for Financial Arithmetic

All financial calculations in this project must use **BigNumber.js** (`bignumber.js`) instead of native JavaScript arithmetic. This prevents floating-point precision errors in prices, totals, cumulative sums, spread, and basis-point calculations.

## Rules

1. **Never use `parseFloat()` or native operators (`+`, `-`, `*`, `/`)** on financial values (prices, amounts, totals, spread).
2. **BigNumber is already available** — it ships as a dependency of the `xrpl` package and is also a direct project dependency. Import as:
   ```ts
   import BigNumber from "bignumber.js";
   ```
3. **Construct from strings**, not numbers, to avoid losing precision:
   ```ts
   new BigNumber(offer.TakerPays)  // good
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
