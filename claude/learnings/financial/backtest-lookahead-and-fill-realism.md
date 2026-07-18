Backtest validity for fill-sensitive strategies: the intrabar (execution) look-ahead that walk-forward cannot catch, plus fill-realism gates for limit/fade strategies.
- **Keywords:** look-ahead bias, intrabar look-ahead, execution look-ahead, fill realism, resting limit, limit fill, penetration, fade, mean-reversion, break-before-enter, held-vs-blew, blow-through, walk-forward, WFE, OOS, order-of-operations, causal backtest, tick simulation, profit factor, R-multiple, realized-at-exit Sharpe, sub-bar resolution, fast-TF entry, resolution-invariant fill set, confirmation entry, fast-confirm, same-bar exit, asymmetric exit, book-stop-defer-TP, worst-path, re-prove drift, generated-table prose drift, rank-IC reproducibility, ordinal vs average ranks, Spearman ties, tie fraction, IS/OOS embargo, per-window de-trend, forward-return seam leak, non-reproducible committed table
- **Related:** ~/.claude/learnings/financial/risk-overlays-and-stops.md, ~/.claude/learnings/financial/order-book-pricing.md

---

## Two unrelated look-aheads — passing one validation says nothing about the other

- **Selection / overfitting look-ahead** — "did I tune parameters on the test period?" Walk-forward / WFE / holdout **catch this** (train past, test future).
- **Intrabar / execution look-ahead** — "at the instant my order executes, did the sim use information that didn't exist yet?" Walk-forward **CANNOT catch this**: it splits by *time*, but the bias lives in the engine's *within-bar* order-of-operations and is identical in every window, so OOS ≥ IS looks reassuring while both halves are inflated by the same bias.

## The canonical trap: a close-based gate on an order that fills intrabar

A per-bar loop that decides lifecycle on **this bar's close** (break/flip/re-arm) and *then* fills **intrabar** orders (resting limit on `bar_low ≤ level`, stop on `bar_high ≥ stop`) in the same iteration lets the close-based step **veto a fill that already happened mid-bar**. Worked case: an engine broke a level on `close[i]` *before* entering a limit fade, so it never booked the ~half of touches that closed *through* the level (the −1R "blow-throughs") — but a real resting limit fills on the touch, before the close exists. Removing the look-ahead collapsed PF ~1.6 → ~0.8 (net-negative) across MES/ES/NQ.

## Rule + test

- **Rule:** a fill may use only information available at the fill instant (intrabar price reaching the level) — never the bar's close or any same-bar lifecycle event. A close-driven *signal/lifecycle* is fine; a close-driven *fill gate* on an order that executes intrabar is look-ahead.
- **Test (cheap, decisive):** re-run with a strict causal gate (every per-bar decision uses only bars strictly *before* the current one); diff vs the engine — the gap is the look-ahead. Then decompose entries **held-vs-blew** (did the bar close back through the level, or beyond it?); a resting limit must include the blew-through bucket — if the engine's population excludes it, it's peeking.
- **Tells:** OOS passes *and* the edge concentrates in trades that resolve favorably "by the close" (high win rate on a fade); the result depends on the *order* of break/exit/entry steps within a bar; a "resting limit" backtest never books fills where price traded through the level and kept going.
- Ultimately only **event/tick-level fill simulation** settles a fill-sensitive strategy; bar OHLC cannot, no matter how the windows are sliced.

## Fill realism for limit/fade strategies — price vs probability

- A penetration sweep (require price to move `k·ATR` past the level before the limit fills) tests fill **price**, not fill **probability** on a touch. A "wider stop fixed the fill-fragility" headline can conflate the two: the winners are often the shallow touch-and-reverse fills least attainable live, so the gate moved off the price axis, not away.
- "Based on bar closes" is not automatically causal, and "walk-forward passes / no *selection* look-ahead" is not "no look-ahead." Quote per-trade **profit factor / R-multiple**; lead $-and-drawdown over a realized-at-exit Sharpe (flat no-exit bars deflate the std → a √N-inflated Sharpe).

## Finer bar resolution does NOT rescue a passive-limit fade — it confirms it

For a **passive resting limit** the fill set is **resolution-invariant**: a slow bar's low equals the min of its constituent fast-bar lows, so "price touched the level" is the same event at 4h, 5min, or tick. Stepping a slow-TF signal with fast-TF execution (e.g. 5min fills under a 4h signal) therefore adds **no new fills** — it only surfaces *more* of the marginal touch-and-reverse fills the bar engine's look-ahead was hiding (the −1R blow-throughs), so a blind-limit fade gets **monotonically worse** as the trigger speeds up (netR ~−0.03 at 4h → ~−0.6 at 5min). Tick simulation would confirm net-negative, not rescue it — so "you need tick data to settle it" is only half-true for a passive limit; sub-bar already settles it. The **one** thing finer resolution helps is a **confirmation entry** (wait for a fast bar to *tag the level AND close back through it*): that changes the fill set (skips blow-throughs honestly) and genuinely needs intrabar price — the one variant worth tick/paper-testing.

## Same-bar exit on an OHLC fill bar — asymmetric is the only correct model

An OHLC bar can't order its own high vs low, so on the bar a limit fills you can't know whether the favourable extreme (TP) printed before or after the fill. The correct **worst-path** model is **asymmetric**: book a same-bar **stop** (a bar that fills you then runs to your stop *did* stop you) but **defer** a same-bar **take-profit** to a later bar (don't assume the favourable path). Symmetric handling is wrong either way — *book-both* over-credits same-bar TPs (a fade's TP-high usually printed before the fill-low), *defer-both* throws away the legitimate same-bar stop. Implement as: evaluate stop-before-TP so a span-both bar books the stop, then null a *returned* same-bar TP (`if reason == TAKE_PROFIT: exit_price = None`). Stop-before-TP alone is **necessary but not sufficient** — it only fixes the *span-both* bar; a bar that fills a fresh limit and reaches the TP **without** touching the stop still books a favourable same-bar TP unless you defer it (the null-returned-TP step above handles exactly this — safe because a returned TP implies the stop didn't hit). Empirically these favourable same-bar TPs ran ~47–70% of net R on a 1%-TP / 1.5-ATR fade at slow TFs; removing them cut headline PF_R / net-$ ~25–50% (the edge survived, the *level* was overstated).

## Re-prove drift — a regenerated table can contradict its own prose

When a result file's data rows are regenerated (re-proven against new data/engine) but its **hardcoded prose summary** isn't, the summary silently contradicts its own rows (e.g. "netR holds under deferral" printed above rows where netR *falls*). Cross-check a table's stated conclusion against its rows before quoting it; fix the summary in the **script** that prints it and regenerate — never hand-edit the generated file (the next regen overwrites it).

## A rank-IC over heavily-tied data is non-reproducible under ordinal tie-breaking — use average ranks

A Spearman rank-IC built with *ordinal* ranks (ties broken by `argsort` position) over a heavily-tied feature makes the correlation depend on the sort's arbitrary tie-order, so a **committed result table fails to reproduce across environments/numpy builds on identical code + data** (e.g. mean|IC| 0.010→0.009, sign-consistency 7/9→8/9). Fix: **average-tie ranks** (collapse each tie run to its mean rank — the textbook Spearman tie rule) → deterministic.

- **Tell:** a script deterministic *within* one environment whose *committed* output still won't reproduce, while sibling `.mean()`/`.sum()` tables (no ranking) reproduce byte-for-byte. An IC swing of ~0.008 absolute is far larger than BLAS summation-order noise (~1e-10 relative) yet sits within a documented noise floor — that combination points at tie-order, not the data or environment.
- **Diagnose before blaming the environment:** probe the tie fraction `1 - len(unique(x))/len(x)`. 90%+ ties (e.g. 3.4k unique in 35k points) means the ordinal rank is mostly tie-order noise.
- A review verdict of "below the noise floor / no-action" on a non-determinism source is **falsified** once it actually breaks reproducibility of a committed artifact — new evidence that re-opens the finding, even when the scientific conclusion (the null) is unchanged.

## IS/OOS split cleanliness: embargo the forward-return seam, de-trend per window

When the target is a forward return `fwd[i] = (close[i+h]-close[i])/ATR[i]`, an IS/OOS split by index or calendar leaks: IS bars within `h` of the seam read `close[i+h]` from the OOS half. Purge them — end IS at `mid-h` (drop `[mid-h, mid)` from **both** halves); OOS needs no purge if its tail is already NaN-padded. Walk-forward/holdout *selection* validity does not catch this — it's a per-window target-bleed, not parameter peeking. Sibling to the intrabar look-ahead at the top of this file: same "the validation you ran is silent on this" trap, different mechanism.

- **De-trend each IS/OOS column against its OWN window's drift**, never one full-sample (future-aware) constant subtracted from every event. The full-window headline may keep the full-sample drift; the IS/OOS columns are the robustness gate, so their split must be self-contained — one shared mean across both halves contaminates the IS→OOS sign-consistency read.
- A constant level-shift can't manufacture or destroy a cross-event edge (ranking/variance untouched), so the **headline** stays honest; the per-window de-trend + embargo protect the **split-cleanliness** gate, not the headline.
