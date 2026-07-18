Vendor data quality patterns: sentinel values, cross-vendor failure mode divergence, and probe-based validation bypass for ground-truth discovery.
- **Keywords:** vendor, sentinel, TradeStation, Schwab, UVXY, VX, data quality, magnitude ceiling, probe, validator bypass, numeric range
- **Related:** ~/.claude/learnings/financial/tradestation-api.md, ~/.claude/learnings/financial/futures-etf-translation.md

---

## Vendor APIs use sentinel values for "no data" in numeric fields

Some vendor APIs return numeric sentinels (e.g., `-2**31 / 100 = -21_474_836.48`, `-999`, `9999.99`) for "no data" instead of null. They pass `isfinite()` and aren't negative-volume — they slip through standard validators and persist as if they were real values.

Defensive validation at the vendor seam: gate on **domain-realistic ranges**, not just type/finite checks. For prices specifically, `val <= 0` is always wrong. Raise loud (don't silently filter) so corrupt rows never persist as "reproducible truth" — the operator can re-fetch with a later start date past the corruption.

Audit any `or 0`, `get(field, 0)`, finite-checks-without-range-check on numeric fields from external sources.

## Vendor-divergent failure modes on shared upstream data

Multiple vendors that wrap the same upstream (corporate-actions, pricing, reference data) each apply their own cleanup pass — **failure modes diverge even when the underlying garbage is shared**. A `val > 0` guard catches one vendor's signed-cents underflow but waves through another vendor's positive-but-absurd magnitude. Concrete: TS returns `-21_474_836.48` sentinels for missing UVXY days; Schwab returns positive bars in the hundreds of billions of dollars (`Close=$514,500,000,000`) over the same window. Both trip a naive eyeball, but only the sentinel trips a sign check — and the billions are *not* corruption (see caveat below).

**Caveat — "absurd magnitude" can be legitimate back-adjustment.** Schwab's $514B UVXY is *correct*: 13 reverse splits (~1.5e9× cumulative) carried into early bars of a continuous adjusted series. Verify before calling it corrupt: count *all* splits, check returns for split-cliffs (none → adjusted), compare against split-*adjusted* history (never unadjusted spot). See `continuous-contract-data-quirks.md` → "Huge early prices: corrupt or legit back-adjustment?".

Defense: pair the sign/finite check with a **percent-change-since-prior-bar** sanity check, not an absolute magnitude ceiling. A flat "reject Close > $1M for an ETF" wrongly rejects legitimate reverse-split back-adjusted history (see caveat above) — gate on *jumps*, which catch corruption while passing smooth back-adjustment.

## Recover a sentinel-poisoned window by backfilling from the sibling vendor

When vendor A serves sentinels for a deep-history window but vendor B serves the *same* back-adjusted series, backfill from B instead of trimming. Proof they're the same series: B's bar at the first clean date equals the cache **to the dollar** (UVXY: Schwab `2016-04-19` == cache == `$19,487,500`). Then:
- Pair B's OHLCV with A's own per-date timestamps (uniform time-of-day, dedup-safe seam).
- Validate every backfilled bar: OHLC finite & > 0 **and** OHLC-consistent (`low ≤ min(O,C)`, `high ≥ max(O,C)`); skip-and-report any failure, never fabricate.
- Confirm the merge: zero split-cliffs across the full series (UVXY's only >60% day post-backfill is Volmageddon 2018-02-05). A clean join = same continuous series.

The "missing" window was feed-specific, not absent — distrust "this vendor has no pre-YYYY data" until you've checked a second vendor.

## Probe vendors below your validator

To verify what a vendor actually serves, write a probe that calls the underlying client/API directly and **skips the production converter/validator path** — otherwise the validator short-circuits on the first bad bar and you see the post-rejection view, not ground truth. Pattern: same window + same signature checks across vendors, raw response saved to a gitignored scratch path for replay, the probe script committed alongside a findings doc so spot-checks stay reproducible.

## Cross-Refs

- `~/.claude/learnings/financial/tradestation-api.md` — TS-specific API mechanics (account gating, orderconfirm, symbol formats)
- `~/.claude/learnings/code-quality-instincts.md` — general validation patterns (sentinel guards, sibling-field scans)
