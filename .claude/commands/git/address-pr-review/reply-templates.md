# Reply Templates

Use these templates when replying to PR review comments. Always include the co-authorship footnote.

## Acknowledging a Fix

```
Thanks for catching this! Updated `_END_YEAR` to 2026 in cfc995a.

---
*Co-authored with Claude Opus 4.5*
```

## Agreeing with Feedback

```
Good call - these were definitely overkill. Inlined both functions in abc123.

---
*Co-authored with Claude Opus 4.5*
```

## Asking for Clarification

State your understanding, then ask:

```
I think you're suggesting we extract this into a separate config dict - is that right,
or did you have a different approach in mind?

---
*Co-authored with Claude Opus 4.5*
```

## Respectfully Pushing Back

Explain context, then ask:

```
I kept this as a separate function because it's also called from `order_processor.py`
(line 142) - if we inline it here we'd have duplicate logic. Would extracting it to a
shared utils module work better, or am I missing something about the intended design?

---
*Co-authored with Claude Opus 4.5*
```
