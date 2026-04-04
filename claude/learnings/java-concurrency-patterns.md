Java concurrency: per-entity sync interval tracking with ConcurrentHashMap timestamps.
- **Keywords:** ConcurrentMap, sync interval, polling, throttle, per-entity, Instant
- **Related:** ~/.claude/learnings/java-concurrency-and-resources.md

---

### Per-entity sync interval pattern using ConcurrentHashMap timestamps

Track last-sync time per entity in `ConcurrentMap<String, Instant>`. On each cycle, check elapsed time against a configurable interval before syncing. Key behaviors: always sync on first encounter (null timestamp), interval <= 0 means "always sync" (disable throttling), and update the timestamp only after successful sync (failed syncs retry next cycle). This pattern is useful for polling loops that manage many independent entities with different freshness requirements.
