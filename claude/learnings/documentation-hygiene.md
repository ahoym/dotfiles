Documentation hygiene: committed documentation that avoids security exposure and confusion.
- **Keywords:** placeholder, UUID, sandbox, environment, documentation, security, source control
- **Related:** ~/.claude/learnings/code-quality-instincts.md

---

### Replace real sandbox/environment UUIDs in committed documentation with placeholders

Real sandbox UUIDs (vault IDs, wallet IDs, organization IDs) committed to source control could overlap with staging/prod values and create confusion or security exposure. Treat sandbox identifiers as potentially sensitive — use clearly fictional placeholders like `<vault-id>` or `00000000-0000-0000-0000-000000000001` in committed docs.

## Cross-Refs

- `~/.claude/learnings/code-quality-instincts.md` -- "Don't commit hardcoded test data in production code paths" (related principle for code; this extends to documentation)
