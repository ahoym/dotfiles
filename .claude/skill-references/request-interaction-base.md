---
description: "Shared patterns for skills that interact with PR/MR comments: platform detection, consolidated fetch, incremental tracking, footnotes, reply conventions, and resolution filters."
---

# Request Interaction Base

Shared logic for `address-request-comments` and `code-review-request`. Skills read sections selectively — not all sections apply to every invocation.

**Read once per session.** Cache the contents after the first read. On subsequent invocations (e.g., polling via `/loop`), skip re-reading unless a new commit modifies this file — the commit SHA check in the quick-exit already detects that.

## Platform Detection

If not already detected this session, read `~/.claude/skill-references/platform-detection.md` and follow its logic to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns. Then read the matching platform cluster files:
- `~/.claude/skill-references/{github,gitlab}/fetch-review-data.md`
- `~/.claude/skill-references/{github,gitlab}/comment-interaction.md`
- `~/.claude/skill-references/{github,gitlab}/pr-management.md`

## Consolidated Fetch

Fetch state + reviews + top-level comments in a single call (GitHub):
```bash
gh pr view <number> --json state,reviews,comments,number,title,headRefName,baseRefName
```
Parse JSON response — no `--jq` (avoids quoted string permission prompts). Store `REQUEST_NUMBER`, `REQUEST_TITLE`, `HEAD_BRANCH`, `BASE_BRANCH`.

**GitLab equivalent:** `glab mr view <number> -F json -c` (includes discussions; see issue #32 for field mapping).

## Terminal State Handling

After the consolidated fetch, check state first. If terminal (merged or closed):
1. Use `CronList` to find any cron job whose prompt contains the skill name and `<REQUEST_NUMBER>`
2. If found, cancel it with `CronDelete`
3. Announce and stop

## Incremental Fetch Rules

For skills that poll repeatedly on the same review:

- Set `LAST_FETCH_TS` to the `created_at` of the newest **non-self** comment returned (not wall-clock time, not your own reply timestamps). "Self" = comments matching `Role:.*<YOUR_ROLE>` in the body.
- Comments can arrive between fetch and reply posting; using your reply's `created_at` instead would skip those.
- If no non-self comments are returned, keep the previous `LAST_FETCH_TS`.
- Filter out your own replies by matching `Role:.*<YOUR_ROLE>` (regex) in the comment body. The footer uses markdown italics (`*Role:* <role>`), so a literal substring match won't work.

**Quick-exit is a gate, not a processing shortcut.** The quick-exit check (fetching only the latest comment) determines whether any new activity exists. If new activity is detected, always perform a full incremental fetch before applying filters or processing. Never apply the Mutual Resolution Filter or categorize comments based solely on the quick-exit result — intermediate comments (especially human comments) may exist between the latest comment and `LAST_FETCH_TS`.

**General Review Comments have no `since` support.** The reviews endpoint returns all reviews every time. On incremental fetches, compare the count against `LAST_REVIEW_COUNT`. Only process reviews beyond the previous count.

**Top-level comments** are included in the consolidated fetch's `comments` field. On incremental fetches, filter by `createdAt > LAST_FETCH_TS` and exclude self-replies.

## Comment Identity

Distinguish comment authors by checking the footnote:
- `Role:.*Reviewer` → reviewer agent
- `Role:.*Addresser` → addresser agent
- No `Role:` tag → human

Both `Persona` and `Role` must match to identify a specific agent's comments (the same persona may post as both Reviewer and Addresser on the same PR).

## Footnote Format

Every externally-posted reply, review body, and inline comment must end with:
```
---
*Co-Authored with [Claude Code](https://claude.ai/code) (<model>)*
*Persona:* <persona-name or "none">
*Role:* <Reviewer|Addresser>
```
Use the model you're currently running (e.g., "Claude Opus 4.6"). This footnote is the identity key — detection of previous reviews, self-reply filtering, and mutual resolution all depend on it.

## Reply File Naming

Write reply bodies to `change-request-replies/<id>-<persona>-<role>.md` before posting. The persona+role suffix prevents file conflicts when multiple agents operate on the same PR concurrently.

Top-level comments: `change-request-replies/<number>-<persona>-<role>-top.md`.

**Path selection for tool calls (Read, Write, Edit/Update):** Use CWD-relative paths when CWD is a symlinked `~/.claude` repo (tilde paths normalize through the symlink and fail permission matching). Use `~/` paths in non-symlinked contexts. Never use absolute `/Users/.../` paths — they match neither pattern style. Note: the Edit tool displays as `Update` in permission prompts — `Edit(...)` allow patterns don't match `Update` prompts. Add `Update(...)` companion patterns for every `Edit(...)` pattern.

## Mutual Resolution Filter

A thread is mutually resolved when ALL of these are true:
- The comment is from the **other** role (`Role:.*<OTHER_ROLE>` in body)
- The comment is a resolution signal (contains: "resolved", "acknowledged", "sounds good", "thread resolved", "no code change needed", "no action needed", or is purely emoji like 👍/🤝)
- You have already posted a substantive reply on the same thread (`in_reply_to_id` matches a thread where your role's reply exists)
- No unaddressed human comments (no `Role:` tag in body) exist in the thread after your last reply. A human comment between your reply and the resolution signal breaks the resolution chain — that comment must be processed first.

When mutual resolution is detected, skip the comment entirely — no reaction, no reply. Just update `LAST_FETCH_TS` and move on. Announce: `Thread <file>:<line> — mutual resolution detected, skipping.`

## Quiet No-Op

When an incremental fetch returns no new comments (inline, top-level, and review counts all unchanged), emit a single line and stop:
```
<REVIEW_UNIT> #<number>: no new comments (<LAST_FETCH_TS>)
```
Do not proceed to analysis or processing steps.

## Stale Poll Auto-Cancel

After a quiet no-op, check whether the poll has been idle long enough to cancel. Track the last activity epoch in session state (conversation context) — no files needed since the state shares the cron job's session lifecycle.

**Session variable:** `POLL_LAST_ACTIVITY_<REQUEST_NUMBER>` — UTC epoch seconds. Set when the poll starts and reset on any non-no-op iteration.

1. **Check for matching cron job.** `CronList` — find any job whose prompt contains the skill name and `<REQUEST_NUMBER>`. If not found (manual invocation), skip the entire staleness check.
2. **Check session variable.** If `POLL_LAST_ACTIVITY_<REQUEST_NUMBER>` is not set, set it to the current epoch (`date -u +%s`). This means the poll just started — skip the cancel.
3. **Compare.** Run `date -u +%s` for current time. If `current - POLL_LAST_ACTIVITY_<REQUEST_NUMBER> < 1800` (30 minutes), skip the cancel.
4. **Cancel if stale.** If delta >= 1800: `CronDelete` and announce: `Stale review — no new comments for 30m on <REVIEW_UNIT> #<number>, cancelled poll (<job_id>).`

**Resetting the clock:** When the skill processes new activity (any non-no-op iteration — including mutual resolutions), set `POLL_LAST_ACTIVITY_<REQUEST_NUMBER>` to the current epoch. This resets the 30-minute window.

This is a sibling to Terminal State Handling: both auto-cancel polls that no longer need to run. Terminal state catches merged/closed PRs; stale poll catches idle reviews where the reviewer hasn't responded.
