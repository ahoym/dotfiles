Patterns for real-time data updates, background refreshes, and resource validation in data-driven UIs.
- **Keywords:** reactive refresh, polling, silent fetch, expiration tracking, setTimeout, setInterval, useRef, balance validation, exchange orders, loading skeleton
- **Related:** react-patterns.md, order-book-pricing.md

---

## Reactive Refresh Over Polling

Instead of polling a secondary dataset on a timer alongside a primary data feed, watch the primary feed for events matching the current user. Track seen event IDs in a `useRef(new Set())`. On first load, seed the set without triggering a refresh. On subsequent updates, diff against the set — if any new event involves the user, silently refetch the secondary dataset.

## Client-Side Expiration Tracking

For items with an expiration timestamp, compute the delay until expiry (converting platform-specific epochs to JS timestamps if needed) and `setTimeout` to trigger a silent refetch 1 second after expiration. Only schedule timers for items expiring within 5 minutes. Clean up timers on unmount or when the list changes. This avoids continuous polling while ensuring expired items don't linger in the UI.

## Silent Fetch Pattern

Add a `silent = false` parameter to data-fetching callbacks (default `false` for backward compatibility). When `silent` is true, skip `setLoading(true)` and don't clear data on error — only update state on success. This prevents loading skeleton flashes during background refreshes. Use `silent: true` for background/automated refreshes (event-driven, expiration timers); `silent: false` for initial loads and user-triggered refreshes.

## Balance Validation for Exchange Orders

When submitting orders that spend a resource, validate the user's available balance for the currency being *spent* before allowing submission.

**Key detail:** Buy orders spend the **quote currency** (total = amount × price), sell orders spend the **base currency** (amount).

Show an inline error with specific amounts ("Insufficient X — you have Y but need Z") and disable submit when `spendAmount > availableBalance`.

## Cross-Refs

- `react-patterns.md` — React hooks, polling with visibility gating, localStorage migration
- `order-book-pricing.md` — pricing computation layer for exchange UIs (mid-price, slippage)
