# Re-Review Mode (Team)

Loaded when `MODE=re-review` (step 2 found a previous team review with matching `Role:.*Team-Reviewer`).

## Quick-exit (re-review)

Two-phase check with short-circuit — see step 3 in SKILL.md for the full commands.

**Phase 1** (1 call): Use **"Fetch Activity Signals (consolidated)"** from the platform cluster files. Check for: new commit SHA, new non-empty-body reviews from others, new top-level PR comments, or merged/closed state. Ignore empty-body reviews — they're wrappers for inline comments, which phase 2 catches. If any signal → proceed immediately.

**Phase 2** (1 call, only if phase 1 found nothing): Use **"Fetch Recent Inline Comments (quick-exit check)"** from the platform cluster files (fetches 10). Filter out self-comments (`Role:.*Team-Reviewer` in body). Non-self present and some new → proceed. Non-self present and all old → skip. All self → inconclusive, fall through to full fetch.

1 call when there's new activity in phase 1, 2 calls when polling quietly. Covers all four activity signals: commits, non-empty review submissions, top-level comments, inline review comments.

## Scoped Re-Launch

The key difference from single-persona re-review: only re-launch personas whose domains are affected by new changes.

1. **Identify new commits** — commits with timestamps after `LAST_REVIEW_TS`. Store as `NEW_COMMITS`.
2. **Derive changed files** — from `NEW_COMMITS`, extract `CHANGED_FILES_SINCE_LAST`.
3. **Re-run persona selection** — apply `persona-routing.md` against `CHANGED_FILES_SINCE_LAST` only. This produces `RE_REVIEW_PERSONAS` (the personas to re-launch).
4. **Identify carried-forward personas** — personas from the original review that are NOT in `RE_REVIEW_PERSONAS`. Their findings carry forward without re-review.

Announce:
```
🔄 Re-review scope: <RE_REVIEW_PERSONAS> (affected by new commits)
📋 Carried forward: <carried-forward personas> (no changes in their domain)
```

## Fetch Previous Comment State

Use **"Fetch Inline/Review Comments"** from the platform cluster files. Filter for comments containing `*Role:* Team-Reviewer` in their body. These are the team's previous comments.

For each previous comment, identify the originating persona from the inline comment attribution (e.g., `[fintech-ledger]` or `[fintech-ledger, java-spring]`).

Fetch replies for each by filtering for `in_reply_to_id` matching the comment ID. Store as `PREVIOUS_COMMENTS` with `{id, path, line, body, created_at, personas}`.

## Analyze Previous Comment Responses

Read `~/.claude/skill-references/review-comment-classification.md` for the terminal acknowledgement rule and classification criteria (Resolved, Acknowledged, Partially addressed, Not addressed).

For each comment in `PREVIOUS_COMMENTS` (skipping closed threads per the terminal acknowledgement rule):
- Read the reply (if any) and check whether corresponding code changed in `NEW_COMMITS`
- Classify using the shared criteria and apply the corresponding reaction/reply actions

Route follow-ups: partially-addressed and not-addressed comments are handled by the originating persona's subagent (identified from the comment's persona attribution). If the originating persona is not in `RE_REVIEW_PERSONAS`, the orchestrator handles the follow-up directly.

Build output lists:
- `REACTIONS`: `{comment_id, emoji}` — hooray for resolved, +1 for acknowledged
- `FOLLOW_UPS`: `{comment_id, body, persona}` — for partially/not addressed
- Text replies for resolved/acknowledged (same pattern as single-persona re-review)

## Launch Scoped Reviewers

For each persona in `RE_REVIEW_PERSONAS`:
- Front-load persona content (same as step 6)
- Launch as a foreground reviewer subagent, but with the diff scoped to `NEW_COMMITS` only
- Each subagent also receives relevant `FOLLOW_UPS` for comments it originally authored
- Subagents produce findings JSON (same schema as first review) plus follow-up replies

Collect and merge findings from re-launched subagents (same merge algorithm as step 10). Deliberation (step 11) applies if new disagreements emerge.

## Re-Review Body Template

```
## Team Re-review: <REQUEST_TITLE>

<1-2 sentence delta summary>

Reviewers (this cycle): <RE_REVIEW_PERSONAS>
Carried forward: <carried-forward personas>

### Previous Findings

- ✅ <N> resolved (code change verified)
- 👍 <N> acknowledged (agreed, pending fix)
- 🔄 <N> partially addressed
- ❌ <N> not addressed

### New Findings

<Merged findings from re-launched personas — same format as first review with signal-strength tags>

### ⚖️ Dissent (if any)

<Only if new disagreements emerged in this cycle>

### Positive Signals

<Acknowledge improvements made in response to feedback>
```

Append footnote with `Role: Team-Reviewer`.

## Post Re-Review Actions

Execute in order:

**a) React to resolved and acknowledged comments** — for each item in `REACTIONS`, use "React to Comment" from platform cluster files.

**b) Post follow-up replies** — for each item in `FOLLOW_UPS`, use "Reply to Inline Comment" from platform cluster files. Each follow-up reply gets the footnote with `Role: Team-Reviewer`.

**c) Post the review** — use "Post Review with Inline Comments" with the re-review body and any new inline comments.

**Report:**
```
🔄 Team re-review posted on <REVIEW_UNIT> #<REQUEST_NUMBER> (<M> personas this cycle)
✅ <N> resolved  👍 <N> acknowledged  🔄 <N> follow-ups  💬 <N> new inline comments
<REQUEST_URL>
```
