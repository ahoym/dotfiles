# Re-Review Mode

Loaded when `MODE=re-review` (step 4 found a previous review with matching Persona + Role).

## Quick-exit (re-review)

Compare the latest commit SHA against `LAST_REVIEW_TS`. Also count new replies to our previous comments using **"Fetch Inline/Review Comments"** from the platform commands file, filtering for `created_at > LAST_REVIEW_TS` and `in_reply_to_id != null`. If no new commits AND no new replies → skip.

## Fetch previous comment state

Use **"Fetch Inline/Review Comments"** from the platform commands file. Filter results for comments containing both `*Persona:* <PERSONA_NAME>` and `*Role:* Reviewer` in their body. Store as our previous comments with `{id, path, line, body, created_at}`.

For each of our previous comments, fetch replies by filtering all comments for `in_reply_to_id` matching the comment ID.

Store as `PREVIOUS_COMMENTS` (our comments + their replies).

## Analyze previous comment responses

For each comment in `PREVIOUS_COMMENTS`:
- Read the author's reply (if any) and check whether the corresponding code changed in `NEW_COMMITS`
- Classify the response:
  - **Resolved** — concern addressed by code change, reply, or both. Action: react with ✅ emoji (see "React to Comment" in platform commands). No text reply.
  - **Partially addressed** — some progress but original concern not fully resolved. Action: post a follow-up reply explaining what's still open.
  - **Not addressed** — no code change and no substantive reply, or reply disagrees without resolution. Action: re-raise with additional context.
  - **Acknowledged (no action needed)** — our comment was informational/positive and the author acknowledged it. Action: no response needed.

Also review new code: analyze `NEW_COMMITS` changes through the persona lens, same as a first review but scoped to the delta.

Build the output lists:
- `INLINE_COMMENTS`: new findings on new/changed code.
- `REACTIONS`: list of `{comment_id, emoji}` for resolved comments.
- `FOLLOW_UPS`: list of `{comment_id, body}` for partially-addressed comments.
- `SUMMARY_POINTS`: high-level themes. No file-specific details.

## Re-review body template

```
## <Persona Name> Re-review: <REQUEST_TITLE>

<1-2 sentence delta summary — what changed since last review>

### Previous Findings

- ✅ <N> resolved
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

**a) React to resolved comments** — for each item in `REACTIONS`, use the **"React to Comment"** section from the platform commands file. React with `+1` (GitHub) or `thumbsup` (GitLab).

**b) Post follow-up replies** — for each item in `FOLLOW_UPS`, use the **"Reply to Inline Comment"** section from the platform commands file.

**c) Post the review** — use the **"Post Review with Inline Comments"** section. This covers the summary body and any new inline comments on new code.

**Report:**
```
🔄 Re-review posted on <REVIEW_UNIT> #<REQUEST_NUMBER>
✅ <N> resolved (reacted)  🔄 <N> follow-ups posted  💬 <N> new inline comments
<REQUEST_URL>
```
