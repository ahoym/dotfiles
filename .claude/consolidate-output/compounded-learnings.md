# Compounded Learnings

Meta-insights about the corpus discovered during consolidation sweeps. These are NOT action logs (see `decisions.md`) — they are patterns about the collection itself that improve future curation and knowledge management.

**Post-loop**: Use as source material for `/learnings:compound` to persist valuable insights into the learnings system.

<!-- Each sweep with findings appends:

### Iter N — CONTENT_TYPE

- Insight bullet points about corpus patterns, not individual actions

-->

### Iter 1 — LEARNINGS

- **Parallel-plan knowledge is split across two files** (`parallel-planning.md` and `parallel-plans.md`). When content is compounded across sessions, the filename index can create near-duplicates if the compounder doesn't search for existing files first. The compound skill should grep for existing files matching the domain before creating new ones.
- **Research methodology patterns gravitate toward the largest domain file** — all 3 patterns from `research-methodology.md` were independently re-discovered and expanded in `skill-design.md`. Small standalone reference files risk becoming orphaned when a larger file in the same domain accumulates the same patterns with more context.
- **Claude Code platform behavior patterns ("Permissions Are Cached", "Worktree Isolation") were duplicated into `parallel-plans.md`** — likely compounded from the same session where they were discovered in a parallel-plan context. The compound skill should check if the insight already exists in a more authoritative location before creating a domain-specific copy.
- **XRPL personas have rich inline gotchas but no Detailed references section** — the `react-frontend` persona demonstrates the correct pattern (lean inline + Detailed references pointing to learnings). Other domain personas should follow this pattern for discoverability.
- **Thin files (< 20 lines) with a single pattern are merge candidates** — `xrpl-testing-patterns.md` (16 lines, 1 pattern) was more discoverable folded into the main `xrpl-patterns.md`. The filename keyword benefit doesn't outweigh the fragmentation cost for single-pattern files.

### Iter 2 — SKILLS

- **Bare filename references in skills are a maintenance hazard** — `do-refactor-code/SKILL.md` referenced `refactoring-patterns.md` without a path prefix. No local file existed; the intended target was `~/.claude/learnings/refactoring-patterns.md`. Skills should always use full `~/.claude/...` paths for cross-directory references. This is the same class of issue that `curation-insights.md` flags as "stale paths are the primary maintenance issue."
- **Skill-reference files can become orphaned silently** — `subagent-patterns.md` exists in `skill-references/` but no SKILL.md references it. Its content is already implemented inline in relevant skills. Orphaned reference files add maintenance surface without providing discoverability benefit. The consolidation loop catches these but a pre-commit check would be more efficient.
