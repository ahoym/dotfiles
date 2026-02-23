# Curation Insights

Operational calibration and phase-specific patterns from prior consolidation runs.

## Operational

- Between-sweep reports work well for visibility during iterative consolidation runs
- When a sweep returns 0 HIGHs and 0 MEDIUMs, a single-line "Sweep N: clean" is sufficient — reserve the full table format for actionable sweeps
- **Cadence signal:** Consolidation has diminishing returns when run shortly after a clean first run — use `/learnings:curate <file>` for targeted cleanup between full consolidation sweeps
- **Run consolidation after bulk imports** (PR extraction, quantum-tunnel sync, manual additions) — bulk imports often introduce content overlapping with existing personas or skills
- **Load files incrementally:** Re-list the directory at each sweep start — files may be added mid-session by hooks or parallel processes
- **Pure-deletion re-sweeps: skip and state why.** After a sweep where all actions were deletions, skip the mechanical re-sweep — deletions can't create new overlaps. State explicitly: "Skipping re-sweep because deletions can't create new overlaps" rather than pretending to run one
- **Clean sweep summaries should lead with polish items:** When the sweep returns 0 HIGHs and 0 MEDIUMs, LOW items *are* the value of the run. Lead with "Polish Opportunities" rather than "no action needed" — the latter signals false completion and buries the useful output

## Classification Calibration

- **Rename actions should be HIGH confidence:** Removing provenance prefixes (e.g., `pr14-playwright-patterns` → `playwright-patterns`) has no ambiguity — classify as HIGH, not MEDIUM
- **Inline analysis beats subagents for small collections:** Under ~25 files, read and analyze directly inline — skip subagent fan-out entirely. Direct reads are faster and avoid wasted agent work when the corpus fits easily in context. Reserve per-cluster subagents for 30+ file collections or 5+ clusters
- **Partial overlap → decompose, don't downgrade.** When a section has N concepts covered elsewhere and 1+ novel concepts, don't classify the whole thing as MEDIUM. Decompose into separate items: HIGH-delete for the covered concepts, HIGH-extract for the novel ones. Each is individually unambiguous. Coverage means *conceptual* coverage (same idea, not necessarily verbatim text)

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
