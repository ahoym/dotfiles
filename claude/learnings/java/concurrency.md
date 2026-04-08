Java concurrency: per-entity sync intervals, thread-safety for shared collections.
- **Keywords:** ConcurrentMap, sync interval, polling, throttle, per-entity, Instant, thread safety, HashSet, race condition, TOCTOU, ConcurrentHashMap, check-and-add
- **Related:** none

---

### Per-entity sync interval pattern using ConcurrentHashMap timestamps

Track last-sync time per entity in `ConcurrentMap<String, Instant>`. On each cycle, check elapsed time against a configurable interval before syncing. Key behaviors: always sync on first encounter (null timestamp), interval <= 0 means "always sync" (disable throttling), and update the timestamp only after successful sync (failed syncs retry next cycle). This pattern is useful for polling loops that manage many independent entities with different freshness requirements.

### Check-and-add on a non-thread-safe Set is not atomic — document the sequential caller guarantee

A `contains()` check followed by `add()` on a plain `HashSet` or `ArrayList` is a race condition when the collection is shared across threads. When thread-safety is deferred to a sequential-caller guarantee (e.g., the method is only called from a single processing thread), document that assumption inline. Without the comment, future callers may introduce concurrent access and trigger a subtle TOCTOU bug that only surfaces under load. If true thread-safety is required, use `ConcurrentHashMap.newKeySet()` and `add()` atomically, or the existing `computeIfAbsent` pattern.
