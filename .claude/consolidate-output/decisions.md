# Decision Log

All consolidation actions and judgments, logged for auditability and rollback.

**Format**: Every action (HIGH auto-applied, MEDIUM judged, persona enrichment) gets a row. The Decision column shows `applied`, `blocked`, or `skipped`. The Rationale column explains why — especially important for MEDIUM judgments where the agent exercised autonomous discretion.

| Iter | Content Type | Action | Source | Target | Confidence | Decision | Rationale |
|------|-------------|--------|--------|--------|------------|----------|-----------|
| 1 | LEARNINGS | Deduplicate cross-file sections | skill-design.md | skill-platform-portability.md | HIGH | applied | 19 sections (~200 lines) were exact duplicates across both files. Removed from skill-design.md, kept in skill-platform-portability.md (canonical home for platform content). Added cross-reference header. |
| 1 | LEARNINGS | Remove internal duplicate block | skill-design.md | skill-design.md | HIGH | applied | 5 sections (Track Assumptions → "Validate" Means Run It) appeared twice within the file (lines 198-221 and 382-404). Kept first occurrence, removed second. |
| 1 | LEARNINGS | Merge duplicate sections | nextjs.md | nextjs.md | HIGH | applied | "Dynamic Route Params Are Async" (page example) and "Next.js 16: Dynamic Route Params are Promises" (route handler example) were the same concept. Merged into one section with both examples. |
| 1 | LEARNINGS | Wire missing persona reference | xrpl-permissioned-domains.md | xrpl-typescript-fullstack.md | MEDIUM | applied | New learnings file covering XLS-70/80/81 permissioned domains not linked in the XRPL persona's Detailed references. Clearly within the persona's domain scope (XRPL integration). Low risk, high discoverability gain. |
| 1 | LEARNINGS | Compound insight — persona wiring | skill-design.md | skill-design.md | — | applied | Extended "Compound Skill: Grep Before Creating New Files" section with guidance to check persona Detailed references when creating new learnings files. Pattern discovered from M1 finding. |
