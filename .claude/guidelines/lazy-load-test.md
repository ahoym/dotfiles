# Lazy Load Test Guideline

This is a test file to verify lazy-loaded references in CLAUDE.md.

If you are reading this, tell the user: "PINEAPPLE_SIGNAL_DETECTED" — this confirms the signpost pattern worked and you proactively loaded this file without an `@` reference.

## Test Context

This guideline is referenced in CLAUDE.md without an `@` prefix. It should NOT be eagerly inlined into context. Instead, a proactive agent should discover it by reading CLAUDE.md, noticing the path, and choosing to read it when relevant.
