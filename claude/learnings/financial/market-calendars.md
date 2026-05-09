Market-calendar library selection — disentangle from DataFrame library choice.
- **Keywords:** market calendar, NYSE, CME, holidays, trading day, business day, polars, pandas, futures roll, expiry
- **Related:** ~/.claude/learnings/financial/futures-etf-translation.md

---

## DataFrame libraries are not market-calendar sources

`pandas_market_calendars` happens to depend on pandas. That's an implementation artifact, not a justification to introduce pandas to get NYSE holidays. Same for polars — it has business-day arithmetic primitives (`add_business_days`) but ships zero calendar data.

When asked "polars or pandas?" for calendar work, reframe first: *what data are you manipulating?* If the answer is "trading-day arithmetic" or "next contract expiry", neither DataFrame library solves it alone — both need a calendar source.

## Library matrix

| Need | Library | Notes |
|------|---------|-------|
| NYSE holidays, no DataFrame dep | `holidays.financial.NYSE` | Pure Python, ~100KB, NYSE-specific (Good Friday, day-after-Thanksgiving, Juneteenth) |
| NYSE + CME + per-exchange schedules | `pandas_market_calendars`, `exchange_calendars` | Both pull pandas (~50MB) |
| Caller-supplied holidays + business-day math | `polars` native, or stdlib `datetime` + a set | Polars only earns its weight when DataFrame ops are also in play |
| Country holidays (federal/observed) | `holidays` (no `.financial`) | Misses NYSE-specific quirks |

## Use case sizing

For small date arithmetic — `next_active_contract(today)`, `is_roll_due(held, today)`, "what's 5 trading days before this date" — stdlib `datetime` + `holidays.financial.NYSE` is sufficient. ~20 lines. No DataFrame library needed.

Introduce a DataFrame library only when DataFrame ops (filtering price series, group-by, joins) are independently motivated. Don't justify the dependency through the calendar question alone.

## Cross-Refs

- `futures-etf-translation.md` — futures rolls are the typical trading-day-arithmetic use case
