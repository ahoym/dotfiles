Engineering process: AI-assisted review workflows and external-API debugging.
- **Keywords:** AI review, automated review, code review bots, division of labor, review tooling, inspection-first debugging, API field verification
- **Related:** ~/.claude/learnings/review-conventions.md, ~/.claude/learnings/code-quality-instincts.md

---

### AI reviewers handle correctness/mechanical issues, freeing humans for design

In a recent MR, two AI review bots caught ~12 issues: a HIGH-severity copy-paste config bug, a MEDIUM security issue (plaintext token logging), missing annotations, lifecycle mismatches, resource leaks, and unencoded form parameters. The human reviewer left only 2 design-level comments. This division of labor -- bots catch mechanical correctness issues while humans focus on design intent and architectural fit -- is a recurring pattern that validates the investment in automated review tooling.

### Inspection-first debugging for external API integrations

When a broker/external-API integration produces wrong output, write a one-shot `scripts/<service>/inspect_*.py` that hits the live endpoint and dumps the raw response **before** coding the fix. Don't reason from docs alone — field names drift, types differ from docs, account-type variants surface different keys.

Three-layer output beats raw JSON dump:

```
--- Candidate <thing> fields ---       # fields you expected, with values
  Equity              top='18776.88'
  CashBalance         top='18876.88'
--- All <container> keys ---           # exhaustive — catches what you missed
  ['AccountID', 'Equity', 'CashBalance', ...]
--- Raw response ---                   # full JSON for the record
```

The candidate-summary header is highest-signal: proves field name AND type AND shape in one line. Verify against multiple variants (cash + margin, equities + futures) — fixture-only verification misleads because fixtures often capture one variant.
