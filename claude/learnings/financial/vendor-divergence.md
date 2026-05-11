Vendor data quality patterns: sentinel values, cross-vendor failure mode divergence, and probe-based validation bypass for ground-truth discovery.
- **Keywords:** vendor, sentinel, TradeStation, Schwab, UVXY, VX, data quality, magnitude ceiling, probe, validator bypass, numeric range
- **Related:** ~/.claude/learnings/financial/tradestation-api.md, ~/.claude/learnings/financial/futures-etf-translation.md

---

## Vendor APIs use sentinel values for "no data" in numeric fields

Some vendor APIs return numeric sentinels (e.g., `-2**31 / 100 = -21_474_836.48`, `-999`, `9999.99`) for "no data" instead of null. They pass `isfinite()` and aren't negative-volume — they slip through standard validators and persist as if they were real values.

Defensive validation at the vendor seam: gate on **domain-realistic ranges**, not just type/finite checks. For prices specifically, `val <= 0` is always wrong. Raise loud (don't silently filter) so corrupt rows never persist as "reproducible truth" — the operator can re-fetch with a later start date past the corruption.

Audit any `or 0`, `get(field, 0)`, finite-checks-without-range-check on numeric fields from external sources.

## Vendor-divergent failure modes on shared upstream data

Multiple vendors that wrap the same upstream (corporate-actions, pricing, reference data) each apply their own cleanup pass — **failure modes diverge even when the underlying garbage is shared**. A `val > 0` guard catches one vendor's signed-cents underflow but waves through another vendor's positive-but-absurd magnitude. Concrete: TS returns `-21_474_836.48` sentinels for missing UVXY days; Schwab returns positive bars in the hundreds of billions of dollars (`Close=$514,500,000,000`) over the same window because of bad split-adjustment math. Both are unusable; only one trips a sign check.

Defense: pair the sign/finite check with a **magnitude ceiling** — per-symbol upper bound, per-asset-class cap, or a percent-change-since-listing sanity check. Keep both: positive-but-billions and negative-cents are both "no data," but only different validators catch each.

## Probe vendors below your validator

To verify what a vendor actually serves, write a probe that calls the underlying client/API directly and **skips the production converter/validator path** — otherwise the validator short-circuits on the first bad bar and you see the post-rejection view, not ground truth. Pattern: same window + same signature checks across vendors, raw response saved to a gitignored scratch path for replay, the probe script committed alongside a findings doc so spot-checks stay reproducible.

## Cross-Refs

- `~/.claude/learnings/financial/tradestation-api.md` — TS-specific API mechanics (account gating, orderconfirm, symbol formats)
- `~/.claude/learnings/code-quality-instincts.md` — general validation patterns (sentinel guards, sibling-field scans)
