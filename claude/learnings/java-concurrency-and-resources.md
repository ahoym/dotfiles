Staged entries for enrichment of ~/.claude/learnings/java-concurrency-and-resources.md

---

### Check-and-add on a non-thread-safe Set is not atomic — document the sequential caller guarantee

A `contains()` check followed by `add()` on a plain `HashSet` or `ArrayList` is a race condition when the collection is shared across threads. When thread-safety is deferred to a sequential-caller guarantee (e.g., the method is only called from a single processing thread), document that assumption inline. Without the comment, future callers may introduce concurrent access and trigger a subtle TOCTOU bug that only surfaces under load. If true thread-safety is required, use `ConcurrentHashMap.newKeySet()` and `add()` atomically, or the existing `computeIfAbsent` pattern from the cache entries above.
