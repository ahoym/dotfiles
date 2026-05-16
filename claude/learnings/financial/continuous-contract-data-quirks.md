Continuous-contract futures data: vendor-side construction artifacts that show up in committed bar caches — back-adjustment offsets, sentinel values, vendor-specific edge cases.

- **Keywords:** continuous contract, back-adjustment, Panama Canal, futures rally, perpetual cache, negative prices, vendor sentinel, validator rejection, single-regime data
- **Related:** futures-etf-translation.md, ../code-quality-instincts.md, ../testing/testing-patterns.md

---

## Recent rallies can poison older bars via back-adjustment

Panama Canal back-adjustment (the standard continuous-contract construction) carries cumulative roll offsets forward from each contract roll. When the most-recent contract has rallied 2-5× over its historical range, the accumulated offset becomes large enough to push older bars into non-positive territory. A strict input validator (one that rejects `Open <= 0` etc.) refuses these — correctly, a negative price is unreal.

Concrete: a 2024 cocoa rally ($2.5k → $11k) made the vendor's `@CC` continuous series return negative bars for everything before ~mid-2024. Identical shape for `@OJ` (Florida citrus greening rally). Only ~500 bars (the rally itself) pass validation — single-regime data, useless for robustness testing.

**Detection recipe:** probe with a small recent window (`--barsback 500` or equivalent). If the only clean bars are inside the rally, the symbol isn't ready for the perpetual cache. Three options:
1. Omit the symbol entirely (best when the clean window is < 2 years and IS the rally).
2. Anchor at the post-rejection inception date (works when the boundary is older than the rally — e.g., `@CT` cotton needed `firstdate >= 2010` because pre-2010 hit Low=-0.1 but recent decades were clean).
3. Wait. The offset stabilizes naturally as more post-rally contracts accumulate — the rally bar becomes one of many, not the anchor.

**Pattern smell:** "this vendor has bad data for old bars" is often back-adjustment recalculation, not vendor incompetence. Validator-rejection at bar N is the diagnostic — find the boundary, then anchor or omit.

## Different rally history → different boundary per symbol

Same vendor, same continuous-contract algorithm, but the boundary varies by how dramatic the recent contract's rally was:

| Symbol | Boundary | Cause |
|---|---|---|
| No rally history | clean from inception | Adjustment offset is small relative to historical prices |
| Modest 2-5× rally | clean from a recent decade | Offset survives lower-price bars from the modest range; only deep-history goes negative |
| Extreme rally with no precedent | only the rally itself is clean | Adjustment offset > all historical prices |

Treat the boundary as a per-symbol parameter to discover empirically, not a vendor-wide constant. Two adjacent contracts on the same exchange can land in different rows of this table.

## Why this isn't a vendor bug to file

Back-adjustment is the price you pay for a continuous time series — the alternative (raw dated contracts) requires roll-stitching logic in every consumer. The math is correct; the artifact comes from the mathematical operation interacting with an unusually high anchor price. The vendor isn't going to "fix" this without changing the back-adjustment algorithm, which would invalidate every other backtest in their ecosystem.

The right response is operator-side discipline: validate at ingestion, document affected symbols, choose between omit/anchor/wait.

## Cross-Refs

- `futures-etf-translation.md` — wrapper-counting and contract specs
- `../code-quality-instincts.md` — "Respect input validators" pattern (the operator-side discipline)
