# Re-Review Mode

Loaded when `MODE=re-review` (step 4 found a previous review with matching Persona + Role).

## Quick-exit (re-review)

Two-phase check with short-circuit — see step 5 in SKILL.md for the full commands.

**Phase 1** (1 call): `gh pr view --json commits,reviews,state,comments` → new commit SHA, new reviews from others, new top-level PR comments, or merged/closed state. If any signal → proceed immediately.

**Phase 2** (1 call, only if phase 1 found nothing): `gh api .../pulls/N/comments?sort=created&direction=desc&per_page=1` → check if the most recent inline review comment is newer than `LAST_REVIEW_TS`. If yes → proceed. If no → skip.

1 call when there's new activity in phase 1, 2 calls when polling quietly. Covers all four activity signals: commits, review submissions, top-level comments, inline review comments.

## Fetch previous comment state

Use **"Fetch Inline/Review Comments"** from the platform cluster files. Filter results for comments containing both `*Persona:* <PERSONA_NAME>` and `*Role:* Reviewer` in their body. Store as our previous comments with `{id, path, line, body, created_at}`.

For each of our previous comments, fetch replies by filtering all comments for `in_reply_to_id` matching the comment ID.

Store as `PREVIOUS_COMMENTS` (our comments + their replies).

## Analyze previous comment responses

**Reviewer acknowledgement is terminal — for agent replies only.** If a thread already contains a Reviewer acknowledgement (reaction or text reply classifying the thread as resolved/acknowledged), skip subsequent *Addresser* closing remarks (identified by `*Role:* Addresser` footnote). This prevents infinite back-and-forth loops between agents. However, comments **without a Role footnote are from the operator** — they always reopen the thread regardless of prior acknowledgements. An operator follow-up question on a "resolved" thread is new activity that requires a reviewer response.

For each comment in `PREVIOUS_COMMENTS` (skipping closed threads per above):
- Read the author's reply (if any) and check whether the corresponding code changed in `NEW_COMMITS`
- Classify the response:
  - **Resolved** — concern addressed by a code change (with or without a reply). The fix is verifiable in the diff. Action: react to the *reply* comment (not our original comment) with 🎉 emoji (see "React to Comment" in platform commands), AND post a short text reply acknowledging the resolution (e.g., "Confirmed — resolved by [description]. 🎉"). If resolved by code change with no reply, react to our own comment instead and post the text reply as a self-reply.
  - **Acknowledged** — reply agrees with the finding and states intent to fix, but no code change yet. Action: react to the reply with 👍 emoji, AND post a short text reply acknowledging (e.g., "Acknowledged — thanks for confirming. 👍"). The finding stays open until a code change lands (at which point it becomes **Resolved**).
  - **Partially addressed** — some progress but original concern not fully resolved. Action: post a follow-up reply explaining what's still open.
  - **Not addressed** — no code change and no substantive reply, or reply disagrees without resolution. Action: re-raise with additional context.

Also review new code: analyze `NEW_COMMITS` changes through the persona lens, same as a first review but scoped to the delta.

Build the output lists:
- `INLINE_COMMENTS`: new findings on new/changed code.
- `REACTIONS`: list of `{comment_id, emoji}` for resolved and acknowledged comments. For **resolved**: `comment_id` is the reply's ID (not our original comment's ID), emoji is `hooray`. If no reply exists (resolved by code change alone), use our original comment's ID. For **acknowledged**: `comment_id` is the reply's ID, emoji is `+1`.
- `FOLLOW_UPS`: list of `{comment_id, body}` for partially-addressed comments.
- `SUMMARY_POINTS`: high-level themes. No file-specific details.

## Re-review body template

```
## <Persona Name> Re-review: <REQUEST_TITLE>

<1-2 sentence delta summary — what changed since last review>

### Previous Findings

- ✅ <N> resolved (code change verified)
- 👍 <N> acknowledged (agreed, pending fix)
- 🔄 <N> partially addressed
- ❌ <N> not addressed

### New Findings

<Bulleted themes from new commits — same rules as first review>

### Positive Signals

<Acknowledge improvements made in response to feedback>

---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model name>)*
*Persona:* <persona-name>
*Role:* Reviewer
```

## Post re-review actions

Execute in order:

**a) React to resolved and acknowledged comments** — for each item in `REACTIONS`, use the **"React to Comment"** section from the platform cluster files. Use the emoji specified in the reaction entry (`hooray` for resolved, `+1` for acknowledged).

**b) Post follow-up replies** — for each item in `FOLLOW_UPS`, use the **"Reply to Inline Comment"** section from the platform cluster files.

**c) Post the review** — use the **"Post Review with Inline Comments"** section. This covers the summary body and any new inline comments on new code.

**Report:**
```
🔄 Re-review posted on <REVIEW_UNIT> #<REQUEST_NUMBER>
✅ <N> resolved  👍 <N> acknowledged  🔄 <N> follow-ups  💬 <N> new inline comments
<REQUEST_URL>
```
