# Reply Templates

Use these templates when replying to review comments. Always include the co-authorship footnote.

**Avoid bare `#N` references.** GitHub auto-links `#1`, `#2`, etc. to issues/PRs. When numbering items in a reply, use backtick-wrapped `` `#1` `` or omit the `#` entirely (e.g., "item 1", "comment 1").

## Footnote Format

Every reply must end with this footnote block:

```
---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
*Persona:* <persona or "none">
*Role:* Addresser
```

- **model**: The model you're running as (e.g., "Claude Opus 4.6", "Claude Sonnet 4.6")
- **Persona**: The active persona name, or "none" if no persona is set
- **Role**: Always "Addresser" for this skill. Other skills use different roles (e.g., "Reviewer" for `git:code-review-request`)

The `Role` field is used by incremental fetches to filter out your own replies — filter comments containing `Role: Addresser` to skip self-replies.

## Acknowledging a Fix

```
Thanks for catching this! Updated `_END_YEAR` to 2026 in cfc995a.

---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
*Persona:* none
*Role:* Addresser
```

## Agreeing with Feedback

```
Good call - these were definitely overkill. Inlined both functions in abc123.

---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
*Persona:* none
*Role:* Addresser
```

## Asking for Clarification

State your understanding, then ask:

```
I think you're suggesting we extract this into a separate config dict - is that right,
or did you have a different approach in mind?

---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
*Persona:* none
*Role:* Addresser
```

## Respectfully Pushing Back

Explain context, then ask:

```
I kept this as a separate function because it's also called from `order_processor.py`
(line 142) - if we inline it here we'd have duplicate logic. Would extracting it to a
shared utils module work better, or am I missing something about the intended design?

---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
*Persona:* none
*Role:* Addresser
```
