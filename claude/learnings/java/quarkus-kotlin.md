Quarkus dev mode incremental compilation gotchas when working with Kotlin enums.
- **Keywords:** quarkus, kotlin, enum, dev mode, hot reload, incremental compilation, mvn clean
- **Related:** none

---

## Enum changes require clean build in dev mode

Quarkus dev mode (`mvn quarkus:dev`) incremental compilation does **not** detect new Kotlin enum values. Symptoms: `IllegalArgumentException: No enum constant ...` at runtime despite correct source code, and Maven logs showing "Nothing to compile - all classes are up to date."

**Fix**: Use `mvn clean quarkus:dev` whenever adding/removing enum values. Regular code changes (method bodies, new classes) hot-reload fine.

## Cross-Refs

No cross-cluster references.
