Staged entries for enrichment of ~/.claude/learnings/code-quality-instincts.md

---

### Use reported timestamps from external systems, not Instant.now()
When integrating with external systems (banks, exchanges, APIs), use the system's reported timestamp for event/transaction records. `Instant.now()` captures when your service processed the event, not when it actually occurred -- creating inaccurate timing data that compounds across retries, queue delays, and timezone differences. Fall back to `Instant.now()` only when the external system genuinely doesn't provide a timestamp. A missing timestamp from an external system that normally provides one is a signal worth investigating, not silently papering over.

### Explicit denomination fields on financial domain models
In multi-currency systems, add explicit denomination fields (e.g., `marketValueAsset`) to financial models rather than relying on implicit context. When a `balance` field could be denominated in any of several currencies, the denomination must travel with the value. Without it, consumers must infer the currency from context -- which breaks when the same model appears in different contexts.

### Remove unnecessary abstraction layers with single implementations
When an interface has exactly one implementation and no realistic prospect of additional ones, prefer using the concrete class directly. Indirection layers (e.g., a `Store` interface wrapping a single DAO) add cognitive load without providing polymorphic value. If a second implementation materializes later, extracting an interface is a straightforward refactor. The cost of premature abstraction (extra files, indirection, harder debugging) exceeds the cost of extracting later.
