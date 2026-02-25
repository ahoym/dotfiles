# Curation Insights

Operational calibration and phase-specific patterns from prior consolidation runs.

## Operational

- Between-sweep reports work well for visibility during iterative consolidation runs
- When a sweep returns 0 HIGHs and 0 MEDIUMs, a single-line "Sweep N: clean" is sufficient — reserve the full table format for actionable sweeps
- **Cadence signal:** Consolidation has diminishing returns when run shortly after a clean first run — use `/learnings:curate <file>` for targeted cleanup between full consolidation sweeps. When invoked on a recently-curated collection, proactively flag: "Last curation was N commits/hours ago — learnings sweep will likely be clean. Skip to skills/guidelines?" Challenge the premise before running a predictably empty sweep.
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
- **Inline analysis beats subagents for small collections:** Under ~25 files, read and analyze directly inline — skip subagent fan-out entirely. Direct reads are faster and avoid wasted agent work when the corpus fits easily in context. Reserve per-cluster subagents for 30+ file collections or 5+ clusters
- **Partial overlap → decompose, don't downgrade.** When a section has N concepts covered elsewhere and 1+ novel concepts, don't classify the whole thing as MEDIUM. Decompose into separate items: HIGH-delete for the covered concepts, HIGH-extract for the novel ones. Each is individually unambiguous. Coverage means *conceptual* coverage (same idea, not necessarily verbatim text)
- **MEMORY.md is not a curation safety net.** Don't classify a learning as "outdated because MEMORY.md covers it." MEMORY.md is always-on context cost; the learning file is conditional and authoritative. When both cover the same pattern, prune the MEMORY.md entry — it's the redundant copy, not the learning.
- **Persona coverage ≠ learning obsolescence.** When a persona one-liner covers a learning's conclusion, ask "what mistake could I still make with only the persona?" If the learning prevents a specific wrong approach (e.g., `suppressHydrationWarning` vs gating) or provides recipes the rule alone can't trigger (e.g., three distinct `setState` alternatives), keep it. Delete only when the rule is self-sufficient to execute correctly.

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

**Calibration:** These patterns typically yield ~30% compression without losing teaching value. The goal is fewer tokens per insight, not fewer insights.

## Phase 2 Patterns

- **Deep dive for large-file MEDIUMs:** When a MEDIUM targets a file with 5+ sections, delegate per-section cross-reference analysis to a Task subagent rather than doing it inline. The subagent produces a per-section table (section title, related skill, coverage status, recommendation).

## Report Formatting

- **Keep full classification tables even when uniform.** When all patterns get the same classification (e.g., "standalone reference / keep"), still show the full table — the user reviews the reasoning per pattern, not just the action items. Don't collapse to "all 16: keep."
- **Front-load the recommendation.** When the report has a clear opinion (e.g., "only pattern 4 really needs genericizing, the rest are cosmetic"), lead with that instead of presenting equal-weight options and walking it back during discussion. The full table provides visibility; the recommendation provides direction.

## Execution Strategy

- **Single-file curation: targeted reads over bulk agents.** For content-mode curation of 1-2 files, read the most-likely-overlapping files directly (same-domain learnings, relevant personas) + grep for key terms. A bulk-read agent for the full corpus is slower and may not return usable content. Reserve corpus-wide agents for broad sweeps.
