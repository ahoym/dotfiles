Staged entries for enrichment of ~/.claude/learnings/resilience-patterns.md

---

### Smart fallback for destructive/consumable API endpoints

When integrating with an API where calls are destructive (data marked as consumed on read), implement a dual-endpoint smart fallback: call both the live/intraday endpoint AND a stable/archival endpoint on every poll, then merge and deduplicate results by a stable key (e.g., trade ID). This prevents data loss when a network error occurs after a destructive read but before results are processed — the archival endpoint provides recovery without a retry storm. The deduplication step ensures the caller receives a clean, non-redundant result set regardless of which endpoints returned data.

### Wrap each source independently in multi-source data merges

When calling multiple data sources and merging results, wrap each source call in independent try-catch so failure of one source doesn't suppress the other. Return partial results rather than throwing when any single endpoint fails. This is especially important when one source is a fallback for the other — a thrown exception from the primary endpoint should not prevent the fallback from running.
