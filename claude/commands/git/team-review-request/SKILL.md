---
name: team-review-request
description: "Multi-persona team code review. Orchestrates parallel reviewer subagents, merges findings with signal-strength tags, surfaces disagreements via deliberation. Use when the operator asks for a team review, multi-persona review, or team code review."
argument-hint: "[request-number-or-url]"
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Team Review Request

Select relevant reviewer personas based on the PR diff, launch parallel reviewer subagents, merge their findings (with signal-strength and dissent handling), and post one unified review.

## Usage

- `/git:team-review-request` — Team review the PR/MR for the current branch
- `/git:team-review-request <number>` — Team review a specific PR/MR by number
- `/git:team-review-request <url>` — Team review a PR/MR by URL

## Prerequisites

No active persona required — this skill selects its own reviewers.

For prompt-free execution, ensure these allow patterns in `~/.claude/settings.local.json`:

```json
"Bash(gh pr view:*)",
"Bash(gh pr diff:*)",
"Bash(gh api:*)",
"Bash(gh pr review:*)",
"Read(~/.claude/learnings*/**)",
"Read(~/.claude/learnings-providers.json)",
"Read(~/.claude/commands/set-persona/**)",
"Read(~/.claude/skill-references/**)",
"Write(~/**/tmp/claude-artifacts/**)"
```

## Reference Files (conditional — read only when needed)

- `~/.claude/skill-references/request-interaction-base.md` — **Read first.** Shared fetch, tracking, footnote, and resolution patterns
- Platform cluster files — loaded via the base reference's Platform Detection section
- `persona-routing.md` — Read at step 5 for persona selection and step 10 for merge algorithm
- `reviewer-prompt-template.md` — Read at step 8, injected into subagent prompts
- `single-reviewer-mode.md` — Read only when N=1 (step 5 selects one persona)
- `re-review-mode.md` — Read only when `MODE=re-review` (step 2)

## Instructions

**Role:** Team Reviewer (orchestrator). Read `~/.claude/skill-references/request-interaction-base.md` for shared patterns (platform detection, consolidated fetch, incremental tracking, footnotes, reply naming, mutual resolution, comment identity). This skill uses `YOUR_ROLE=Team-Reviewer` throughout.

**Orchestrator personas:** Read `~/.claude/commands/set-persona/team-lead.md` and `~/.claude/commands/set-persona/reviewer.md` at skill start. The `team-lead` persona guides merge, overview composition, and deliberation. The `reviewer` persona provides base review instincts. These are the orchestrator's own lenses — distinct from the domain reviewer personas selected for subagents in step 5.

1. **Platform commands** — platform-specific commands are inlined via `!` preprocessing. No detection needed.

2. **Resolve the request and detect mode** — resolve the request number from `$ARGUMENTS` (URL → extract number, number → use directly, empty → detect from current branch). Then follow the base reference: **Consolidated Fetch** → **Terminal State Handling**.

   Check for previous team reviews using the `reviews` data already fetched. Filter for `*Role:* Team-Reviewer` in review bodies. If found, set `MODE=re-review`, store `LAST_REVIEW_ID` and `LAST_REVIEW_TS`, and read `re-review-mode.md` from this skill's directory. Otherwise, set `MODE=first-review`.

   Announce: `🔍 Mode: first review` or `🔄 Mode: re-review (previous team review from <LAST_REVIEW_TS>)`

3. **Quick-exit check** (re-review only) — follow the two-phase check in `re-review-mode.md`. If nothing has changed, emit a single line and stop:
   ```
   PR #<REQUEST_NUMBER>: no changes since last team review (<LAST_REVIEW_TS>). Skipping. 🔄
   ```

4. **Fetch PR metadata and diff** — run these in parallel using the platform cluster files:
   - **Fetch Diff** → store as `FULL_DIFF`
   - **Fetch Files Changed** → store as `CHANGED_FILES`
   - **Fetch Review Details** → store `REQUEST_BODY`
   - **Fetch Commits** → store as `COMMITS`

   For large diffs, read the full diff — thorough review requires seeing all changes.

   **Re-review only:** Also identify `NEW_COMMITS` — commits after `LAST_REVIEW_TS`.

5. **Select reviewer personas** — read `persona-routing.md` from this skill's directory, then:
   - Glob `~/.claude/commands/set-persona/*.md` to get all persona files
   - Read the first 5-10 lines of each (name + description + domain priorities heading)
   - Derive domain terms from `CHANGED_FILES` paths using judgment (see persona-routing.md)
   - Match terms against persona descriptions using the matching heuristic
   - Apply constraints: min 1, max 3. Don't select both a child and its parent persona.
   - If no domain persona matches → `reviewer` alone (N=1)

   Announce: `🎭 Team: <persona-1>, <persona-2> (matched from <domains>)` or `🎭 Single reviewer: <persona> (only domain match)`

   **If N=1:** Read `single-reviewer-mode.md` and follow its instructions. Skip steps 6 and 8-11 — the orchestrator reviews directly. Still execute step 7 (system context) — it's cheap and valuable for single-reviewer mode. Then resume at step 13.

6. **Front-load persona content** — for each selected persona:
   - Read the full persona file
   - If it has `## Extends:`, read parent persona(s) in declaration order
   - If it (or its parents) has `## Proactive Cross-Refs` or `## Proactive loads`, resolve `provider:` paths before loading: read `~/.claude/learnings-providers.json`, expand `provider:default/path` via the `defaultWriteTarget` provider's `localPath`, and `provider:<name>/path` via the named provider's `localPath`. Skip references whose provider isn't in the config.
   - Read each resolved proactive file
   - Store the combined content as `PERSONA_CONTENT[persona_name]`

7. **Identify system context for cross-cutting code** — scan `CHANGED_FILES` for cross-cutting patterns: AOP aspects (`@Aspect`), interceptors, shared utilities, SPI implementations, filters, or middleware. If found:
   - Grep the codebase for callers: annotation usages (`@ExternalService`, `@Timed`), injection sites, pointcut targets
   - For each caller, note: class name, threading model (web request, `@Scheduled`, `@Async`, message listener), and invocation frequency if discoverable (e.g., `fixedDelay` value)
   - Summarize as `SYSTEM_CONTEXT`: "Changed code is called by X (single-threaded scheduler, 30s interval), Y (web request handler, pooled threads)."

   If no cross-cutting patterns detected, set `SYSTEM_CONTEXT` to empty. This step is lightweight — a few targeted greps, not a full codebase scan.

8. **Launch parallel reviewer subagents** — read `reviewer-prompt-template.md` from this skill's directory. For each selected persona, launch a **foreground** Agent (all in one message for parallel execution). Each subagent prompt includes:
   - The reviewer prompt template with placeholders filled:
     - `{{PERSONA_NAME}}` → persona name
     - `{{PERSONA_CONTENT}}` → front-loaded content from step 6
     - `{{SYSTEM_CONTEXT}}` → caller/threading context from step 7 (or empty)
     - `{{REQUEST_TITLE}}`, `{{REQUEST_BODY}}`, `{{COMMITS}}` → PR metadata
     - `{{FULL_DIFF}}` → the full diff
     - `{{OUTPUT_FILE}}` → `tmp/claude-artifacts/change-request-replies/team-review-<REQUEST_NUMBER>-<persona>-findings.json`

   Wait for all subagents to complete before proceeding.

9. **Collect and verify findings** — read each subagent's output file. Verify per `~/.claude/skill-references/subagent-patterns.md`: spot-check that findings reference real files from the diff. Parse the structured JSON.

    **Line number correction (mandatory):** Subagents derive line numbers from the diff, which is error-prone — off-by-1-3 lines is common. For each finding, verify and correct `line_start` before merging:

    a. Extract a recognizable code token from the finding's `summary` or `inline_comment` (e.g., a function name, variable, keyword — the most specific identifier mentioned).
    b. Read the actual file content around the reported `line_start` (±5 lines): `Read(file, offset=line_start-5, limit=11)`.
    c. Check if the code token appears at `line_start`. If yes, the line number is correct — move on.
    d. If not, scan the ±5 line window for the token. If found, update `line_start` (and `line_end` by the same delta) to the correct line.
    e. If the token isn't found within ±5 lines, widen to ±10. If still not found, keep the original and flag: `⚠️ Could not verify line number for <file>:<line_start> (<token>)`.

    This step catches the most common subagent error (LLM line-counting imprecision) before it reaches GitLab. Correct lines before merging — merged findings inherit the corrected positions.

10. **Merge findings** — follow the **Merge Algorithm** in `persona-routing.md`:
    - Index findings by `(file, overlapping line range, category)`
    - **Agreement** (2+ personas, compatible): merge into one finding, tag `[persona-1, persona-2]`
    - **Unique** (1 persona): pass through with single-persona attribution `[persona-1]`
    - **Disagreement** (conflicting severity or contradictory recommendations): flag as `DISSENT_CANDIDATE`

    Not a disagreement: both agree on the problem but suggest different fixes — merge with complementary recommendations.

11. **Deliberation** (only if `DISSENT_CANDIDATES` exist) — for each disagreement between 2 personas:
    - SendMessage to Persona A's subagent: "Persona B disagrees with your finding on `<file>:<line>`. Their position: [B's summary and reasoning]. Does this change your recommendation? Respond with MAINTAIN or REVISE and brief reasoning."
    - Simultaneously SendMessage to Persona B's subagent with the symmetric prompt.
    - Both sent in parallel — neither needs the other's rebuttal.
    - **If either revises:** resolved. Use the consensus position. Tag as agreement with both personas.
    - **If both hold:** unresolved. Surface as `⚖️ DISSENT` block in the review with both positions and their rebuttals.

    For 3-way dissents (rare with max 3 reviewers): the orchestrator summarizes all positions as team lead and presents the tradeoff — no SendMessage round-trips.

12. **Compose the merged review** — build the review body:

    ```
    ## Team Review: <REQUEST_TITLE>

    <2-3 sentence overview of the change and overall assessment>

    Reviewed by: <persona-1>, <persona-2>, <persona-3>

    ### Findings

    <Grouped by theme, not by persona. ONE line per bullet — area + gist only, ≤20 words. Details live in inline comments.>
    - **[persona-1, persona-2]** Error handling gap in intent file I/O boundary
    - **[persona-3]** CLARIFY escalation has no blocking signal for degraded outcome

    ### ⚖️ Dissent

    <Only if unresolved dissents exist. For each:>
    **<topic>** — <persona-A>: <position and reasoning>. <persona-B>: <position and reasoning>. Both held after deliberation.

    ### Positive Signals

    <Themes done well, with persona attribution where relevant>
    ```

    Append the **Footnote Format** from the base reference with `Role: Team-Reviewer`. For the `*Persona:*` field, list all reviewer personas used (e.g., `*Persona:* react-frontend, financial-reviewer`), not the orchestrator's persona. The base reference's persona detection precedence (formal → ad-hoc → none) applies to single-persona skills; team-review always has explicit reviewer personas from step 5.

    **Inline comments:** for each merged finding, compose one inline comment with combined attribution. Use the most detailed `inline_comment` from the contributing subagents, prefixed with the signal-strength tag. Never post duplicate comments on the same line range.

    **Body discipline.** The body is a themed summary, not a finding ledger. Each `### Findings` bullet is **one line, ≤20 words** — area and gist only. No file paths, line numbers, fixes, or rationale (those live in the inline comment). If a bullet needs more than one line, it's too detailed for the body — move the detail to the inline comment. Summary-only findings (no inline) get one sentence + `(summary-only)` tag. Allowed sections only: overview, reviewer roster, Findings, Dissent, Positive Signals.

13. **Post the review** — write the review payload to `tmp/claude-artifacts/change-request-replies/review-<REQUEST_NUMBER>-team-reviewer.json` following the **"Post Review with Inline Comments"** format from the platform cluster files. Event: `COMMENT`.

    ```bash
    gh api repos/{owner}/{repo}/pulls/<REQUEST_NUMBER>/reviews \
      --input tmp/claude-artifacts/change-request-replies/review-<REQUEST_NUMBER>-team-reviewer.json
    ```

    **Re-review only:** Also execute reactions and follow-ups per `re-review-mode.md`.

14. **Clean up and report** — remove temp files (review payload JSON). **Preserve subagent findings JSONs** (`team-review-<N>-<persona>-findings.json`) — they contain the raw line numbers and reasoning that directors need for debugging when comments land on wrong lines. The findings are small and uniquely named; they'll be cleaned up when the operator clears `tmp/claude-artifacts/change-request-replies/`. Then confirm:
    ```
    ✅ Team review posted on <REVIEW_UNIT> #<REQUEST_NUMBER> (<N> inline comments, <M> personas)
    <REQUEST_URL>
    ```
    Re-review report format is in `re-review-mode.md`.

   **Note:** Step numbers 7-14 apply to multi-reviewer mode. Single-reviewer mode (N=1) skips to step 13.

## Important Notes

- Review is always thorough regardless of PR size — don't skip files or skim changes
- Every piece of externally-posted content gets the footnote (see base reference **Footnote Format**) with `Role: Team-Reviewer` — no exceptions
- Post the review as a `COMMENT` event (not `APPROVE` or `REQUEST_CHANGES`) — the operator decides the verdict
- If the diff is too large to fit in subagent context, tell the operator rather than silently truncating
- Re-review mode is automatic — the skill detects previous team reviews by checking for `Role:.*Team-Reviewer` in review bodies
- `Role: Team-Reviewer` is distinct from `Role: Reviewer` — the two skills do not detect each other's reviews
- **Don't post empty reviews** — if the merge produces no findings, no inline comments, and no follow-ups, skip posting entirely. **Exception**: when the review was triggered by new commits, post a brief confirmation (e.g., "Reviewed `<sha>` — no new findings") so operators can verify the commit was reviewed
- **Always run the API-based quick-exit check (step 3) in re-review.** Never skip it based on session memory.
- **Handle all activity types in one invocation.** When multiple signals are present (new replies AND new commits), handle them all — reply to comments first, then review new code
- **Advance `LAST_REVIEW_TS` after reaction-only cycles.** When a re-review posts only reactions and thread replies (no review body), advance `LAST_REVIEW_TS` to the newest non-self comment processed
