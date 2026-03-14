---
name: code-review-request
description: "Code review a pull request or merge request. Fetches diff, analyzes through active persona lens, posts review with inline comments. Detects previous reviews and handles re-review automatically. Use when the user asks to review a PR, do a code review, review a request, or review changes."
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
"Write(~/**/change-request-replies/**)"
```

## Reference Files (conditional — read only when needed)

- @~/.claude/skill-references/platform-detection.md
- `~/.claude/skill-references/github-commands.md` / `gitlab-commands.md` — Read the one matching detected platform
- `re-review-mode.md` — Read only when `MODE=re-review` (step 4)

## Instructions

1. **Verify active persona** — confirm a persona was activated this session. If not, glob `.claude/personas/` and `.claude/commands/set-persona/` for available personas, recommend the best match for the PR's domain, and wait for the user to activate one before proceeding. The persona shapes every aspect of the review — proceeding without one produces generic feedback.

2. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns. Then read the matching platform commands file (`~/.claude/skill-references/github-commands.md` or `gitlab-commands.md`).

3. **Resolve the request** — determine which PR/MR to review:
   - If `$ARGUMENTS` contains a URL, extract the number from it
   - If `$ARGUMENTS` contains a number, use it directly
   - Otherwise, detect from current branch using **"Fetch Review Details"** from the platform commands file

   Store as `REQUEST_NUMBER`, `REQUEST_TITLE`, `REQUEST_URL`, `HEAD_BRANCH`, `BASE_BRANCH`.

   **Check request state** — also fetch the PR/MR state using **"Fetch Review Details"** from the platform commands file. If the state is `MERGED` or `CLOSED`:
   1. Use `CronList` to find any cron job whose prompt contains `/git:code-review-request` and `<REQUEST_NUMBER>`
   2. If found, cancel it with `CronDelete` using the matched job ID
   3. Emit a message and stop:
   ```
   PR #<REQUEST_NUMBER> is <merged/closed>. Nothing to review. Canceled cron job <JOB_ID>. 🔄
   ```

4. **Check for previous reviews** — detect whether this is a first review or re-review by searching for both `*Persona:* <PERSONA_NAME>` AND `*Role:* Reviewer` in review bodies. Both must match — the same persona may post as Author (via `address-request-comments`) and those are separate comment chains.

   **GitHub:**
   ```bash
   gh api repos/{owner}/{repo}/pulls/<REQUEST_NUMBER>/reviews \
     --jq '[.[] | select((.body | contains("*Persona:* <PERSONA_NAME>")) and (.body | contains("*Role:* Reviewer"))) | {id, submitted_at, body}] | sort_by(.submitted_at) | last'
   ```

   **GitLab:** Check for top-level comments containing both `*Persona:* <PERSONA_NAME>` and `*Role:* Reviewer`.

   If a previous review is found, set `MODE=re-review`, store `LAST_REVIEW_ID` and `LAST_REVIEW_TS`, and read `re-review-mode.md` from the skill's base directory. Otherwise, set `MODE=first-review`.

   Announce: `🔍 Mode: first review` or `🔄 Mode: re-review (previous review from <LAST_REVIEW_TS>)`

5. **Quick-exit check** — before fetching the full diff, check if anything has changed. This is the cheapest possible check and should short-circuit polling runs that find nothing new.

   Fetch the latest commit SHA using **"Fetch Commits"** from the platform commands file (only the last entry).

   **Re-review mode:** Follow the quick-exit logic in `re-review-mode.md`.

   **First-review mode with cached analysis:** If you have high-confidence cached data from a previous invocation in this session (e.g., you already analyzed the full diff and the commit SHA matches), skip the full diff fetch and trust your cached analysis. The cheap SHA check validates the cache.

   **If nothing has changed**, emit a single line and stop — do not proceed to step 6+:
   ```
   PR #<REQUEST_NUMBER>: no changes since last review (<LAST_REVIEW_TS>). Skipping. 🔄
   ```

6. **Fetch PR metadata and diff** — run these in parallel using the platform commands file:

   - **Fetch Diff** — use the **"Fetch Diff"** section
   - **Fetch Files Changed** — use the **"Fetch Files Changed"** section
   - **Fetch Review Details** — for PR body and metadata
   - **Fetch Commits** — use the **"Fetch Commits"** section

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
   - This supplements the persona's proactive loads with PR-specific knowledge

9. **Analyze changes** — review through the active persona's lens.

   **First review:** For each file, evaluate:
   - Does the change align with the persona's domain priorities?
   - Are there taxonomy, placement, or architectural concerns?
   - Are there patterns from loaded learnings that apply?
   - Are there bugs, edge cases, or missing considerations?
   - Is there unnecessary complexity or missing simplification?

   **Re-review:** Follow `re-review-mode.md` — evaluate previous comment responses + review new code.

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

   ---
   *Co-Authored with [Claude Code](https://claude.ai/code) (<model name>)*
   *Persona:* <persona-name>
   *Role:* Reviewer
   ```

   **Re-review body:** Use the template in `re-review-mode.md`.

   **Each inline comment and follow-up reply** must end with the same footnote:
   ```

   ---
   *Co-Authored with [Claude Code](https://claude.ai/code) (<model name>)*
   *Persona:* <persona-name>
   *Role:* Reviewer
   ```

   For `<model name>`, use the model you're currently running (e.g., "Claude Opus 4.6").

11. **Post the review** — use the **"Post Review with Inline Comments"** section from the platform commands file. Write the review payload to `change-request-replies/review-<REQUEST_NUMBER>.json` and post via the API.

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
- Every piece of externally-posted content gets the footnote — no exceptions
- Post the review as a `COMMENT` event (not `APPROVE` or `REQUEST_CHANGES`) — the user decides the verdict
- If the diff is too large to fit in context, tell the user rather than silently truncating
- Re-review mode is automatic — no flag needed. The skill detects previous reviews by checking for our review comments on the PR
- Emoji reactions are the right response for resolved comments — they signal acknowledgment without creating noise
- **Cache-then-validate on repeated invocations.** If you have high-confidence cached data from a previous invocation (e.g., you already analyzed the full diff and know the latest commit SHA), you don't need to re-fetch the full diff — but you DO need to validate the cache with the quick-exit check (step 5). One cheap API call to confirm the commit SHA hasn't changed, then trust your cached analysis.
- **Don't post empty reviews** — if analysis produces no findings, no inline comments, no reactions, and no follow-ups, skip posting entirely. An empty review adds noise without value. This applies to both first-review and re-review modes.
- **Footnote format is the identity key** — if the footnote format changes, old-format reviews won't be detected as "previous reviews," causing the skill to treat a re-review as a first review. During format transitions, expect one redundant first-review post before the new format takes over
