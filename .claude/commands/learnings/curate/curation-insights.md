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

## Phase 2 Patterns

- **Deep dive for large-file MEDIUMs:** When a MEDIUM targets a file with 5+ sections, delegate per-section cross-reference analysis to a Task subagent rather than doing it inline. The subagent produces a per-section table (section title, related skill, coverage status, recommendation).
