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
"Read(~/.claude/learnings*/**)",
"Read(~/.claude/learnings-providers.json)",
"Read(~/.claude/commands/set-persona/**)",
"Read(~/.claude/skill-references/**)",
"Write(~/**/tmp/claude-artifacts/**)"
```

## Reference Files (conditional — read only when needed)

- `~/.claude/skill-references/request-interaction-base.md` — **Read first.** Shared footnote format, reply naming, incremental tracking, mutual resolution, and comment identity patterns
- `persona-routing.md` — Read at step 5 for persona selection and step 10 for merge algorithm
- `reviewer-prompt-template.md` — Read at step 8, injected into subagent prompts
- `line-number-verification.md` — Read at step 9, MANDATORY line-number correction before merging findings
- `single-reviewer-mode.md` — Read only when N=1 (step 5 selects one persona)
- `re-review-mode.md` — Read only when `MODE=re-review` (step 2)

## Instructions

**Role:** Team Reviewer (orchestrator). Read `~/.claude/skill-references/request-interaction-base.md` for shared patterns (footnotes, reply naming, incremental tracking, mutual resolution, comment identity). Platform commands are inlined at each step — no detection or cluster file reading needed. This skill uses `YOUR_ROLE=Team-Reviewer` throughout.

**Orchestrator personas:** Read `~/.claude/commands/set-persona/team-lead.md` and `~/.claude/commands/set-persona/reviewer.md` at skill start. The `team-lead` persona guides merge, overview composition, and deliberation. The `reviewer` persona provides base review instincts. These are the orchestrator's own lenses — distinct from the domain reviewer personas selected for subagents in step 5.

1. **Platform commands** — platform-specific commands are inlined via `!` preprocessing. No detection needed.

2. **Resolve the request and detect mode** — resolve the request number from `$ARGUMENTS` (URL → extract number, number → use directly, empty → detect from current branch). A non-number/non-URL directive (e.g. `from fresh`, `from scratch`) → detect the number from the current branch AND force `MODE=first-review`, reviewing the full current diff anew and ignoring any prior Team-Reviewer review the detection below would otherwise match.

   **Consolidated Fetch:**
   ```
   !`cat ~/.claude/platform-commands/consolidated-fetch.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```
   Parse JSON response. Store `REQUEST_NUMBER`, `REQUEST_TITLE`, `HEAD_BRANCH`, `BASE_BRANCH`.

   **Terminal State Handling:** Check state first. If terminal (merged or closed): load deferred tool schemas via `ToolSearch("select:CronList,CronDelete")`, then use `CronList` to find any cron job whose prompt contains the skill name and `<REQUEST_NUMBER>`, cancel it with `CronDelete` if found, announce and stop.

   Check for previous team reviews using the `reviews` data already fetched. Filter for `*Role:* Team-Reviewer` in review bodies. If found, set `MODE=re-review`, store `LAST_REVIEW_ID` and `LAST_REVIEW_TS`, and read `re-review-mode.md` from this skill's directory. Otherwise, set `MODE=first-review`.

   Announce: `🔍 Mode: first review` or `🔄 Mode: re-review (previous team review from <LAST_REVIEW_TS>)`

3. **Quick-exit check** (re-review only) — follow the two-phase check in `re-review-mode.md`. If nothing has changed, emit a single line and stop:
   ```
   PR #<REQUEST_NUMBER>: no changes since last team review (<LAST_REVIEW_TS>). Skipping. 🔄
   ```

4. **Fetch PR metadata and diff** — run these in parallel:

   **Fetch Diff** → store as `FULL_DIFF`:
   ```
   !`cat ~/.claude/platform-commands/fetch-review-diff.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```

   **Fetch Files Changed** → store as `CHANGED_FILES`:
   ```
   !`cat ~/.claude/platform-commands/fetch-review-files.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```

   **Fetch Review Details** → store `REQUEST_BODY`:
   ```
   !`cat ~/.claude/platform-commands/fetch-review-details.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```

   **Fetch Commits** → store as `COMMITS`:
   ```
   !`cat ~/.claude/platform-commands/fetch-review-commits.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
   ```

   For large diffs, read the full diff — thorough review requires seeing all changes.

   **Artifact path discipline.** If you write the diff (or any scratch file) to disk during this skill, use `tmp/claude-artifacts/change-request-replies/` — the standard dir for this skill family. Any subdirectory of `tmp/claude-artifacts/` is covered by the settings.json wildcards (`Read`/`Write`/`Bash(bash …)` on `tmp/claude-artifacts/**`, plus `mkdir:*`); the actual gotcha is that a bash `>` redirect can't create parent directories, so a brand-new subdir fails with "no such file or directory" until you `mkdir -p` it. Reusing the existing dir avoids that extra step and keeps all skill artifacts in one predictable place — step 8's diff-artifact prescription uses this same dir.

   **Re-review only:** Also identify `NEW_COMMITS` — commits after `LAST_REVIEW_TS`.

5. **Select reviewer personas** — read `persona-routing.md` from this skill's directory, then:
   - Glob `~/.claude/commands/set-persona/*.md` to get all persona files
   - Issue parallel `Read(persona_file, limit=10)` calls — one tool block, all personas at once. Do **not** use `bash for-loop + head` or any quoted-string shell pattern — those trigger permission prompts and break the fire-and-forget contract. The header (name + description + `## Domain priorities` heading) fits in 10 lines.
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

   **Don't drop the parent when writing the subagent prompt.** For personas with `## Extends`, the text injected at `{{PERSONA_CONTENT}}` in step 8 must literally contain parent + child concatenated (mindset, methodology, proactive loads) — pasting only the child's specialized section strips the base `reviewer` persona's code-quality/process instincts from every extends-based subagent. Easy to get right at step 6 (reading the parent) and still lose at step 8 (forgetting to paste it into the prompt).

   **Curate for narrow diffs.** A proactive-load file (e.g. `gitlab-ci-cd.md`, `concurrency-and-resources.md`) is often hundreds of lines covering a broad domain; a diff touching one small package rarely needs all of it, and the cost multiplies by reviewer count (N personas × full files). After reading each proactive file, extract only the sections plausibly relevant to `CHANGED_FILES`' actual content (file types touched, patterns present) into `PERSONA_CONTENT` — skip sections on domains absent from the diff (e.g. CI/CD learnings when no `.gitlab-ci.yml`/pipeline file changed). This is consistent with the reviewer template's step 2 ("learnings are supplementary, not the primary driver") — full-file inclusion is the safe default for large/cross-cutting diffs, but disproportionate for a 3-file, single-package change.

7. **Identify system context for cross-cutting code** — scan `CHANGED_FILES` for cross-cutting patterns: AOP aspects (`@Aspect`), interceptors, shared utilities, SPI implementations, filters, or middleware. If found:
   - Grep the codebase for callers: annotation usages (`@ExternalService`, `@Timed`), injection sites, pointcut targets
   - For each caller, note: class name, threading model (web request, `@Scheduled`, `@Async`, message listener), and invocation frequency if discoverable (e.g., `fixedDelay` value)
   - Summarize as `SYSTEM_CONTEXT`: "Changed code is called by X (single-threaded scheduler, 30s interval), Y (web request handler, pooled threads)."

   If no cross-cutting patterns detected, set `SYSTEM_CONTEXT` to empty. This step is lightweight — a few targeted greps, not a full codebase scan.

8. **Launch parallel reviewer subagents** — read `reviewer-prompt-template.md` from this skill's directory.

   **Write the diff to a tmp artifact first.** Save `FULL_DIFF` to `tmp/claude-artifacts/change-request-replies/team-review-<REQUEST_NUMBER>-diff.txt` and pass the path to subagents — do not inline the diff in each prompt. Inlining duplicates the diff N times (one per reviewer), which adds up fast for large MRs (a 70KB diff × 3 reviewers = ~210KB of duplicate prompt cost). See `~/.claude/learnings/claude-code/multi-agent/orchestration.md` → "Stage a Large Shared Read-Only Input as a File". A staged tmp artifact isn't "the repository," so the template's no-repo-reads rule still holds.

   For each selected persona, launch a **foreground** Agent (all in one message for parallel execution). Each subagent prompt includes:
   - The reviewer prompt template with placeholders filled:
     - `{{PERSONA_NAME}}` → persona name
     - `{{PERSONA_CONTENT}}` → front-loaded content from step 6
     - `{{SYSTEM_CONTEXT}}` → caller/threading context from step 7 (or empty)
     - `{{REQUEST_TITLE}}`, `{{REQUEST_BODY}}`, `{{COMMITS}}` → PR metadata
     - `{{DIFF_FILE_PATH}}` → path to the tmp diff artifact (e.g. `tmp/claude-artifacts/change-request-replies/team-review-<REQUEST_NUMBER>-diff.txt`)
     - `{{OUTPUT_FILE}}` → `tmp/claude-artifacts/change-request-replies/team-review-<REQUEST_NUMBER>-<persona>-findings.json`

   Wait for all subagents to complete before proceeding.

9. **Collect and verify findings** — read each subagent's output file. Verify per `~/.claude/skill-references/subagent-patterns.md`: spot-check that findings reference real files from the diff. Parse the structured JSON.

    **Line-number verification (MANDATORY — DO NOT SKIP):** before posting any inline comment, apply `line-number-verification.md` in full — offset detection (`a-prime`), the working-tree mismatch trap, cross-file re-attribution (`e`), new-file placeholder recovery (`f`), and substance verification. Correct every finding's `line_start` (and `line_end`) before merging — merged findings inherit the corrected positions.

10. **Merge findings** — follow the **Merge Algorithm** in `persona-routing.md`:
    - Index findings by `(file, overlapping line range, category)`
    - **Agreement** (2+ personas, compatible): merge into one finding, tag `[persona-1, persona-2]`
    - **Unique** (1 persona): pass through with single-persona attribution `[persona-1]`
    - **Disagreement** (conflicting severity or contradictory recommendations): flag as `DISSENT_CANDIDATE`

    Not a disagreement: both agree on the problem but suggest different fixes — merge with complementary recommendations.

    **Drop self-resolving findings.** INFO-tier findings whose own `recommendation` is a verification step ("confirm X is in place", "check Y") or that the reviewer admits "doesn't apply" are the orchestrator's job to resolve at merge time — read the file, grep the anchor, and either drop the finding (verification passes) or upgrade it to a real finding (verification fails). Posting "confirming this check doesn't apply" is noise; posting "this check passes" is theater. Resolve, then drop or upgrade.

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

    N finding(s) — see inline comments.

    ### ⚖️ Dissent

    <Only if unresolved dissents exist. For each:>
    **<topic>** — <persona-A>: <position and reasoning>. <persona-B>: <position and reasoning>. Both held after deliberation.

    ### Positive Signals

    <Themes done well, with persona attribution where relevant>
    ```

    Append the **Footnote Format** from the base reference with `Role: Team-Reviewer`. For the `*Persona:*` field, list all reviewer personas used (e.g., `*Persona:* react-frontend, financial-reviewer`), not the orchestrator's persona. The base reference's persona detection precedence (formal → ad-hoc → none) applies to single-persona skills; team-review always has explicit reviewer personas from step 5.

    **Inline comments:** for each merged finding, compose one inline comment with combined attribution. Use the most detailed `inline_comment` from the contributing subagents, prefixed with the signal-strength tag. Never post duplicate comments on the same line range. **Each inline comment must also end with the Footnote Format block** (same `Role: Team-Reviewer` footer as the top-level review) — the base reference's footnote rule covers "every reply, review body, and inline comment," not just the body above. Easy to miss: this bullet sits right after the footnote instruction for the review body, and reads as if that instruction's scope stopped there.

    **Body discipline.** The body is a count + pointer, not a finding list. The `### Findings` section is exactly one line: `N finding(s) — see inline comments.` No bullets, no per-finding summaries, no file paths, no rationale. All specifics live in inline comments exclusively. Summary-only findings (no inline target) get appended as `N summary-only finding(s): <one-sentence theme>.` Allowed sections only: overview, reviewer roster, Findings, Dissent, Positive Signals.

13. **Post the review** — write the review payload to `tmp/claude-artifacts/change-request-replies/review-<REQUEST_NUMBER>-team-reviewer.json`. Event: `COMMENT`.

    **Inline target must be in the diff.** GitLab `createDiffNote` (and GitHub's equivalent) require `newLine` to be a line that appears in the MR/PR diff (added or context). Findings whose target file is unchanged in the diff — e.g., a pre-existing helper class called from new code — cannot post inline. Re-anchor on a related changed line (the call site in a changed file) and reference the unchanged file in the body, OR demote to summary-only. Don't try to post and discover the rejection at request time.

    **Context lines in modified files require more than `newLine` alone.** For context lines (unchanged lines visible in a hunk) in partially-modified files, `newLine` alone triggers "Line code can't be blank / Line code must be a valid line code". Only `+` (added) lines are safe to post on with `newLine` only. For any finding that targets a context line in a modified file, either: (a) re-anchor to the nearest `+` line in the same hunk, or (b) demote to summary-only. New files (fully `+`) are unaffected — every line is an added line.

    **Batch posts via a wrapper script when N > 5.** Each inline post is one `glab api graphql ...` Bash call. For more than ~5 inline comments, write a single wrapper script that loops a `post()` function over `(body_file, path, line)` triples, then invoke with one `bash` call. Saves N-1 Bash tool calls + permission prompts. The script body uses file-based GraphQL variables (`-F query=@...`, `-F body=@...`, `-f noteableId=...`) — no quoted strings, no shell escaping. Errors are visible in the `errors: []` field of each GraphQL response.

    **Use a per-cycle versioned wrapper name** — `tmp/claude-artifacts/change-request-replies/let-it-rip-<short-sha>.sh` (first 7 chars of `HEAD_SHA`), not the bare `let-it-rip.sh`. The artifact dir persists across cycles, so a fixed filename collides with the prior cycle's script — and a `bash` invocation chained after a blocked Write fires the *stale* script with old SHAs / old body paths / old comment IDs. GraphQL returns 200 with note IDs, but the posts target the wrong commit.

    ```
    !`cat ~/.claude/platform-commands/post-code-review.sh 2>/dev/null || echo "UNCONFIGURED: run setup-claude.sh to set up platform-commands"`
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
