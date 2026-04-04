# Process Learnings (Staging - Batch 4 General)

Enrichments and additions for `docs/learnings/process.md`.

---

### AI reviewers handle correctness/mechanical issues, freeing humans for design

In a recent MR, two AI review bots caught ~12 issues: a HIGH-severity copy-paste config bug, a MEDIUM security issue (plaintext token logging), missing annotations, lifecycle mismatches, resource leaks, and unencoded form parameters. The human reviewer left only 2 design-level comments. This division of labor -- bots catch mechanical correctness issues while humans focus on design intent and architectural fit -- is a recurring pattern that validates the investment in automated review tooling.
