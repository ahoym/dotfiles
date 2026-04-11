---
description: "Shared classification criteria for re-review comment analysis — used by code-review-request and team-review-request re-review modes."
---

# Review Comment Classification

Shared criteria for classifying previous review comment responses during re-review.

## Terminal Acknowledgement Rule

If a thread already contains a reviewer acknowledgement (reaction or text reply classifying the thread as resolved/acknowledged), skip subsequent *Addresser* closing remarks (identified by `*Role:* Addresser` footnote). This prevents infinite back-and-forth loops between agents. However, comments **without a Role footnote are from the operator** — they always reopen the thread regardless of prior acknowledgements. An operator follow-up question on a "resolved" thread is new activity that requires a reviewer response.

## Classification Criteria

For each previous comment, read the reply (if any) and check whether the corresponding code changed in `NEW_COMMITS`:

- **Resolved** — concern addressed by a code change (with or without a reply). The fix is verifiable in the diff. Action: react to the *reply* comment (not the original comment) with 🚀 emoji. **No text reply** — the reaction is the acknowledgement; a text reply would just re-iterate what the addresser already said and add noise. If resolved by code change with no reply, react to the original comment instead.
- **Acknowledged** — reply agrees with the finding and states intent to fix, but no code change yet. Action: react to the reply with 👍 emoji. **No text reply** — same reasoning as Resolved. The finding stays open until a code change lands (at which point it becomes **Resolved**).
- **Partially addressed** — some progress but original concern not fully resolved. Action: post a follow-up reply explaining what's still open.
- **Not addressed** — no code change and no substantive reply, or reply disagrees without resolution. Action: re-raise with additional context.

## Reaction Summary

| Classification | Emoji | Target | Text reply? |
|---------------|-------|--------|-------------|
| Resolved | `rocket` | Reply comment (or original if no reply) | No — reaction is the acknowledgement |
| Acknowledged | `thumbsup` | Reply comment | No — reaction is the acknowledgement |
| Partially addressed | — | — | Yes — explain what's still open |
| Not addressed | — | — | Yes — re-raise with context |
