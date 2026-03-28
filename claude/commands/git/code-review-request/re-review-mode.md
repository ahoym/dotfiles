# Re-Review Mode

Loaded when `MODE=re-review` (step 4 found a previous review with matching Persona + Role).

## Quick-exit (re-review)

Two-phase check with short-circuit — see step 5 in SKILL.md for the full commands.

**Phase 1** (1 call): Use **"Fetch Activity Signals (consolidated)"** from the platform cluster files. Check for: new commit SHA, new non-empty-body reviews from others, new top-level PR comments, or merged/closed state. Ignore empty-body reviews — they're wrappers for inline comments, which phase 2 catches. If any signal → proceed immediately.

**Phase 2** (1 call, only if phase 1 found nothing): Use **"Fetch Recent Inline Comments (quick-exit check)"** from the platform cluster files (fetches 10). Filter out self-comments (`Role:.*<YOUR_ROLE>` in body). Non-self present and some new → proceed. Non-self present and all old → skip. All self → inconclusive, fall through to full fetch.

1 call when there's new activity in phase 1, 2 calls when polling quietly. Covers all four activity signals: commits, non-empty review submissions, top-level comments, inline review comments.

## Fetch previous comment state

Use **"Fetch Inline/Review Comments"** from the platform cluster files. Filter results for comments containing both `*Persona:* <PERSONA_NAME>` and `*Role:* Reviewer` in their body. Store as our previous comments with `{id, path, line, body, created_at}`.

For each of our previous comments, fetch replies by filtering all comments for `in_reply_to_id` matching the comment ID.

Store as `PREVIOUS_COMMENTS` (our comments + their replies).

## Analyze previous comment responses

Read `~/.claude/skill-references/review-comment-classification.md` for the terminal acknowledgement rule and classification criteria (Resolved, Acknowledged, Partially addressed, Not addressed).

For each comment in `PREVIOUS_COMMENTS` (skipping closed threads per the terminal acknowledgement rule):
- Read the author's reply (if any) and check whether the corresponding code changed in `NEW_COMMITS`
- Classify using the shared criteria and apply the corresponding reaction/reply actions

Also review new code: analyze `NEW_COMMITS` changes through the persona lens, same as a first review but scoped to the delta.

Build the output lists:
- `INLINE_COMMENTS`: new findings on new/changed code.
- `REACTIONS`: list of `{comment_id, emoji}` per the shared classification's reaction summary table.
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
