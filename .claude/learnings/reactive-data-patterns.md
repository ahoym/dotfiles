# Reactive Data Patterns

Patterns for real-time data updates, background refreshes, and resource validation in data-driven UIs.

## Reactive Refresh Over Polling

Instead of polling a secondary dataset on a timer alongside a primary data feed, watch the primary feed for events matching the current user. Track seen event IDs in a `useRef(new Set())`. On first load, seed the set without triggering a refresh. On subsequent updates, if any new event involves the user, silently refetch the secondary dataset.

**Key points:**
- Use `useRef(new Set())` to track already-seen IDs
- On initial load, populate the set without triggering side effects
- On subsequent updates, diff against the set to detect new events
- Only refetch secondary data when a relevant event is detected

## Client-Side Expiration Tracking

For items with an expiration timestamp, compute the delay until expiry and `setTimeout` to trigger a silent refetch 1 second after expiration. Only schedule timers for items expiring within 5 minutes. Clean up timers on unmount or when the list changes. This avoids continuous polling while ensuring expired items don't linger in the UI.

**Key points:**
- Convert platform-specific epoch to JS timestamp if needed
- Schedule `setTimeout` for 1 second after computed expiry time
- Only schedule for items expiring within a 5-minute window
- Clean up all timers on unmount or when the list re-renders

## Silent Fetch Pattern

Add a `silent = false` parameter to data-fetching callbacks. When `silent` is true, skip `setLoading(true)` and don't clear data on error — only update state on success. This prevents loading skeleton flashes during background refreshes.

**Key points:**
- Default `silent` to `false` for backward compatibility
- When silent: skip loading state, don't clear data on error
- Use `silent: true` for background/automated refreshes (event-driven, expiration timers)
- Use `silent: false` for initial loads and user-triggered refreshes

## Balance Validation for Exchange Orders

When submitting orders that spend a resource, validate the user's available balance for the currency being *spent* before allowing submission.

**Key detail:** Buy orders spend the **quote currency** (total = amount × price), sell orders spend the **base currency** (amount).

Show an inline error with specific amounts ("Insufficient X — you have Y but need Z") and disable submit when `spendAmount > availableBalance`.
