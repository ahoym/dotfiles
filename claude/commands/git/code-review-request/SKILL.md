---
name: code-review-request
description: "Code review a pull request or merge request. Fetches diff, analyzes through active persona lens, posts review with inline comments. Detects previous reviews and handles re-review automatically. Use when the operator asks to review a PR, do a code review, review a request, or review changes."
argument-hint: "[request-number-or-url]"
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Code Review Request

Fetch a PR/MR diff, analyze it through the active persona's lens, and post a review with inline comments — all footnoted with model and persona attribution. On consecutive runs, automatically detects previous reviews and enters re-review mode.

## Usage

- `/git:code-review-request` - Review the PR/MR for the current branch
- `/git:code-review-request <number>` - Review a specific PR/MR by number
- `/git:code-review-request <url>` - Review a PR/MR by URL

## Prerequisites

Requires an **active persona** — the persona provides the review lens (priorities, tradeoffs, domain knowledge). If no persona is active, recommend one and wait for activation.

For prompt-free execution, ensure these allow patterns in `~/.claude/settings.local.json`:

```json
"Bash(gh pr view:*)",
"Bash(gh pr diff:*)",
"Bash(gh api:*)",
"Bash(gh pr review:*)",
"Read(~/.claude/learnings/**)",
"Read(~/.claude/commands/set-persona/**)",
"Write(~/**/tmp/change-request-replies/**)"
```

## Reference Files (conditional — read only when needed)

- `~/.claude/skill-references/request-interaction-base.md` — **Read first.** Shared fetch, tracking, footnote, and resolution patterns
- Platform cluster files — loaded via the base reference's Platform Detection section
- `re-review-mode.md` — Read only when `MODE=re-review` (step 4)

## Instructions

**Role:** Reviewer. Read `~/.claude/skill-references/request-interaction-base.md` for shared patterns (platform detection, consolidated fetch, incremental tracking, footnotes, reply naming, mutual resolution, comment identity). This skill uses `YOUR_ROLE=Reviewer` and `OTHER_ROLE=Addresser` throughout.

1. **Verify active persona** — a persona is active if set via `/set-persona` or an ad-hoc prompt (e.g., "act as a senior infosec engineer", "you are a security reviewer"). For ad-hoc, extract a short name and proceed. If neither is active, glob `.claude/personas/` and `~/.claude/commands/set-persona/` for available personas, recommend the best match, and wait for activation. The persona shapes every aspect of the review — proceeding without one produces generic feedback.

2. **Detect platform** — follow **Platform Detection** from the base reference.

3. **Resolve the request and detect mode** — resolve the request number from `$ARGUMENTS` (URL → extract number, number → use directly, empty → detect from current branch). Then follow the base reference: **Consolidated Fetch** → **Terminal State Handling**.

4. **Check for previous reviews** — using the `reviews` data already fetched in step 3, filter for both `*Persona:* <PERSONA_NAME>` AND `*Role:* Reviewer` in review bodies. Both must match — the same persona may post as Author (via `address-request-comments`) and those are separate comment chains.

   **GitLab:** Check for top-level comments containing both `*Persona:* <PERSONA_NAME>` and `*Role:* Reviewer` (requires a separate API call).

   If a previous review is found, set `MODE=re-review`, store `LAST_REVIEW_ID` and `LAST_REVIEW_TS`, and read `re-review-mode.md` from the skill's base directory. Otherwise, set `MODE=first-review`.

   Announce: `🔍 Mode: first review` or `🔄 Mode: re-review (previous review from <LAST_REVIEW_TS>)`

5. **Quick-exit check** — before fetching the full diff, check if anything has changed. This is the cheapest possible check and should short-circuit polling runs that find nothing new.

   **Non-negotiable: run both phases as specified.** Do not reduce phase 1 fields or skip phase 2 to save tokens. Consecutive no-ops create optimization pressure — resist it. The cost is 1-2 API calls; the failure mode is missed operator comments.

   **Re-review mode** — two-phase check, short-circuiting on the first signal:

   **Phase 1 (1 call):** Using the section index from `fetch-review-data.md`, `Read` the file at `fetch-activity-signals`'s offset/limit, substitute placeholders, and execute. Parse the JSON response to check:
   - **New commits**: latest commit SHA differs from last reviewed
   - **New reviews from others**: any review with a non-empty body submitted after `LAST_REVIEW_TS` that doesn't contain our persona+role footnote. Ignore empty-body reviews — they're wrappers for inline comments, which phase 2 catches reliably.
   - **New top-level comments**: any comment created after `LAST_REVIEW_TS`
   - **State**: if `MERGED` or `CLOSED` → cancel cron and stop (step 3 logic)

   If any activity signal → proceed to step 6+ (skip phase 2).

   **Phase 2 (1 call, only if phase 1 found nothing):** Using the section index from `comment-interaction.md`, `Read` the file at `fetch-recent-inline-comments`'s offset/limit, substitute placeholders, and execute (fetches 10). Filter out self-comments (`Role:.*<YOUR_ROLE>` in body). Non-self present and some new → proceed. Non-self present and all old → skip. All self → inconclusive, fall through to full incremental fetch.

   This is 1 call when there's new activity in phase 1, 2 calls when polling quietly. All four activity signals (commits, non-empty reviews, top-level comments, inline comments) are covered.

   **First-review mode with cached analysis:** If you have high-confidence cached data from a previous invocation in this session (e.g., you already analyzed the full diff and the commit SHA matches), skip the full diff fetch and trust your cached analysis. The cheap SHA check validates the cache.

   **If nothing has changed**, emit a single line and stop — do not proceed to step 6+:
   ```
   PR #<REQUEST_NUMBER>: no changes since last review (<LAST_REVIEW_TS>). Skipping. 🔄
   ```

6. **Fetch PR metadata and diff** — run these in parallel using the platform cluster files:

   Using the section index from `fetch-review-data.md`, for each command below,
   `Read` the file at the section's offset/limit, substitute placeholders, and execute:
   - `fetch-diff` — full diff
   - `fetch-files-changed` — file list
   - `fetch-review-details` — PR body and metadata
   - `fetch-commits` — commit history

   Store the diff as `FULL_DIFF`, file list as `CHANGED_FILES`, body as `REQUEST_BODY`, commits as `COMMITS`.

   For large diffs, read the full diff — thorough review requires seeing all changes.

   **Re-review only:** Also identify `NEW_COMMITS` — commits with timestamps after `LAST_REVIEW_TS`.

7. **Fetch previous comment state** (re-review only) — follow `re-review-mode.md`.

8. **Load domain-relevant learnings** — match `CHANGED_FILES` paths and domains against learnings filenames:
   - Glob `~/.claude/learnings/*.md`, `~/.claude/learnings-private/*.md`, and `docs/learnings/*.md` to get the full inventory
   - For each changed file, derive domain terms from the path and content (e.g., `src/api/` -> "api", `.github/workflows/` -> "ci-cd", `tests/` -> "testing")
   - Match domain terms against learnings filenames (e.g., "ci" matches `ci-cd.md`, "test" matches `testing-patterns.md`)
   - Read matched files to ground the review in established knowledge
   - Announce: `📚 Loaded domain learnings: <list>`
   - This supplements the persona's proactive cross-refs with PR-specific knowledge

9. **Analyze changes** — review through the active persona's lens. **Base analysis only on MR content** — the diff, changed files, MR body, commits, and loaded learnings. The consolidated fetch includes existing reviews and comments for mode detection only; do not read, reference, or let them influence your findings. Your review must be fully independent. Redundant findings across reviewers are expected; influenced findings are not.

   **First review:** For each file, evaluate:
   - Does the change align with the persona's domain priorities?
   - Are there taxonomy, placement, or architectural concerns?
   - Are there patterns from loaded learnings that apply?
   - Are there bugs, edge cases, or missing considerations?
   - Is there unnecessary complexity or missing simplification?

   **Re-review:** Follow `re-review-mode.md` — evaluate previous comment responses + review new code.

   **Separate identification from suggestion.** Finding an issue and proposing a fix require independent reasoning. A wrong suggestion compounds — the addresser implements it, the reviewer confirms it, and the operator unwinds multiple layers. Verify a rule's scope before citing it, think about what actually improves the content, and when uncertain, identify without prescribing.

   Build the output lists:
   - `INLINE_COMMENTS`: new findings on new/changed code. All specifics belong here — not in the summary.
   - `SUMMARY_POINTS`: high-level themes. No file-specific details.

   **No duplication between summary and inline comments.** The summary names themes; inline comments carry the specifics.

10. **Compose the review** — build the review payload:

   **First review body** (summary — themes only, no file-specific details):
   ```
   ## <Persona Name> Review: <REQUEST_TITLE>

   <2-3 sentence overview of the change and overall assessment>

   ### Findings

   <Bulleted themes — group by concern, not by file. No filenames or line numbers here.>

   ### Positive Signals

   <What's done well — themes and patterns, not file-by-file inventory>
   ```

   Append the **Footnote Format** from the base reference (Role: Reviewer) to the review body.

   **Re-review body:** Use the template in `re-review-mode.md`.

   **Each inline comment and follow-up reply** must also end with the footnote.

11. **Post the review** — using the section index from `pr-management.md`, `Read` the file at `post-review-with-inline-comments`'s offset/limit, substitute placeholders, and execute. Write the review payload following the **Reply File Naming** convention from the base reference (e.g., `tmp/change-request-replies/review-<REQUEST_NUMBER>-<PERSONA>-reviewer.json`).

    **Re-review only:** Also execute reactions and follow-ups per `re-review-mode.md`.

12. **Clean up and report** — remove temp files, then confirm:
    ```
    ✅ Review posted on <REVIEW_UNIT> #<REQUEST_NUMBER> (<N> inline comments)
    <REQUEST_URL>
    ```
    Re-review report format is in `re-review-mode.md`.

## Important Notes

- Review is always thorough regardless of PR size — don't skip files or skim changes
- The persona's judgment lens shapes what you look for and how you weigh findings
- Domain learnings ground the review in established patterns — cite them when relevant
- Every piece of externally-posted content gets the footnote (see base reference **Footnote Format**) — no exceptions
- Post the review as a `COMMENT` event (not `APPROVE` or `REQUEST_CHANGES`) — the operator decides the verdict
- If the diff is too large to fit in context, tell the operator rather than silently truncating
- Re-review mode is automatic — no flag needed. The skill detects previous reviews by checking for our review comments on the PR
- For resolved and acknowledged comments, post both an emoji reaction AND a short text reply — the reaction is a quick signal, the text reply provides visibility in the comment thread for async review
- **Always run the API-based quick-exit check (step 5).** Never skip it based on session memory of the last SHA or timestamp. The full phase 1+2 check is cheap (1-2 API calls) and catches activity that session memory misses — especially operator comments on threads you thought were closed. Caching applies to the *diff analysis* (step 6+), not to *activity detection* (step 5).
- **Don't post empty reviews** — if analysis produces no findings, no inline comments, and no follow-ups, skip posting entirely. An empty review adds noise without value. **Exception**: when the review was triggered by new commits, post a brief confirmation (e.g., "Reviewed `<sha>` — no new findings") so operators can verify the commit was reviewed. In re-review mode, resolved/acknowledged responses without new findings or follow-ups don't warrant a summary — post the reactions and text replies, then skip the review body.
- **Advance `LAST_REVIEW_TS` after reaction-only cycles.** When a re-review posts only reactions and thread replies (no review body), advance `LAST_REVIEW_TS` to the `created_at` of the newest non-self comment processed. Without this, subsequent polls re-detect already-processed addresser replies as "new" activity, wasting API calls and context every cycle until the stale poll auto-cancel fires.
- **Handle all activity types in one invocation.** When multiple signals are present (e.g., new inline replies AND new commits), handle them all — don't stop after replying to threads. Reply to comments first (step 7), then proceed through steps 8-12 to review the new code. Splitting these across poll cycles delays review of new commits.
- **Footnote format is the identity key** — if the footnote format changes, old-format reviews won't be detected as "previous reviews," causing the skill to treat a re-review as a first review. During format transitions, expect one redundant first-review post before the new format takes over
