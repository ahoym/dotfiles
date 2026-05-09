Patterns for runtime gates and polling cadences driven by configurable time windows.
- **Keywords:** trading window, market hours, cross-midnight, wrap window, weekday gate, polling cadence, sleep cadence, derive-from-window, CME calendar, futures session, equities close, time gate, scheduling
- **Related:** ~/.claude/learnings/refactoring-patterns.md, ~/.claude/learnings/code-quality-instincts.md

---

## Cross-midnight time-window: anchor weekday to window-open day, not now

When a runtime gate uses a `HH:MM-HH:MM` window that can wrap midnight (e.g. `18:00-09:30`, futures ETH session), the day-of-week check must anchor on **the day the window opened**, not `now`. The pre-end portion (between midnight and end-time) belongs to the prior calendar day's session.

```python
def _in_window(now, start, end, wraps):
    t = now.time()
    if not wraps:
        return start <= t < end and _is_valid_open_day(now, wraps)
    if t >= start:
        return _is_valid_open_day(now, wraps)            # post-start: today opened it
    if t < end:
        return _is_valid_open_day(now - timedelta(1), wraps)  # pre-end: yesterday opened it
    return False
```

Without this, Tue 02:00 in a Mon-evening session falsely fails the weekday check (Tue is fine but the rule has to anchor on Mon-the-opener anyway, and the fix matters when Mon is replaced by Sat/Sun).

## Excluded-open-days varies by market

The naive "weekend = Sat+Sun" only fits equities. CME index futures open Sun 18:00 ET → Fri 17:00 ET, with a daily 17-18:00 maintenance break. Fri-evening does NOT re-open after Thu's session ends. Excluded session-open days:

| Window shape | Excluded opens | Markets |
|---|---|---|
| Non-wrap (`15:20-16:00`) | Sat, Sun | Equities cash session |
| Wrap (`18:00-17:00`) | Fri, Sat | CME E-mini futures (Sun-Thu admit) |

Encode the rule by wrap mode (or by an explicit `TRADING_DAYS` knob if a third market needs different days):

```python
def _excluded_open_days(wraps: bool) -> tuple[int, ...]:
    return (4, 5) if wraps else (5, 6)  # 4=Fri, 5=Sat, 6=Sun
```

Common bug: implementing wrap-windows as "wraps means Sun opens admitted" without thinking through Fri. A wrap window `18:00-17:00` with only Sat excluded would falsely admit a Fri-evening session that doesn't exist on CME.

## Sleep cadence derived from the window beats hand-tuned tier ladders

Replace heuristic sleep tiers (90s at 14:25, 30min at 13:20, 1h before 15:00, 6h before 9am, 60h Fri after market...) with three constants and a derive-from-window formula:

```python
SLEEP_INSIDE_WINDOW = 90              # poll fast inside window
SLEEP_FLOOR = 60                      # min sleep
SLEEP_CEIL = 12 * HOUR_IN_SECONDS     # cap so DST/config can't lock out >12h
WAKE_LEAD_SECONDS = 30 * 60           # wake this much before window opens

def compute_sleep_time():
    if _in_window(now, start, end, wraps):
        return SLEEP_INSIDE_WINDOW
    next_open = _next_window_open(now, start, wraps)
    seconds_until = (next_open - now).total_seconds() - WAKE_LEAD_SECONDS
    return max(SLEEP_FLOOR, min(SLEEP_CEIL, seconds_until))
```

`_next_window_open` skips excluded days. The ceiling matters: without it, a window-config bug or DST transition could silently sleep through an entire trading day. The floor matters: prevents busy-loop when `next_open - now < lead`.

Trade-off vs the tier ladder: weekend sleeps wake more often (≤12h cap fires 4-5 times across a 60h gap instead of one 60h sleep). Acceptable — each wake is a cheap re-check.

## Split the inside-window constant when modes diverge in default

Adding a continuous/repeated-execution mode to a once-per-session loop? Don't overload `SLEEP_INSIDE_WINDOW`. Once-per-session needs the tight 90s poll so window-open isn't missed; continuous mode wants quieter polling (5min) since the cap is lifted and re-firing every 90s is wasted log noise + broker calls.

```python
SLEEP_INSIDE_WINDOW = 90               # once-per-session — fire promptly at open
DEFAULT_CONTINUOUS_POLL_SECONDS = 300  # continuous mode — quieter, cap is lifted

if _in_window(...):
    if is_continuous_run_enabled():
        return override or DEFAULT_CONTINUOUS_POLL_SECONDS
    return SLEEP_INSIDE_WINDOW
```

User-facing banner imports the constant (`f"default {DEFAULT_CONTINUOUS_POLL_SECONDS}s"`) so the echoed cadence can't drift from the actual default after future tuning.

## pytz `replace(hour=H)` doesn't re-localize across DST

`now.replace(hour=H)` on a pytz-aware datetime preserves the original UTC offset — it does NOT re-localize to the offset valid for the target date. Across DST transitions the wall-clock time is wrong by 1h. Build naive, then localize:

```python
naive = datetime(now.year, now.month, now.day, H, M)
target = TZ.localize(naive)
```

The bug is silent when a sleep ceiling caps the off-by-1h delay — wakes happen at the wrong wall-clock moment, not as a crash.

## Cross-Refs

- `~/.claude/learnings/refactoring-patterns.md` — when to replace heuristic ladders with derive-from-X formulas
- `~/.claude/learnings/code-quality-instincts.md` — clamp-with-floor-and-ceil discipline
- `~/.claude/learnings/python-specific.md` — Python timezone gotchas
