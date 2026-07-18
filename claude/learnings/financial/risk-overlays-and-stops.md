Risk management as a separate layer in systematic trading: stop-loss alpha-vs-risk, drawdown control under leverage, overlay attribution, and the sizing-vs-de-risk distinction.
- **Keywords:** stop-loss, trailing stop, ATR stop, risk overlay, drawdown guard, circuit breaker, stopping premium, Kaminski-Lo, volatility drag, geometric return, vol-targeting, position sizing, Kelly, alpha vs risk, RMS, portfolio construction, attribution, monotone de-risk, Grinold-Kahn, Carver
- **Related:** ~/.claude/learnings/financial/futures-etf-translation.md, ~/.claude/learnings/financial/numeric-precision-strategy.md

---

## Risk management is a layer on top of allocation, not baked into the signal

Institutional standard: **alpha model → portfolio construction (risk + cost models) → execution**, plus a real-time risk system that checks/rewrites orders *after* the signal, *before* execution. The separation keeps alpha and risk independently testable + attributable. Even the "integrated" school (Carver) bakes only *market-vol-derived* stops into the trading rule and still layers *account-level* risk (vol targeting) separately. The real question is never layer-vs-baked — layering wins — it's *which* risk lives where (portfolio-level risk → separate layer near-universally; position-level stops → contested seam, overlay is mainstream).

## A stop-loss is a hybrid: risk job, conditional alpha

A stop's *job* is risk — it reshapes the outcome distribution off **path state** and forecasts nothing directional. But it carries a conditional alpha component:
- **Kaminski & Lo, "When Do Stop-Loss Rules Stop Losses?":** a stop adds expected return (a "stopping premium" ∝ persistence) **iff the underlying has momentum** / positive serial correlation. On a random walk it strictly *reduces* return (forfeits the risk premium while stopped out). Mean-reversion → it hurts (misses the reversal).
- **Leverage channel:** on a levered, compounding book, cutting left-tail drawdown raises the *geometric* CAGR even at constant arithmetic return — negative geometric drag scales with **leverage²** (volatility drag).
- **Decisive test** for "is my stop alpha or risk?": did it raise **CAGR** (→ stopping premium / alpha) or only cut **maxDD** with CAGR flat/down (→ pure risk + vol-drag)? Decompose Calmar's numerator vs. denominator — don't settle it philosophically.

## Keep risk overlays isolated → attributable + pluggable

Because the alpha/risk label is genuinely ambiguous, draw the layer boundary by **information dependency + testability**, not philosophy. Keep each overlay a separate object (not merged into the algo) so its return contribution stays *attributable* — you cannot attribute a stopping premium you cannot isolate. Compose overlays as a **chain of single-purpose, monotone-toward-cash** de-riskers ("most conservative wins" → order-robust, composable); collapse two into one overlay only when they genuinely share state or precedence.

## Risk-sizing ≠ de-risk overlay ≠ affordability sizing

Three distinct concerns, routinely conflated:
- **Affordability sizing** — how many whole contracts/shares the equity supports (e.g. `floor(cash/notional)+1`). Execution-time; scales *with equity* (compounding).
- **Risk sizing / vol-target** — scale exposure ∝ 1/vol to hold risk constant. Strategy-time, broker-agnostic, **can scale up** → it cannot live in a monotone de-risk chain; it is its own layer *above* it.
- **De-risk overlays** — clamp toward cash on a tripped condition (stop, drawdown breaker). Monotone-down only.

They compose: vol-target sets the target → affordability sizing makes it placeable → de-risk overlays clamp on breach.

## Deploying a risk control: default-OFF structurally, then shadow → sim → live per control

Ship the structural code **default-OFF** — empty control set = byte-for-byte prior behavior, so the refactor merges with nothing live. Then enable each individual control through a **shadow soak** (compute + log + attribute its decision, but don't apply it) before it moves money. Two independent gating levels — structural (off until configured) + per-control (shadow → sim → live) — so the only irreversible step (a control acting) is always preceded by a shadow period. No big-bang switch.

## Stateful overlay mechanics for backtest ↔ live parity

A stateful control shared between backtest and live must:
- **Stamp persisted state with the decision-bar timestamp, never wall-clock.** Wall-clock breaks backtest determinism (the backtest has no clock — time *is* the bar date) and lets date-based reclaim replay exactly. Bump `updated_at` only on a *substantive* state change so a no-op-write skip survives.
- **Batch all controls' state into one read-modify-write per account per tick** — not one write per control (N× write amplification + N× crash windows).
- **Define an explicit re-entry/reclaim per control** — "a stop without a re-entry gate is a no-op." Once tripped it stays flat until *its own* re-arm fires (fresh signal episode / drawdown recovery / next session); a removed control's stale state should be pruned (its `updated_at` stops advancing) so it can't silently resurrect on re-add.

## A de-risk overlay must bias to the clamped/safe state under uncertainty — on restore and on a bad mark

Two failure-direction rules for a stateful breaker (drawdown guard, stop) that persists `{peak, tripped, ticks}` and runs live:

- **Restore (`load_state`) must fail loud or default-to-safe — never silently default to risk-on.** A tolerant restore that coerces a corrupt/partial blob to first-run defaults silently flips a *tripped* guard to un-tripped, re-risking the book in exactly the restart-mid-trip the persistence exists to cover (a truncated write during that restart is the likeliest corruption). Validate the whole blob, then either raise (match a fail-loud sibling) or default the protective bits to the **clamped** state; log every coercion so the disarm is auditable. `state.get("tripped") is True` defaulting a money-protecting flag to `False` is the wrong direction.
- **A non-finite/stale equity must not release de-risk.** While tripped, hold the clamp (re-apply it to the *current* target — don't pass the raw target through) and advance the reclaim clock, but **defer the reclaim *action* to a finite mark** (re-arming on an unknown mark is unsafe; a time-out re-baseline needs a real equity). Finite path unchanged ⇒ backtest numbers stay byte-identical (backtests never feed a non-finite mark).

Unifying principle: failing toward *clamped* costs opportunity, failing toward *risk-on* costs principal — pick the former under any uncertainty. Companion sibling overlays persisting state the same way should share this restore contract; an asymmetry (one raises, one silently coerces) is a review smell (`~/.claude/learnings/resilience-patterns.md` → symmetric failure handling). A type-only deserialization gate also passes a non-finite `peak` — see `~/.claude/learnings/python-specific.md` (`json` round-trips NaN; `x > nan` is always False, so a NaN high-water mark is permanently sticky).

## A composable sizing layer must clip the CUMULATIVE exposure, not its own factor

A multiplicative sizing layer that threads a scalar (`apply(...) -> (alloc, incoming × factor)`) must clip the **cumulative product**, not just its own factor: `clip(incoming × factor)`, not `incoming × clip(factor)`. Clipping only the per-layer factor lets the book run past every layer's `[min,max]` once layers compose (two `[0.5,1.5]` layers reach 2.25×) or the incoming scalar is already off 1.0 — on a leveraged book that's an unbounded scale-up with no margin-survival guard. The cumulative form is byte-for-byte for a single layer at incoming 1.0, and is more correct for vol-targeting (turbulent vol floors the book at `min_exposure` regardless of the incoming scalar). Prefer it over "clip per-layer + rely on a book-level cap" unless that cap actually exists. Pairs with `futures-etf-translation.md` → margin-call survival.

Corollary for the value object that carries the scalar: validate it **permissively in the safe direction, bound the dangerous direction upstream**. `exposure == 0.0` ("flat the book") is the safe failure (missed opportunity), so permit it; reject only non-finite/negative; impose **no upper bound at the value level** — bounding is the producing layer's job (the cumulative clip above), not a value-object invariant. Same opportunity-vs-principal asymmetry as the de-risk restore contract above.

## Vol/indicator fail-safe: filter to the clean window BEFORE the sufficiency check

A measurement fail-safe ("missing/short/bad data → pass exposure through unchanged, alert loudly") must filter corrupt values (`isfinite and > 0`) **before** the length/sufficiency check, not after — checking the raw count first lets a window with several corrupt bars pass the guard, filter down to a degraded sub-sample, and size off it (the fail-safe is silently violated whenever ≥2 points survive). Filter the trailing `lookback+1` slice, then require the **full clean count**, else fail safe. Requiring a fully-clean window also kills a second bug for free: dropping an *interior* corrupt close makes its neighbours adjacent and fabricates a **bridged return across the gap** (a 2-day move read as 1-day), spuriously inflating realized vol. Fail-safe-on-any-corruption beats drop-and-continue for a control whose contract is "never silently scale on bad data."
