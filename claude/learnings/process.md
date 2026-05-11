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

### Pin a bug with a failing regression test BEFORE the fix

When fixing a non-trivial bug, write the test first and confirm it fails for the reason you think the bug is. Then apply the fix and confirm the test now passes. Two payoffs: (a) you've empirically verified the bug exists where you think it does — not somewhere else producing the same symptom; (b) the test stays in the suite as a permanent regression guard against the same class of bug returning.

Especially valuable for bugs found via end-to-end runs (where the symptom and root cause are several layers apart) and for shared-mutable-state bugs where the failure is order-dependent. Cheap insurance against "fixed the wrong thing" or "the fix introduced a new bug."

### Diverging "same" runs → suspect ephemeral state, re-run before reasoning

When two runs of nominally-identical config produce different results, suspect ephemeral state before re-deriving from logs: in-flight code state mid-edit, cached data refresh between runs, partial config-file write, an env var that got toggled. Re-run the canonical baseline in the current session against current state before drawing conclusions about which result is "correct" — saves you from analyzing a phantom run that no longer reproduces.

The mistake mode is treating one of the divergent runs as authoritative and reasoning about *why it differs* from the other, when both may be artifacts. Reproducing on current state collapses the search space to one number.

### Broker permission probe sequence: symbol → market-data → preview-endpoint

Probe broker-account capability without risking capital by layering: (1) symbol lookup (broker recognizes it?), (2) live quote (data flowing?), (3) preview/dry-run endpoint (account accepts the order?). The preview is the definitive permission test — symbol and quote can succeed on accounts that still can't trade the instrument, because permission validation usually runs deeper in the order pipeline than market-data access.
