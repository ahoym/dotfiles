---
name: code-review-request
description: "Code review a pull request or merge request. Fetches diff, analyzes through active persona lens, posts review with inline comments. Use when the user asks to review a PR, do a code review, review a request, or review changes."
argument-hint: "[request-number-or-url]"
---

## Context
- Current branch: !`git branch --show-current 2>/dev/null`

# Code Review Request

Fetch a PR/MR diff, analyze it through the active persona's lens, and post a review with inline comments — all footnoted with model and persona attribution.

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

## Instructions

1. **Verify active persona** — confirm a persona was activated this session. If not, glob `.claude/personas/` and `.claude/commands/set-persona/` for available personas, recommend the best match for the PR's domain, and wait for the user to activate one before proceeding. The persona shapes every aspect of the review — proceeding without one produces generic feedback.

2. **Detect platform** — follow `@~/.claude/skill-references/platform-detection.md` to determine GitHub vs GitLab. Set `CLI`, `REVIEW_UNIT`, and API command patterns. Then read the matching platform commands file (`~/.claude/skill-references/github-commands.md` or `gitlab-commands.md`).

3. **Resolve the request** — determine which PR/MR to review:
   - If `$ARGUMENTS` contains a URL, extract the number from it
   - If `$ARGUMENTS` contains a number, use it directly
   - Otherwise, detect from current branch:

   **GitHub:**
   ```bash
   gh pr view --json number,title,headRefName,baseRefName,url
   ```

   **GitLab:**
   ```bash
   glab mr view --output json
   ```

   Store as `REQUEST_NUMBER`, `REQUEST_TITLE`, `REQUEST_URL`, `HEAD_BRANCH`, `BASE_BRANCH`.

4. **Fetch PR metadata and diff** — run these in parallel:

   **Fetch the full diff:**
   ```bash
   gh pr diff <REQUEST_NUMBER>
   ```

   **Fetch the file list:**
   ```bash
   gh pr view <REQUEST_NUMBER> --json files --jq '.files[].path'
   ```

   **Fetch the PR body:**
   ```bash
   gh pr view <REQUEST_NUMBER> --json body --jq '.body'
   ```

   **Fetch commit history:**
   ```bash
   gh pr view <REQUEST_NUMBER> --json commits --jq '.commits[] | {sha: .oid[0:7], message: .messageHeadline}'
   ```

   Store the diff as `FULL_DIFF`, file list as `CHANGED_FILES`, body as `REQUEST_BODY`, commits as `COMMITS`.

   For large diffs, read the full diff — thorough review requires seeing all changes.

5. **Load domain-relevant learnings** — match `CHANGED_FILES` paths and domains against learnings filenames:
   - Glob `~/.claude/learnings/*.md` to get the full inventory
   - For each changed file, derive domain terms from the path and content (e.g., `src/api/` -> "api", `.github/workflows/` -> "ci-cd", `tests/` -> "testing")
   - Match domain terms against learnings filenames (e.g., "ci" matches `ci-cd.md`, "test" matches `testing-patterns.md`)
   - Read matched files to ground the review in established knowledge
   - Announce: `📚 Loaded domain learnings: <list>`
   - This supplements the persona's proactive loads with PR-specific knowledge

6. **Analyze changes** — review the full diff through the active persona's lens. For each file, evaluate:
   - Does the change align with the persona's domain priorities?
   - Are there taxonomy, placement, or architectural concerns?
   - Are there patterns from loaded learnings that apply?
   - Are there bugs, edge cases, or missing considerations?
   - Is there unnecessary complexity or missing simplification?

   Build two lists:
   - `INLINE_COMMENTS`: list of `{path, line, body}` — specific findings anchored to file lines. Use the line number as it appears in the final version of the file (RIGHT side of diff). Every comment should be actionable or ask a clarifying question. All specifics (file names, line numbers, code snippets) belong here — not in the summary.
   - `SUMMARY_POINTS`: high-level themes and patterns across the PR. No file-specific details — those belong in inline comments. The summary should be readable without clicking into any file.

   **No duplication between summary and inline comments.** The summary names themes ("some learnings may not earn their context cost"); inline comments carry the specifics ("this pattern on line 103 is basic OOP"). A reader skimming the summary gets the full picture; a reader reviewing the diff gets the details in context.

7. **Compose the review** — build the review payload:

   **Review body** (summary — themes only, no file-specific details):
   ```
   ## <Persona Name> Review: <REQUEST_TITLE>

   <2-3 sentence overview of the change and overall assessment>

   ### Findings

   <Bulleted themes — group by concern, not by file. No filenames or line numbers here.>

   ### Positive Signals

   <What's done well — themes and patterns, not file-by-file inventory>

   ---
   *Generated with [Claude Code](https://claude.ai/code) (<model name>) using the `<persona-name>` persona.*
   ```

   **Each inline comment** must end with:
   ```

   ---
   *Generated with [Claude Code](https://claude.ai/code) (<model name>) using the `<persona-name>` persona.*
   ```

   For `<model name>`, use the model you're currently running (e.g., "Claude Opus 4.6").

8. **Post the review** — use the **"Post Review with Inline Comments"** section from the platform commands file. Write the review payload to `change-request-replies/review-<REQUEST_NUMBER>.json` and post via the API.

9. **Clean up and report** — remove temp files, then confirm:
   ```
   ✅ Review posted on <REVIEW_UNIT> #<REQUEST_NUMBER> (<N> inline comments)
   <REQUEST_URL>
   ```

## Important Notes

- Review is always thorough regardless of PR size — don't skip files or skim changes
- The persona's judgment lens shapes what you look for and how you weigh findings
- Domain learnings ground the review in established patterns — cite them when relevant (e.g., "per `ci-cd.md`, lint should run first as a fast gate")
- Every piece of externally-posted content gets the footnote — no exceptions
- Post the review as a `COMMENT` event (not `APPROVE` or `REQUEST_CHANGES`) — the user decides the verdict
- If the diff is too large to fit in context, tell the user rather than silently truncating
