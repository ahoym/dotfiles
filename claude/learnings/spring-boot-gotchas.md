Spring Boot timezone gotcha: fixed-offset external systems vs DST-aware zone IDs.
- **Keywords:** ZoneOffset, ZoneId, DST, timezone, fixed offset, external system
- **Related:** ~/.claude/learnings/java-spring-boot-gotchas.md

---

- Fixed-offset external systems: use `ZoneOffset.ofHours(-5)`, not `ZoneId.of("America/New_York")`. Geographic zone IDs observe DST, producing incorrect conversions for roughly half the year when the external system documents a fixed UTC offset. The existing guideline (prefer `ZoneId` for DST-aware zones) applies to internal/user-facing time handling — the opposite applies when you're matching an external system's documented, non-DST-adjusted offset. Verify from the feed's documentation which applies.
