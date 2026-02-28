# Curation Insights

Operational calibration and phase-specific patterns from prior consolidation runs.

## Operational

- Between-sweep reports work well for visibility during iterative consolidation runs
- When a sweep returns 0 HIGHs and 0 MEDIUMs, a single-line "Sweep N: clean" is sufficient — reserve the full table format for actionable sweeps
- **Cadence signal — check BEFORE reading any files.** Run `git log --oneline -10` and `git log --diff-filter=A --oneline -- .claude/learnings/` as the very first step. Decision tree: (1) last 3+ commits are curation-related AND no new learnings files → flag "Collection was curated N commits ago. Skip to skills?"; (2) new learnings files added since last curation → full sweep (new content needs cross-referencing against full corpus — personas, skills, guidelines, other learnings); (3) significant content diffs to existing files → full sweep. This is a 2-command check that can save 10+ minutes on a clean collection.
- **Run consolidation after bulk imports** (PR extraction, quantum-tunnel sync, manual additions) — bulk imports often introduce content overlapping with existing personas or skills
- **Load files incrementally:** Re-list the directory at each sweep start — files may be added mid-session by hooks or parallel processes
- **Pure-deletion re-sweeps: skip and state why.** After a sweep where all actions were deletions, skip the mechanical re-sweep — deletions can't create new overlaps. State explicitly: "Skipping re-sweep because deletions can't create new overlaps" rather than pretending to run one
- **Clean sweep summaries should lead with polish items — and polish items need a data source.** When the sweep returns 0 HIGHs and 0 MEDIUMs, the per-file quality scan (genericization + compression candidates) IS the value of the run. Lead with "Polish Opportunities" populated from the quality scan, each with a ready-to-run `/learnings:curate <file>` command. Without the quality scan, "Polish Opportunities" is an empty template that signals false completion
- **Concept-name collision detection is a separate, high-value pass.** Grepping for identical/near-identical H2/H3 headings across all files catches cross-file duplicates that cluster-level analysis misses. In a 25-file collection, this found 2 duplicates (worktree settings isolation, hooks/permissions) that cluster analysis didn't flag because the files were in different domain clusters. Run this as a distinct step after clustering, before classification

- **Cross-persona gotcha deduplication:** When personas share a domain boundary (e.g., java-backend and java-devops both cover Java/Spring), identical gotchas can drift into both files' "Known gotchas" sections. During the skills sweep, cross-check personas sharing a parent domain for duplicated content bullets. The more specialized persona owns the gotcha (e.g., metrics patterns → java-devops, not java-backend). Heading-level collision detection won't catch these — the same content appears under different subsection headings ("Spring Boot" vs "Metrics & Observability"), so you need content-level comparison.

- **Mature personas can obsolete entire learning files.** When a persona's "Known gotchas" comprehensively covers a domain's patterns (e.g., 15/15 match), the learning file is fully redundant. Check the corresponding persona early during per-file curation — complete coverage means "delete file" rather than pattern-by-pattern migration.
- **Inline short algorithms rather than cross-referencing.** When a persona's gotcha references a learning file for detail (e.g., "see X for full algorithm"), consider inlining if the detail is ~6 steps or fewer. Makes the persona self-contained and saves a runtime Read call. Reserve cross-references for genuinely long content (multi-page algorithms, large tables).
- **Check project learnings directories during genericization, not just CLAUDE.md.** Mature projects often have detailed learnings (e.g., `docs/claude-learnings/development-patterns.md`) that already capture project-specific content being removed from global files. The common outcome is "genericize in place, no migration needed" — saves the overhead of creating/updating project files that would be redundant.

## Classification Calibration

- **Rename actions should be HIGH confidence:** Removing provenance prefixes (e.g., `pr14-playwright-patterns` → `playwright-patterns`) has no ambiguity — classify as HIGH, not MEDIUM
- **Always read files directly, never via subagent.** Parallel Read tool calls (batches of 10-12) are strictly faster than routing through a subagent — subagents add process spawn overhead, system prompt loading, and their output can exceed retrieval limits (62KB+ persisted output that can't be read back). Subagents are only faster when each work unit requires multiple *sequential* tool calls (read → grep → cross-reference → classify) across many independent units. For bulk reads: direct. For multi-step parallel analysis across 30+ files or 5+ clusters: subagents.
- **Inline analysis beats subagents for small collections:** Under ~25 files, read and analyze directly inline — skip subagent fan-out entirely. Direct reads are faster and avoid wasted agent work when the corpus fits easily in context. Reserve per-cluster subagents for 30+ file collections or 5+ clusters.
- **Post-prune cross-reference cleanup is immediate, not deferred.** After deleting a skill, grep for the deleted skill's name across all remaining skill directories. Common stale references: "Related Skills" tables, naming examples in writing-best-practices, usage examples in curate/consolidate report templates. Fix in the same sweep — don't defer to a follow-up run.
- **"Why this matters" blocks in reference files are dead weight.** Skill reference files that explain principles (SRP, DRY, testability) before each pattern consume ~80 tokens per section without changing agent behavior — the agent already knows these principles. Remove during curation. The "Signs you need extraction" bullets DO change behavior (they're detection heuristics) and should be kept.
- **Self-referencing cross-reference headers are deletion markers.** When a file's own header says "See also: `X.md` for universal patterns (A, B, C)" — patterns A, B, and C in that file are high-confidence deletion candidates. The author already acknowledged the migration; the cross-reference IS the provenance trail. Stronger signal than normal corpus cross-referencing because it's explicit, not inferred.
- **Merge pattern pairs under shared headings.** When two patterns in the same file address the same root cause (one describes the problem, the other the fix) or the same goal (two techniques for the same purpose), merge under a single heading. Reduces pattern count without losing content.
- **Partial overlap → decompose, don't downgrade.** When a section has N concepts covered elsewhere and 1+ novel concepts, don't classify the whole thing as MEDIUM. Decompose into separate items: HIGH-delete for the covered concepts, HIGH-extract for the novel ones. Each is individually unambiguous. Coverage means *conceptual* coverage (same idea, not necessarily verbatim text)
- **MEMORY.md is not a curation safety net.** Don't classify a learning as "outdated because MEMORY.md covers it." MEMORY.md is always-on context cost; the learning file is conditional and authoritative. When both cover the same pattern, prune the MEMORY.md entry — it's the redundant copy, not the learning.
- **Persona coverage ≠ learning obsolescence.** When a persona one-liner covers a learning's conclusion, ask "what mistake could I still make with only the persona?" If the learning prevents a specific wrong approach (e.g., `suppressHydrationWarning` vs gating) or provides recipes the rule alone can't trigger (e.g., three distinct `setState` alternatives), keep it. Delete only when the rule is self-sufficient to execute correctly.
- **Internal catalog-to-section redundancy.** When a file has both a catalog (e.g., "Unused Features" listing 5 items) and dedicated sections expanding some of those items, compress the catalog entries to cross-references (e.g., "See section X below") instead of duplicating the summary. Prevents the same insight from consuming tokens twice in the same file.

## Context Window Optimization

- **`@` references are always-on context cost.** Content included via `@` in CLAUDE.md is injected into every conversation. During curation, flag domain-specific or task-specific content in `@`-referenced files as candidates for migration to conditional references (skill reference files, learnings, non-`@` guidelines)
- **Non-`@` path references enable selective loading.** The agent decides at runtime whether to read a file based on task relevance. This is strictly better than `@` for content that isn't universally needed. Prefer reorganizations that move content from always-on to conditional
- **Reorganization should also compress.** When moving or consolidating content, look for opportunities to say the same thing more concisely. Redundant phrasing, excessive examples, and verbose explanations waste context budget
- **Granular files > monolithic files for selective loading.** Smaller, focused files let the agent load only what's relevant. Split large files when distinct sections serve different tasks — the agent can then pay tokens only for the section it needs
- **Deduplication has compounding returns.** Content duplicated across N files costs N× tokens when multiple files are loaded in the same conversation. Consolidating to a single authoritative location saves tokens proportional to the overlap

## Compression Target Patterns

The conciseness check (curate step 4) should specifically flag these patterns as compression candidates:

- **Provenance notes** — "Discovered from: building the /api/amm/info route..." adds no teaching value; the pattern stands on its own
- **Compound-time self-assessments** — "Utility: High — novel pattern" was useful during triage but is noise once the learning is accepted
- **Debugging trails** — "What didn't work: tried X, then Y" belongs in commit history, not permanent reference docs
- **Verbose source code** — Multi-line code blocks when an English summary captures the same insight (e.g., a 15-line C++ snippet reducible to "Source: rippled `NetworkOPs.cpp` ~4177-4191")
- **Redundant structural dividers** — `---` between sections when `##` headings already provide visual separation

- **Stale snapshot numbers** — Specific counts or percentages tied to collection state (e.g., "22 skills, 31% utilization") go stale as files are added/removed. Replace with durable phrasing that captures the insight without brittle numbers (e.g., "well under 50% with ample headroom"). Keep formulas and structural capacity tables — those are state-independent.

**Calibration:** These patterns typically yield ~30% compression without losing teaching value. The goal is fewer tokens per insight, not fewer insights.

## Phase 2 Patterns

- **Deep dive for large-file MEDIUMs:** When a MEDIUM targets a file with 5+ sections, delegate per-section cross-reference analysis to a Task subagent rather than doing it inline. The subagent produces a per-section table (section title, related skill, coverage status, recommendation).

## Report Formatting

- **Keep full classification tables even when uniform.** When all patterns get the same classification (e.g., "standalone reference / keep"), still show the full table — the user reviews the reasoning per pattern, not just the action items. Don't collapse to "all 16: keep."
- **Front-load the recommendation.** When the report has a clear opinion (e.g., "only pattern 4 really needs genericizing, the rest are cosmetic"), lead with that instead of presenting equal-weight options and walking it back during discussion. The full table provides visibility; the recommendation provides direction.

## Execution Strategy

- **Single-file curation: targeted reads over bulk agents.** For content-mode curation of 1-2 files, read the most-likely-overlapping files directly (same-domain learnings, relevant personas) + grep for key terms. A bulk-read agent for the full corpus is slower and may not return usable content. Reserve corpus-wide agents for broad sweeps.
- **Clean sweep output should be terse.** One-line "Learnings: Clean (23 files, ~120 patterns)" when there are 0 findings. Don't produce multi-section reports with cluster tables, cross-reference validation, and persona coverage checks for sweeps that found nothing. Reserve detailed reports for sweeps with actionable findings.
- **New learnings require full corpus cross-referencing.** A new learning could duplicate a persona gotcha, overlap with a skill reference, be a guideline candidate, or overlap with another learning in a different domain cluster. Incremental analysis (only reading new files) doesn't work — the value is in cross-referencing against the full corpus. The optimization is faster acquisition (direct reads) not narrower scope.
