Continuous-contract futures data: vendor-side construction artifacts that show up in committed bar caches — back-adjustment offsets, sentinel values, vendor-specific edge cases.

- **Keywords:** continuous contract, back-adjustment, Panama Canal, futures rally, perpetual cache, negative prices, vendor sentinel, validator rejection, single-regime data, barsback, firstdate, forming bar, in-formation bar, mid-formation, settled bar, partial trailing bar
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

## Incremental refresh sidesteps the boundary entirely

For an append-only bar cache, default the refresh to fetch from the newest cached bar minus a small overlap — not from inception. This structurally avoids ever re-requesting the poisoned deep-history window, so a back-adjustment-corrupted old range can't crash the run or force per-symbol boundary discovery. Reserve full-history fetch behind an explicit `--full` flag for gap-backfill / rebuild; an empty cache still does a full pull.

Bonus: re-fetching full history every sync is wasted payload + I/O. With a merge that prefers existing bars, re-fetched old bars are discarded anyway — and rewriting a parquet partition with identical logical content is byte-identical, so `git status` shows zero churn for unchanged years (only the current-period partition differs). General rule: make the default the cheap/safe operation; put the expensive, can-hit-bad-data path behind a flag.

## Huge early prices: corrupt or legit back-adjustment?

A committed series whose early bars are enormous (UVXY: $514B in 2011, decaying to ~$28 today) is usually *legitimate reverse-split back-adjustment*, not corruption. Decide empirically before trimming — the cost of guessing wrong is discarding real history:

1. **Count *all* splits → cumulative factor.** UVXY had 13 reverse splits since 2012 (~1.5e9× cumulative); an adjusted series *must* carry that into early bars. Undercounting splits (4 vs 13) is what makes legit prices look "10,000,000× too high."
2. **Check returns for split-cliffs.** Day-over-day on the full series: a back-adjusted series has *zero* ~−80%/−75% single-day cliffs (adjustment removes them); an unadjusted one spikes on every split. UVXY's only >60% day is Volmageddon (2018-02-05) — real, not artifact.
3. **Compare against split-*adjusted* history, never unadjusted spot.** Adjusted-vs-spot always shows a spurious "overshoot" by construction — that comparison proves nothing.
4. **Cross-vendor seam continuity.** If a second vendor's bar at the boundary matches to the dollar, it's the same series → the early window is recoverable, not corrupt (see `vendor-divergence.md` → backfill from sibling vendor).

Only genuinely non-positive sentinel rows are corrupt; the large positive tail is signal. Returns are scale-invariant under smooth multiplicative back-adjustment, so inflated absolute levels don't distort backtest math.

## `barsback` returns the forming bar; `firstdate` returns only settled bars

A vendor's two fetch windows can disagree on the trailing edge. TS's date-bounded `firstdate` daily query returns only *settled* sessions (last bar = last completed day), but `barsback` (the sidestep for CBOT continuous bonds where `firstdate` silently no-ops — `@US`/`@TY`/`@FV`/`@TU`) returns the *current forming* session bar, stamped at the nominal settlement time. A mid-session refresh writes a partial trailing daily bar (a few % of normal volume, compressed range) for `barsback`-routed tickers only.

The unfinished session is the universal *trigger*; the *bug* was applying the mid-formation cutoff to the existing cache but not the fetched set, so the forming bar slips through only on the path that returns it. **Detection:** every other ticker's last daily bar lands on the prior session while the barsback group is one session ahead. Fix: drop fetched bars at the same cutoff (`../code-quality-instincts.md` → Trailing-edge mid-formation bars).

## A "conservative" retention floor is directional — safe only coarser than its probed baseline

TS Minute retention is calendar-tiered (5min ~200d, 15min ~600d, 30/60/240min
~3yr), so a fallback floor probed at one interval is conservative only for
*coarser* intervals — longer retention means it merely under-fetches. For a
*finer* interval the same floor over-reaches the (shorter) retention and
`firstdate` returns HTTP 400, aborting the sweep. Don't let an unlisted interval
silently inherit a baseline floor in the wrong direction: fall back only on the
coarser side, and `raise` for finer-than-baseline intervals until their own
cliff is probed and added to the tier map. (Sibling to `../code-quality-instincts.md`
→ "A magic constant can encode a hidden assumption about a sibling parameter".)

## Multi-interval continuous series drift onto separate Panama baselines

A forward-fetched intraday store keeps a **separate back-adjustment baseline per
interval** (5min vs 30min vs daily). The vendor re-levels its whole continuous at each
roll, so two intervals last refreshed at different times sit a **constant apart** —
detect via the close difference at coincident `:00/:30` instants: a razor-constant `−C`
(one root's accumulated roll gap), bimodal against `0`, not noise. Large only for
big-roll-gap roots (index futures); negligible for VX/DX/ETF.

- `prefer="existing"` **freezes bars at their fetch-time baseline** while newer bars
  carry the re-leveled one → a **fake ~1% jump on a non-roll date** where a stale
  segment meets a fresh one. The coarsest interval (longest retention, refreshed most
  completely) is the internally-current reference.
- **Repair** by adding the per-root constant to OHLC (volume untouched) across the stale
  `[start, boundary)` segment — an additive shift preserves every within-segment
  point-change and heals the seam. The deepest stale bars are past retention (fetcher
  can't refresh them → hand-repair only), and the artifact **recurs each roll** until the
  fetcher stops freezing stale baselines.

## Cross-Refs

- `futures-etf-translation.md` — wrapper-counting and contract specs
- `vendor-divergence.md` — sentinel vs magnitude divergence; backfill from sibling vendor
- `../code-quality-instincts.md` — "Respect input validators" pattern (the operator-side discipline)
- `../resilience-patterns.md` — per-item batch-loop abort (one poisoned symbol skips the rest)
