# Single Reviewer Mode (N=1)

When step 5 selects only one persona, the orchestrator reviews directly — no subagents, no merge layer, no deliberation.

## Flow

1. **Front-load persona content** — Read the selected persona file + `Extends` parents + `Proactive Cross-Refs`. Store as `PERSONA_CONTENT`.

2. **Load domain learnings** — Same as step 7 in the main flow. Glob learnings dirs, match against `CHANGED_FILES` domains.

3. **Analyze changes** — Review the diff through the loaded persona's lens. For each file, evaluate:
   - Does the change align with the persona's domain priorities?
   - Are there patterns from loaded learnings that apply?
   - Are there bugs, edge cases, or missing considerations?
   - Is there unnecessary complexity?

   **Separate identification from suggestion.** Finding an issue and proposing a fix require independent reasoning. When uncertain about the right fix, identify the issue without prescribing.

   Build output lists:
   - `INLINE_COMMENTS`: findings on changed code, with file + line references
   - `SUMMARY_POINTS`: high-level themes (no file-specific details)
   - `POSITIVE_SIGNALS`: what's done well

4. **Compose the review** — Use the same format as the merged review, minus signal-strength tags and dissent blocks:

   ```
   ## Team Review: <REQUEST_TITLE>

   <2-3 sentence overview>
   Reviewed by: <persona-name>

   ### Findings

   <Bulleted themes — group by concern, not by file>

   ### Positive Signals

   <What's done well>
   ```

   Append the footnote from `request-interaction-base.md` with `Role: Team-Reviewer`.

5. **Resume main flow** — Continue at step 13 (post review) with the composed review body and inline comments.

## Important Notes

- Use `Role: Team-Reviewer` (not `Role: Reviewer`) — same identity as multi-reviewer mode for consistent detection
- No duplication between summary and inline comments — summary names themes, inline carries specifics
- Don't post empty reviews — if no findings, skip posting entirely. **Exception**: when triggered by new commits, post a brief confirmation (e.g., "Reviewed `<sha>` — no new findings")
