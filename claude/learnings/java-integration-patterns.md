Staged entries for enrichment of ~/.claude/learnings/java-integration-patterns.md

---

### gRPC proto builders NPE on null string fields
Proto builders throw `NullPointerException` on `.setX(null)` for string fields. Always null-check before calling the setter in Java-to-proto translation. Pattern: `if (value != null) { builder.setField(value); }`. This applies to all proto string, bytes, and message fields -- the builder contract requires non-null values.
